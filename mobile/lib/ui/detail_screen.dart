import 'package:flutter/material.dart';

import '../data/app_store.dart';
import '../models/anime.dart';
import '../models/content.dart';
import 'catalog_screen.dart';
import 'common.dart';

class DetailScreen extends StatefulWidget {
  const DetailScreen({super.key, required this.anime, required this.store});
  final Anime anime;
  final AppStore store;
  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late Anime anime;
  List<Availability> availability = [];
  bool loading = true;
  String? error, availabilityError;
  @override
  void initState() {
    super.initState();
    anime = widget.anime;
    widget.store.addListener(_changed);
    _load();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
      availabilityError = null;
    });
    try {
      final value = await widget.store.catalog.detail(anime.id);
      if (mounted) setState(() => anime = value);
    } catch (_) {
      if (mounted) {
        setState(() => error = 'Details konnten nicht geladen werden.');
      }
    }
    try {
      final value = await widget.store.availability(anime.id);
      if (mounted) setState(() => availability = value);
    } catch (_) {
      if (mounted) {
        setState(
          () => availabilityError =
              'Streaming-Daten sind gerade nicht erreichbar.',
        );
      }
    }
    if (mounted) setState(() => loading = false);
  }

  @override
  void dispose() {
    widget.store.removeListener(_changed);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Anime-Details')),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Cover(anime.image, width: 110, height: 160),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      anime.title,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '★ ${anime.score?.toStringAsFixed(1) ?? '—'}  ·  ${anime.episodes ?? '?'} Folgen',
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed:
                          widget.store.busy || widget.store.isSaved(anime.id)
                          ? null
                          : () => perform(
                              context,
                              () => widget.store.save(WatchEntry(anime: anime)),
                            ),
                      icon: Icon(
                        widget.store.isSaved(anime.id)
                            ? Icons.check
                            : Icons.bookmark_add,
                      ),
                      label: Text(
                        widget.store.isSaved(anime.id)
                            ? 'In deiner Liste'
                            : 'Merken',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            children: anime.genres.map((g) => Chip(label: Text(g))).toList(),
          ),
          if (loading) const LinearProgressIndicator(),
          if (error != null || availabilityError != null) ...[
            Text(error ?? availabilityError!),
            TextButton(onPressed: _load, child: const Text('Erneut versuchen')),
          ],
          const SizedBox(height: 16),
          Text(anime.synopsis ?? 'Noch keine Beschreibung verfügbar.'),
          if (anime.broadcast != null) ...[
            const SizedBox(height: 20),
            Text(
              'Reguläre Ausstrahlung in Japan',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(anime.broadcast!),
            const Text(
              'Dies ist kein bestätigter Streaming- oder Synchronisationstermin in Deutschland.',
            ),
          ],
          const SizedBox(height: 24),
          Text(
            'Wo schauen? · ${widget.store.region}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          if (availability.isEmpty && !loading)
            Text(
              availabilityError ??
                  'Für diese Region sind noch keine geprüften Anbieter- und Sprachdaten hinterlegt.',
            ),
          ...availability.map(
            (a) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a.provider,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      a.status == 'available'
                          ? 'Als verfügbar gemeldet'
                          : 'Angekündigt',
                    ),
                    Text(
                      a.scope == 'episode'
                          ? 'Folge ${a.episode ?? '?'}'
                          : 'Angabe für ${a.scope == 'season' ? 'die Staffel' : 'die Serie'}; kann je Folge abweichen.',
                    ),
                    Text(
                      'Audio: ${a.audio == null
                          ? 'Unbekannt'
                          : a.audio!.isEmpty
                          ? 'Keine Angabe'
                          : a.audio!.map(languageLabel).join(', ')}',
                    ),
                    Text(
                      'Untertitel: ${a.subtitles == null
                          ? 'Unbekannt'
                          : a.subtitles!.isEmpty
                          ? 'Keine Angabe'
                          : a.subtitles!.map(languageLabel).join(', ')}',
                    ),
                    Text(
                      'Zuletzt geprüft: ${dateLabel(DateTime.tryParse(a.checkedAt)?.toLocal())}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    TextButton.icon(
                      onPressed: () => openSource(context, a.url),
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Beim Anbieter prüfen'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
