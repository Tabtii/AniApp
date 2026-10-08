import 'package:flutter/material.dart';

import '../data/app_store.dart';
import '../models/anime.dart';
import 'common.dart';
import 'detail_screen.dart';
import 'visuals.dart';

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

  void open(Anime anime) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => DetailScreen(anime: anime, store: widget.store),
    ),
  );
  String get seasonName => const {
    'winter': 'Winter',
    'spring': 'Frühling',
    'summer': 'Sommer',
    'fall': 'Herbst',
  }[season]!;
  Widget controls() => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Row(
      children: [
        ChoiceChip(
          label: const Text('Saison'),
          selected: !searching,
          onSelected: loading
              ? null
              : (_) {
                  searching = false;
                  page = 1;
                  _load();
                },
        ),
        const SizedBox(width: 12),
        if (!searching) ...[
          DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: year,
              style: Theme.of(context).textTheme.labelLarge,
              borderRadius: BorderRadius.circular(18),
              items:
                  List.generate(
                        DateTime.now().year - 1980 + 2,
                        (i) => DateTime.now().year + 1 - i,
                      )
                      .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
                      .toList(),
              onChanged: loading
                  ? null
                  : (y) {
                      year = y!;
                      page = 1;
                      _load();
                    },
            ),
          ),
          const SizedBox(width: 14),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: season,
              style: Theme.of(context).textTheme.labelLarge,
              borderRadius: BorderRadius.circular(18),
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
          ),
        ] else
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
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
                  : (g) {
                      genre = g == '' ? null : g;
                      page = 1;
                      _load();
                    },
            ),
          ),
      ],
    ),
  );
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final featured = !searching && items.length > 1;
      final gridItems = featured ? items.skip(1).toList() : items;
      final columns = (constraints.maxWidth / 180).floor().clamp(2, 6);
      final width = (constraints.maxWidth - 40 - (columns - 1) * 14) / columns;
      return RefreshIndicator(
        onRefresh: () async {
          page = 1;
          await _load();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            const SliverToBoxAdapter(
              child: SectionHeading(
                'Dein nächster Lieblingsanime.',
                eyebrow: 'Entdecken',
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: TextField(
                  controller: search,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Titel, Welten, neue Geschichten …',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: IconButton(
                      tooltip: 'Suchen',
                      icon: const Icon(Icons.arrow_forward_rounded),
                      onPressed: loading
                          ? null
                          : () {
                              searching = true;
                              page = 1;
                              _load();
                            },
                    ),
                  ),
                  onSubmitted: (_) {
                    if (!loading) {
                      searching = true;
                      page = 1;
                      _load();
                    }
                  },
                ),
              ),
            ),
            SliverToBoxAdapter(child: controls()),
            if (loading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: LinearProgressIndicator(minHeight: 2),
                ),
              ),
            if (error != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(error!),
                      TextButton(
                        onPressed: () => _load(),
                        child: const Text('Erneut versuchen'),
                      ),
                    ],
                  ),
                ),
              ),
            if (items.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyPanel(
                  loading
                      ? 'Anime werden geladen …'
                      : 'Keine Anime gefunden. Versuche andere Suchbegriffe oder Filter.',
                  icon: loading
                      ? Icons.hourglass_top
                      : Icons.search_off_rounded,
                ),
              ),
            if (featured)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: FeatureAnime(
                    anime: items.first,
                    store: widget.store,
                    label: '$seasonName $year',
                    onTap: () => open(items.first),
                  ),
                ),
              ),
            if (items.isNotEmpty)
              SliverToBoxAdapter(
                child: SectionHeading(
                  searching ? 'Deine Suchergebnisse' : 'Mehr aus dieser Season',
                  eyebrow: searching ? 'Treffer' : 'Neue Welten entdecken',
                  trailing: Text(
                    '${items.length} Titel',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => PosterCard(
                    anime: gridItems[i],
                    store: widget.store,
                    onTap: () => open(gridItems[i]),
                  ),
                  childCount: gridItems.length,
                ),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 20,
                  mainAxisExtent: width * 1.38 + 88,
                ),
              ),
            ),
            if (hasNext)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: OutlinedButton(
                    onPressed: loading
                        ? null
                        : () {
                            page++;
                            _load(append: true);
                          },
                    child: const Text('Weitere Anime laden'),
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      );
    },
  );
}

