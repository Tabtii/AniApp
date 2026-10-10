import 'package:flutter/material.dart';
import '../l10n/strings.dart';

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
  Map<String, Map<String, dynamic>> dubObservations = {};
  String? enrichmentError;
  bool loading = true;
  String? error, availabilityError, releaseError;
  String get _settings =>
      '${widget.store.region}|${widget.store.dubLanguages.join(',')}|${widget.store.languageMode}';
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
      dubObservations = {};
      enrichmentError = null;
    });
    releaseError = null;
    await Future.wait([
      for (final language in widget.store.dubLanguages)
        (() async {
          try {
            final value = await widget.store.enrichment(
              anime.id,
              audioLanguage: language,
            );
            if (current()) {
              setState(() {
                dubObservations[language] = value.dub;
                if (language == widget.store.language) enrichment = value;
              });
            }
          } catch (_) {
            if (current()) {
              setState(() {
                dubObservations[language] = {'status': 'unavailable'};
                enrichmentError = context.l10n.enrichmentError;
              });
            }
          }
        })(),
      (() async {
        try {
          final value = await widget.store.catalog.detail(anime.id);
          if (current()) setState(() => anime = value);
        } catch (_) {
          if (current()) {
            setState(() => error = context.l10n.detailLoadError);
          }
        }
      })(),
      (() async {
        try {
          final value = await widget.store.availability(anime.id);
          if (current()) setState(() => availability = value);
        } catch (_) {
          if (current()) {
            setState(() => availabilityError = context.l10n.streamingError);
          }
        }
      })(),
      (() async {
        try {
          final value = await widget.store.dubReleases(anime.id);
          if (current()) setState(() => dubs = value);
        } catch (_) {
          if (current()) {
            setState(() => dubError = context.l10n.dubLoadError);
          }
        }
      })(),
      (() async {
        try {
          final value = await widget.store.releases(animeId: anime.id);
          if (current()) setState(() => releases = value);
        } catch (_) {
          if (current()) {
            setState(() => releaseError = context.l10n.releaseError);
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
    appBar: AppBar(title: Text(context.l10n.detailTitle)),
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
                          '${anime.score?.toStringAsFixed(1) ?? '—'}  ·  ${context.l10n.episodeCount('${anime.episodes ?? '?'}')}',
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
                  ? context.l10n.inYourList
                  : context.l10n.saveWatchlist,
            ),
          ),
          const SizedBox(height: 20),
          for (final language in widget.store.dubLanguages)
            DubPanel(
              language: language,
              region: widget.store.region,
              events: dubs.where((e) => e.language == language).toList(),
              availability: availability,
              loading: loading,
              error: dubError,
              observation: dubObservations[language] ?? const {},
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
            TextButton(onPressed: _load, child: Text(context.l10n.retry)),
          ],
          const SizedBox(height: 16),
          Text(
            context.l10n.story,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Text(
            enrichment.overview ??
                anime.synopsis ??
                enrichment.synopsis ??
                context.l10n.noSynopsis,
            style: TextStyle(
              height: 1.65,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (enrichment.overview != null)
            TextButton(
              onPressed: () =>
                  openSource(context, enrichment.streaming['source'] as String),
              child: Text(context.l10n.tmdbSynopsis),
            ),
          if (enrichment.anilist['status'] == 'ok')
            TextButton(
              onPressed: () =>
                  openSource(context, enrichment.anilist['source'] as String),
              child: Text(context.l10n.anilistCredit),
            ),
          if (enrichment.kitsu['status'] == 'ok')
            TextButton(
              onPressed: () =>
                  openSource(context, enrichment.kitsu['source'] as String),
              child: Text(context.l10n.kitsuCredit),
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
                              ? context.l10n.nextJapan
                              : context.l10n.nextRelease,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          e.startsAt != null
                              ? dateLabel(e.startsAt, context)
                              : e.startsOn != null
                              ? shortDate(e.startsOn, context)
                              : context.l10n.dateTba,
                        ),
                        Text(
                          e.note ??
                              (e.status == 'estimated'
                                  ? context.l10n.weeklyEstimate
                                  : e.status == 'delayed'
                                  ? context.l10n.pausedTba
                                  : context.l10n.announcedDate),
                        ),
                        TextButton(
                          onPressed: () => openSource(context, e.source),
                          child: Text(context.l10n.openDateSource),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          if (anime.broadcast != null) ...[
            const SizedBox(height: 20),
            Text(
              context.l10n.regularJapan,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(anime.broadcast!),
            Text(context.l10n.japanNotLocal),
          ],
          const SizedBox(height: 24),
          Text(
            context.l10n.whereWatch(widget.store.region),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          if (availability.isEmpty && enrichment.providers.isEmpty && !loading)
            Text(availabilityError ?? context.l10n.noProviders),
          if (availability.isEmpty && enrichment.providers.isEmpty && !loading)
            TextButton.icon(
              onPressed: () => openSource(
                context,
                'https://myanimelist.net/anime/${anime.id}',
              ),
              icon: const Icon(Icons.open_in_new),
              label: Text(context.l10n.malProviders),
            ),
          if (enrichment.streaming['status'] == 'unavailable')
            Text(context.l10n.tmdbUnavailable),
          if (enrichment.providers.isNotEmpty) ...[
            Text(context.l10n.providerCredit),
            TextButton(
              onPressed: () =>
                  openSource(context, 'https://github.com/Fribb/anime-lists'),
              child: Text(context.l10n.titleMapping),
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
                          ? context.l10n.reportedAvailable
                          : context.l10n.announced,
                    ),
                    Text(
                      a.scope == 'episode'
                          ? context.l10n.episodeNumber('${a.episode ?? '?'}')
                          : a.scope == 'movie'
                          ? context.l10n.movieScope
                          : a.scope == 'season'
                          ? context.l10n.seasonScope('${a.season ?? '?'}')
                          : context.l10n.seriesScope,
                    ),
                    if (a.offers.isNotEmpty)
                      Text(
                        a.offers
                            .map(
                              (o) =>
                                  {
                                    'flatrate': context.l10n.subscription,
                                    'free': context.l10n.free,
                                    'ads': context.l10n.withAds,
                                    'rent': context.l10n.rent,
                                    'buy': context.l10n.buy,
                                  }[o] ??
                                  o,
                            )
                            .join(' · '),
                      ),
                    if (a.sourceName != null)
                      Text(context.l10n.sourceName(a.sourceName!)),
                    Text(
                      context.l10n.audioLabel(
                        a.audio == null
                            ? context.l10n.unknown
                            : a.audio!.isEmpty
                            ? context.l10n.noInformation
                            : a.audio!
                                  .map((code) => languageLabel(code, context))
                                  .join(', '),
                      ),
                    ),
                    Text(
                      context.l10n.subtitleLabel(
                        a.subtitles == null
                            ? context.l10n.unknown
                            : a.subtitles!.isEmpty
                            ? context.l10n.noInformation
                            : a.subtitles!
                                  .map((code) => languageLabel(code, context))
                                  .join(', '),
                      ),
                    ),
                    Text(
                      context.l10n.lastChecked(
                        dateLabel(
                          DateTime.tryParse(a.checkedAt)?.toLocal(),
                          context,
                        ),
                      ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    TextButton.icon(
                      onPressed: () => openSource(context, a.url),
                      icon: const Icon(Icons.open_in_new),
                      label: Text(
                        a.sourceName == 'TMDb / JustWatch'
                            ? context.l10n.tmdbOffers
                            : context.l10n.checkProvider,
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
