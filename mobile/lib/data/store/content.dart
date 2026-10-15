part of '../app_store.dart';

// Read-only shared content: news, release calendar, enrichment, providers.
mixin _Content on _Settings {
  SupabaseClient? get backend;
  List<WatchEntry> get entries;

  Future<List<Map<String, dynamic>>> news() async {
    if (backend == null) return [];
    final rows = List<Map<String, dynamic>>.from(
      await backend!
              .rpc(
                'companion_news',
                params: {
                  'p_languages': newsLanguages,
                  'p_region': region,
                  'p_providers': providers,
                  'p_muted': mutedSources,
                  'p_ids': personalNews
                      ? entries.map((e) => e.anime.id).toList()
                      : null,
                },
              )
              .timeout(const Duration(seconds: 15))
          as List,
    );
    final seen = <String>{};
    return rows.where((n) {
      final url = Uri.tryParse(n['source_url'] as String? ?? '');
      final key = url == null ? '${n['id']}' : '${url.host}${url.path}';
      return seen.add(key);
    }).toList();
  }

  Future<List<ReleaseEvent>> releases({int? animeId}) =>
      _loadReleases(animeId).timeout(const Duration(seconds: 20));

  Future<AnimeEnrichment> enrichment(int id, {String? audioLanguage}) async {
    if (backend == null) return AnimeEnrichment.empty;
    final selectedRegion = region, selectedLanguage = audioLanguage ?? language;
    final result = await backend!.functions
        .invoke(
          'anime-enrichment',
          body: {
            'mal_id': id,
            'region': selectedRegion,
            'language': selectedLanguage,
          },
        )
        .timeout(const Duration(seconds: 32));
    if (result.status != 200 ||
        result.data is! Map ||
        result.data['mal_id'] != id ||
        result.data['region'] != selectedRegion ||
        result.data['language'] != selectedLanguage) {
      throw StateError('Zusatzinformationen sind nicht erreichbar.');
    }
    return AnimeEnrichment(Map<String, dynamic>.from(result.data as Map));
  }

  Future<List<ReleaseEvent>> _aniSchedule() async {
    if (backend == null || languageMode == 'dub') return [];
    try {
      final result = await backend!.functions
          .invoke(
            'anime-enrichment',
            body: {'mode': 'calendar', 'region': region, 'language': language},
          )
          .timeout(const Duration(seconds: 8));
      if (result.status != 200 ||
          result.data is! Map ||
          result.data['status'] != 'ok') {
        return [];
      }
      return (result.data['events'] as List)
          .map((e) => ReleaseEvent(Map<String, dynamic>.from(e as Map)))
          .where((e) => e.kind == 'japan' && e.isUpcoming(DateTime.now()))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<ReleaseEvent>> calendarReleases() async {
    final results = await Future.wait([releases(), _aniSchedule()]);
    return mergeJapanSchedule(results[0], results[1]);
  }

  Future<List<ReleaseEvent>> _loadReleases(int? animeId) async {
    if (backend == null) return [];
    final now = DateTime.now();
    final deadline = now.add(const Duration(seconds: 20));
    final selectedRegion = region;
    final selectedLanguages = dubLanguages;
    final dubOnly = languageMode == 'dub';
    final result = <ReleaseEvent>[];
    // Provider schedules can contain more than 200 episodes. Read every page;
    // stable ID ordering prevents equal/undated timestamps from shuffling pages.
    for (var page = 0; page < 20; page++) {
      var query = backend!
          .from('release_events')
          .select()
          .eq('published', true);
      if (animeId != null) query = query.eq('mal_id', animeId);
      query = query
          .or('kind.eq.japan,region.eq.$selectedRegion')
          .or(
            'and(starts_at.is.null,starts_on.is.null),starts_at.gte.${now.toUtc().subtract(const Duration(hours: 24)).toIso8601String()},starts_on.gte.${now.toIso8601String().split('T').first}',
          );
      if (dubOnly) {
        query = query
            .eq('kind', 'dub')
            .inFilter('audio_language', selectedLanguages);
      } else {
        query = query.or(
          'kind.neq.dub,audio_language.in.(${selectedLanguages.join(',')})',
        );
      }
      final remaining = deadline.difference(DateTime.now());
      if (remaining <= Duration.zero) {
        throw TimeoutException(
          'Kalender konnte nicht vollständig geladen werden.',
        );
      }
      final rows = await query
          .order('id')
          .range(page * 200, page * 200 + 199)
          .timeout(remaining);
      result.addAll(
        rows
            .map(ReleaseEvent.new)
            .where(
              (e) =>
                  e.isUpcoming(now) &&
                  (e.kind == 'japan' || e.region == selectedRegion) &&
                  (e.kind != 'dub' || selectedLanguages.contains(e.language)) &&
                  (!dubOnly || e.kind == 'dub'),
            ),
      );
      if (rows.length < 200) {
        result.sort(
          (a, b) => a.date == null
              ? (b.date == null ? a.title.compareTo(b.title) : 1)
              : b.date == null
              ? -1
              : a.date!.compareTo(b.date!),
        );
        return result;
      }
    }
    throw StateError('Zu viele Termine. Bitte den Sprachfilter verwenden.');
  }

  Future<List<ReleaseEvent>> dubReleases(int id) async {
    if (backend == null) return [];
    final rows = await backend!
        .from('release_events')
        .select()
        .eq('published', true)
        .eq('mal_id', id)
        .eq('kind', 'dub')
        .eq('region', region)
        .inFilter('audio_language', dubLanguages)
        .order('checked_at', ascending: false)
        .limit(50)
        .timeout(const Duration(seconds: 15));
    return rows.map(ReleaseEvent.new).toList();
  }

  Future<List<Availability>> availability(int id) async {
    if (backend == null) return [];
    final rows = await backend!
        .from('availability')
        .select()
        .eq('mal_id', id)
        .eq('region', region)
        .eq('published', true)
        .order('checked_at', ascending: false)
        .limit(50)
        .timeout(const Duration(seconds: 15));
    return rows.map((r) => Availability(r)).toList();
  }
}
