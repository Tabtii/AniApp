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
  List<ReleaseEvent> releases = [];
  bool loading = true;
  String? error, availabilityError, releaseError;
  String get _settings =>
      '${widget.store.region}|${widget.store.language}|${widget.store.languageMode}';
  late String _loadedSettings;
  int _loadVersion = 0;
  @override
  void initState() {
    super.initState();
    anime = widget.anime;
    _loadedSettings = _settings;
    widget.store.addListener(_changed);
    _load();
  }

  void _changed() {
    if (!mounted) return;
    if (_loadedSettings != _settings) {
      _loadedSettings = _settings;
      _load();
    } else {
      setState(() {});
    }
  }

  Future<void> _load() async {
    final version = ++_loadVersion;
    bool current() => mounted && version == _loadVersion;
    setState(() {
      loading = true;
      error = null;
      availabilityError = null;
      availability = [];
      releases = [];
    });
    releaseError = null;
    await Future.wait([
      (() async {
        try {
          final value = await widget.store.catalog.detail(anime.id);
          if (current()) setState(() => anime = value);
        } catch (_) {
          if (current()) {
            setState(() => error = 'Details konnten nicht geladen werden.');
          }
        }
      })(),
      (() async {
        try {
          final value = await widget.store.availability(anime.id);
          if (current()) setState(() => availability = value);
        } catch (_) {
          if (current()) {
            setState(
              () => availabilityError =
                  'Streaming-Daten sind gerade nicht erreichbar.',
            );
          }
        }
      })(),
      (() async {
        try {
          final value = await widget.store.releases(animeId: anime.id);
          if (current()) setState(() => releases = value);
        } catch (_) {
          if (current()) {
            setState(
              () => releaseError =
                  'Release-Termine sind gerade nicht erreichbar.',
            );
          }
        }
      })(),
    ]);
    if (current()) setState(() => loading = false);
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
          if (error != null ||
              availabilityError != null ||
              releaseError != null) ...[
            Text(error ?? availabilityError ?? releaseError!),
            TextButton(onPressed: _load, child: const Text('Erneut versuchen')),
          ],
          const SizedBox(height: 16),
          Text(anime.synopsis ?? 'Noch keine Beschreibung verfügbar.'),
          ...releases.map(
            (e) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.kind == 'japan'
                          ? 'Nächste Ausstrahlung in Japan'
                          : 'Nächster Release',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(dateLabel(e.startsAt)),
                    Text(
                      e.status == 'estimated'
                          ? 'Voraussichtlich laut regulärem Sendeplan. Pausen sind möglich.'
                          : 'Angekündigter Termin',
                    ),
                    TextButton(
                      onPressed: () => openSource(context, e.source),
                      child: const Text('Terminquelle öffnen'),
                    ),
                  ],
                ),
              ),
            ),
          ),
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
                  'Für diesen Titel und diese Region ist noch keine verlässliche Sprachangabe verfügbar.',
            ),
          if (availability.isEmpty && !loading)
            TextButton.icon(
              onPressed: () => openSource(
                context,
                'https://myanimelist.net/anime/${anime.id}',
              ),
              icon: const Icon(Icons.open_in_new),
              label: const Text('Anbieterübersicht auf MyAnimeList'),
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
