import 'package:flutter/material.dart';

import '../data/app_store.dart';
import '../models/anime.dart';
import '../models/content.dart';
import '../models/enrichment.dart';
import 'common.dart';
import 'visuals.dart';
import 'dub_panel.dart';
import 'kitsu_panel.dart';

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
  List<ReleaseEvent> dubs = [];
  String? dubError;
  AnimeEnrichment enrichment = AnimeEnrichment.empty;
  String? enrichmentError;
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
      dubs = [];
      dubError = null;
      enrichment = AnimeEnrichment.empty;
      enrichmentError = null;
    });
    releaseError = null;
    await Future.wait([
      (() async {
        try {
          final value = await widget.store.enrichment(anime.id);
          if (current()) setState(() => enrichment = value);
        } catch (_) {
          if (current()) {
            setState(
              () => enrichmentError =
                  'Zusätzliche Sprach- und Anbieterdaten sind gerade nicht erreichbar.',
            );
          }
        }
      })(),
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
          final value = await widget.store.dubReleases(anime.id);
          if (current()) setState(() => dubs = value);
        } catch (_) {
          if (current()) {
            setState(
              () =>
                  dubError = 'Dub-Ankündigungen konnten nicht geladen werden.',
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
    if (current()) {
      setState(() {
        loading = false;
        if (enrichment.kitsu['status'] == 'ok') error = null;
      });
    }
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
          ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: SizedBox(
              height: 360,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Artwork(
                    enrichment.banner ?? anime.image,
                    fallbackUrl: anime.image,
                    alignment: Alignment.topCenter,
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Color(0x33090F1C),
                          Color(0xFF090F1C),
                        ],
                        stops: [0, .4, 1],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 22,
                    right: 22,
                    bottom: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Tag(
                          '${anime.score?.toStringAsFixed(1) ?? '—'}  ·  ${anime.episodes ?? '?'} Folgen',
                          icon: Icons.star_rounded,
                          color: lime,
                          solid: true,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          anime.title,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 28,
                            height: 1.08,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: widget.store.busy || widget.store.isSaved(anime.id)
                ? null
                : () => perform(
                    context,
                    () => widget.store.save(WatchEntry(anime: anime)),
                  ),
            icon: Icon(
              widget.store.isSaved(anime.id)
                  ? Icons.bookmark_added_rounded
                  : Icons.bookmark_add_rounded,
            ),
            label: Text(
              widget.store.isSaved(anime.id)
                  ? 'In deiner Liste'
                  : 'Auf meine Watchlist',
            ),
          ),
          const SizedBox(height: 20),
          DubPanel(
            language: widget.store.language,
            region: widget.store.region,
            events: dubs,
            availability: availability,
            loading: loading,
            error: dubError,
            observation: enrichment.dub,
            onRetry: _load,
          ),
          const SizedBox(height: 6),
          KitsuPanel(data: enrichment.kitsu),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: anime.genres.map((g) => Chip(label: Text(g))).toList(),
          ),
          if (loading) const LinearProgressIndicator(),
          if (error != null ||
              availabilityError != null ||
              releaseError != null ||
              enrichmentError != null) ...[
            Text(
              error ?? availabilityError ?? releaseError ?? enrichmentError!,
            ),
            TextButton(onPressed: _load, child: const Text('Erneut versuchen')),
          ],
          const SizedBox(height: 16),
          Text(
            'Die Geschichte',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Text(
            enrichment.overview ??
                anime.synopsis ??
                enrichment.synopsis ??
                'Noch keine Beschreibung verfügbar.',
            style: TextStyle(
              height: 1.65,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (enrichment.overview != null)
            TextButton(
              onPressed: () =>
                  openSource(context, enrichment.streaming['source'] as String),
              child: const Text('Deutsche Beschreibung: TMDb'),
            ),
          if (enrichment.anilist['status'] == 'ok')
            TextButton(
              onPressed: () =>
                  openSource(context, enrichment.anilist['source'] as String),
              child: const Text('Bilder & Episodentermine: AniList'),
            ),
          if (enrichment.kitsu['status'] == 'ok')
            TextButton(
              onPressed: () =>
                  openSource(context, enrichment.kitsu['source'] as String),
              child: const Text('Zusätzliche Bilder & Infos: Kitsu'),
            ),
          const SizedBox(height: 20),
          ...mergeJapanSchedule(releases, [
                if (enrichment.nextRelease != null) enrichment.nextRelease!,
              ])
              .where((e) => e.kind != 'dub')
              .map(
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
                        Text(
                          e.startsAt != null
                              ? dateLabel(e.startsAt)
                              : e.startsOn != null
                              ? shortDate(e.startsOn)
                              : 'Termin noch offen',
                        ),
                        Text(
                          e.note ??
                              (e.status == 'estimated'
                                  ? 'Voraussichtlich laut regulärem Sendeplan. Pausen sind möglich.'
                                  : e.status == 'delayed'
                                  ? 'Pause oder Verschiebung – Termin offen'
                                  : 'Angekündigter Termin'),
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
          if (availability.isEmpty && enrichment.providers.isEmpty && !loading)
            Text(
              availabilityError ??
                  'Für diesen Titel und diese Region liegen noch keine verlässlichen Anbieterangaben vor.',
            ),
          if (availability.isEmpty && enrichment.providers.isEmpty && !loading)
            TextButton.icon(
              onPressed: () => openSource(
                context,
                'https://myanimelist.net/anime/${anime.id}',
              ),
              icon: const Icon(Icons.open_in_new),
              label: const Text('Anbieterübersicht auf MyAnimeList'),
            ),
          if (enrichment.streaming['status'] == 'unavailable')
            const Text('TMDb / JustWatch ist gerade nicht erreichbar.'),
          if (enrichment.providers.isNotEmpty) ...[
            const Text(
              'Anbieterdaten: JustWatch über TMDb. Verfügbarkeit und Sprachen bitte beim Anbieter prüfen.',
            ),
            TextButton(
              onPressed: () =>
                  openSource(context, 'https://github.com/Fribb/anime-lists'),
              child: const Text('Titelzuordnung: Fribb / anime-lists'),
            ),
          ],
          ...[...availability, ...enrichment.providers].map(
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
                          : a.scope == 'movie'
                          ? 'Angabe für den Film.'
                          : a.scope == 'season'
                          ? 'Angabe für Staffel ${a.season ?? '?'}; Episodenabdeckung bitte prüfen.'
                          : 'Angabe für die Serie; kann je Staffel und Folge abweichen.',
                    ),
                    if (a.offers.isNotEmpty)
                      Text(
                        a.offers
                            .map(
                              (o) =>
                                  const {
                                    'flatrate': 'Abo',
                                    'free': 'Kostenlos',
                                    'ads': 'Mit Werbung',
                                    'rent': 'Leihen',
                                    'buy': 'Kaufen',
                                  }[o] ??
                                  o,
                            )
                            .join(' · '),
                      ),
                    if (a.sourceName != null) Text('Quelle: ${a.sourceName}'),
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
                      label: Text(
                        a.sourceName == 'TMDb / JustWatch'
                            ? 'Angebote auf TMDb öffnen'
                            : 'Beim Anbieter prüfen',
                      ),
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
