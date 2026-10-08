import 'package:flutter/material.dart';

import '../data/app_store.dart';
import '../models/anime.dart';
import 'common.dart';
import 'detail_screen.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key, required this.store});
  final AppStore store;
  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final search = TextEditingController();
  late int year;
  late String season;
  int page = 1;
  int _request = 0;
  bool loading = true, hasNext = false, searching = false;
  String? error;
  String? genre;
  List<Anime> items = [];
  @override
  void initState() {
    super.initState();
    year = DateTime.now().year;
    season = currentSeason(DateTime.now());
    widget.store.addListener(_changed);
    _load();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  Future<void> _load({bool append = false}) async {
    final request = ++_request;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final result = searching
          ? await widget.store.catalog.search(search.text, page, genre: genre)
          : await widget.store.catalog.season(year, season, page);
      if (!mounted || request != _request) return;
      setState(() {
        items = append
            ? [
                ...items,
                ...result.items.where(
                  (a) => !items.any((old) => old.id == a.id),
                ),
              ]
            : result.items;
        hasNext = result.hasNext;
      });
    } catch (e) {
      if (mounted && request == _request) {
        setState(() {
          error = e.toString();
          if (append) page--;
        });
      }
    } finally {
      if (mounted && request == _request) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    widget.store.removeListener(_changed);
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: TextField(
          controller: search,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Deine nächste Lieblingsserie …',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: IconButton(
              tooltip: 'Suchen',
              icon: const Icon(Icons.arrow_forward),
              onPressed: () {
                searching = true;
                page = 1;
                _load();
              },
            ),
          ),
          onSubmitted: (_) {
            searching = true;
            page = 1;
            _load();
          },
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ChoiceChip(
              label: const Text('Saison'),
              selected: !searching,
              onSelected: (_) {
                searching = false;
                page = 1;
                _load();
              },
            ),
            if (!searching) ...[
              DropdownButton<int>(
                value: year,
                items:
                    List.generate(
                          DateTime.now().year - 1980 + 2,
                          (i) => DateTime.now().year + 1 - i,
                        )
                        .map(
                          (y) => DropdownMenuItem(value: y, child: Text('$y')),
                        )
                        .toList(),
                onChanged: loading
                    ? null
                    : (y) {
                        year = y!;
                        page = 1;
                        _load();
                      },
              ),
              DropdownButton<String>(
                value: season,
                items: const [
                  DropdownMenuItem(value: 'winter', child: Text('Winter')),
                  DropdownMenuItem(value: 'spring', child: Text('Frühling')),
                  DropdownMenuItem(value: 'summer', child: Text('Sommer')),
                  DropdownMenuItem(value: 'fall', child: Text('Herbst')),
                ],
                onChanged: loading
                    ? null
                    : (s) {
                        season = s!;
                        page = 1;
                        _load();
                      },
              ),
            ] else
              DropdownButton<String>(
                value: genre ?? '',
                items: const [
                  DropdownMenuItem(value: '', child: Text('Alle Genres')),
                  DropdownMenuItem(value: '1', child: Text('Action')),
                  DropdownMenuItem(value: '4', child: Text('Comedy')),
                  DropdownMenuItem(value: '10', child: Text('Fantasy')),
                  DropdownMenuItem(value: '7', child: Text('Mystery')),
                  DropdownMenuItem(value: '22', child: Text('Romance')),
                  DropdownMenuItem(value: '24', child: Text('Sci-Fi')),
                ],
                onChanged: loading
                    ? null
                    : (value) {
                        genre = value == '' ? null : value;
                        page = 1;
                        _load();
                      },
              ),
          ],
        ),
      ),
      if (loading) const LinearProgressIndicator(),
      if (error != null)
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(child: Text(error!)),
              TextButton(
                onPressed: () => _load(),
                child: const Text('Erneut versuchen'),
              ),
            ],
          ),
        ),
      Expanded(
        child: items.isEmpty && !loading
            ? EmptyPanel(
                error == null
                    ? 'Keine Anime gefunden. Versuche andere Suchbegriffe oder Filter.'
                    : 'Anime-Daten konnten nicht geladen werden.',
              )
            : RefreshIndicator(
                onRefresh: () async {
                  page = 1;
                  await _load();
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length + (hasNext ? 1 : 0),
                  itemBuilder: (context, i) {
                    if (i == items.length) {
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: OutlinedButton(
                          onPressed: loading
                              ? null
                              : () {
                                  page++;
                                  _load(append: true);
                                },
                          child: const Text('Weitere Anime laden'),
                        ),
                      );
                    }
                    return AnimeTile(anime: items[i], store: widget.store);
                  },
                ),
              ),
      ),
    ],
  );
}

class AnimeTile extends StatelessWidget {
  const AnimeTile({super.key, required this.anime, required this.store});
  final Anime anime;
  final AppStore store;
  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => DetailScreen(anime: anime, store: store),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Cover(anime.image, width: 78, height: 112),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    anime.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '★ ${anime.score?.toStringAsFixed(1) ?? '—'}  ·  ${anime.episodes ?? '?'} Folgen',
                  ),
                  const SizedBox(height: 6),
                  Text(
                    anime.genres.take(3).join(' · '),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: store.isSaved(anime.id)
                  ? 'In deiner Watchlist'
                  : 'Zur Watchlist hinzufügen',
              icon: Icon(
                store.isSaved(anime.id)
                    ? Icons.bookmark
                    : Icons.bookmark_add_outlined,
              ),
              onPressed: store.busy || store.isSaved(anime.id)
                  ? null
                  : () => perform(
                      context,
                      () => store.save(WatchEntry(anime: anime)),
                    ),
            ),
          ],
        ),
      ),
    ),
  );
}

class Cover extends StatelessWidget {
  const Cover(this.url, {super.key, this.width = 80, this.height = 120});
  final String? url;
  final double width, height;
  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: width,
      height: height,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Icon(Icons.movie_outlined),
    );
    return url == null
        ? placeholder
        : Image.network(
            url!,
            width: width,
            height: height,
            fit: BoxFit.cover,
            errorBuilder: (_, error, stack) => placeholder,
          );
  }
}