class SaveAnimeButton extends StatelessWidget {
  const SaveAnimeButton({super.key, required this.anime, required this.store});
  final Anime anime;
  final AppStore store;
  @override
  Widget build(BuildContext context) => IconButton.filled(
    tooltip: store.isSaved(anime.id)
        ? 'In deiner Watchlist'
        : 'Zur Watchlist hinzufügen',
    style: IconButton.styleFrom(
      backgroundColor: const Color(0xCF111520),
      foregroundColor: Colors.white,
    ),
    icon: Icon(
      store.isSaved(anime.id)
          ? Icons.bookmark_rounded
          : Icons.bookmark_add_outlined,
    ),
    onPressed: store.busy || store.isSaved(anime.id)
        ? null
        : () => perform(context, () => store.save(WatchEntry(anime: anime))),
  );
}

class FeatureAnime extends StatelessWidget {
  const FeatureAnime({
    super.key,
    required this.anime,
    required this.store,
    required this.label,
    required this.onTap,
  });
  final Anime anime;
  final AppStore store;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    label: '$label: ${anime.title}',
    button: true,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: SizedBox(
        height: 370,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Artwork(anime.image, alignment: Alignment.topCenter),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0, .4, .75, 1],
                  colors: [
                    Color(0x22070C15),
                    Colors.transparent,
                    Color(0xC0070C15),
                    Color(0xFF070C15),
                  ],
                ),
              ),
            ),
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(onTap: onTap),
              ),
            ),
            Positioned(
              left: 18,
              top: 18,
              child: Tag(label.toUpperCase(), color: lime, solid: true),
            ),
            Positioned(
              right: 10,
              top: 10,
              child: SaveAnimeButton(anime: anime, store: store),
            ),
            Positioned(
              left: 22,
              right: 22,
              bottom: 22,
              child: IgnorePointer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (anime.score != null) ...[
                          const Icon(Icons.star_rounded, color: lime, size: 17),
                          const SizedBox(width: 4),
                          Text(
                            anime.score!.toStringAsFixed(1),
                            style: const TextStyle(
                              color: lime,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: Text(
                            anime.genres.take(2).join(' / '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      anime.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 27,
                        height: 1.08,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.7,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Row(
                      children: [
                        Text(
                          'Anime entdecken',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: coral,
                          size: 19,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class PosterCard extends StatelessWidget {
  const PosterCard({
    super.key,
    required this.anime,
    required this.store,
    required this.onTap,
  });
  final Anime anime;
  final AppStore store;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Artwork(anime.image, alignment: Alignment.topCenter),
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(onTap: onTap),
                ),
              ),
              if (anime.score != null)
                Positioned(
                  left: 8,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xDE111520),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, color: lime, size: 13),
                        const SizedBox(width: 3),
                        Text(
                          anime.score!.toStringAsFixed(1),
                          style: const TextStyle(
                            color: lime,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Positioned(
                right: 0,
                top: 0,
                child: SaveAnimeButton(anime: anime, store: store),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 10),
      GestureDetector(
        onTap: onTap,
        child: Text(
          anime.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
        ),
      ),
      const SizedBox(height: 5),
      Text(
        '${anime.episodes ?? '?'} Folgen${anime.genres.isEmpty ? '' : ' · ${anime.genres.first}'}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontSize: 11,
        ),
      ),
    ],
  );
}

class Cover extends StatelessWidget {
  const Cover(this.url, {super.key, this.width = 80, this.height = 120});
  final String? url;
  final double width, height;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    height: height,
    child: Artwork(url, alignment: Alignment.topCenter),
  );
}
