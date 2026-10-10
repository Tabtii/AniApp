import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/anime.dart';
import '../models/content.dart';
import '../models/enrichment.dart';
import 'catalog.dart';

class AppStore extends ChangeNotifier {
  AppStore(
    this.preferences, {
    this.backend,
    Catalog? catalog,
    String Function()? deviceLanguage,
  }) : catalog = catalog ?? Catalog(backend: backend),
       _deviceLanguage =
           deviceLanguage ??
           (() => PlatformDispatcher.instance.locale.languageCode);
  final SharedPreferences preferences;
  final SupabaseClient? backend;
  final Catalog catalog;
  final String Function() _deviceLanguage;
  List<WatchEntry> entries = [];
  bool busy = false;
  bool cloudLoaded = false;
  String? watchError;
  bool passwordRecoveryPending = false;
  void finishPasswordRecovery() {
    passwordRecoveryPending = false;
    _notify();
  }

  int _sessionVersion = 0;
  int _mutationVersion = 0;
  bool _disposed = false;
  String? _userId;
  StreamSubscription<AuthState>? _auth;
  String get scope => _userId ?? 'guest';
  String? get email => backend?.auth.currentUser?.email;
  bool get signedIn => _userId != null;
  static const supportedLanguages = ['de', 'en'];
  String get region {
    final value = preferences.getString('region');
    return ['DE', 'AT', 'CH', 'US', 'GB'].contains(value) ? value! : 'DE';
  }

  String get appLanguage {
    final value = preferences.getString('app_language');
    return supportedLanguages.contains(value) ? value! : 'system';
  }

  String get resolvedAppLanguage => appLanguage == 'system'
      ? (_deviceLanguage() == 'de' ? 'de' : 'en')
      : appLanguage;

  String get newsLanguage {
    final value = preferences.getString('news_language');
    return [...supportedLanguages, 'both'].contains(value) ? value! : 'app';
  }

  List<String> get newsLanguages => newsLanguage == 'both'
      ? supportedLanguages
      : [newsLanguage == 'app' ? resolvedAppLanguage : newsLanguage];

  List<String> get dubLanguages {
    final saved = preferences.getStringList('dub_languages');
    final valid = supportedLanguages
        .where((l) => saved?.contains(l) ?? false)
        .toList();
    if (valid.isNotEmpty) return valid;
    final legacy = preferences.getString('language');
    return [
      supportedLanguages.contains(legacy) ? legacy! : resolvedAppLanguage,
    ];
  }

  // Kept for single-language enrichment requests; never used for news or UI.
  String get language => dubLanguages.first;
  String get languageMode => preferences.getString('language_mode') ?? 'any';
  bool isSaved(int id) => entries.any((e) => e.anime.id == id);
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> initialize() async {
    // Capture the initial audio preference once. Later UI/device-language
    // changes must not silently change the user's dub selection.
    await preferences.setStringList('dub_languages', dubLanguages);
    _userId = backend?.auth.currentUser?.id;
    _readLocal();
    _auth = backend?.auth.onAuthStateChange.listen((event) {
      if (event.event == AuthChangeEvent.passwordRecovery) {
        passwordRecoveryPending = true;
        _notify();
      }
      if (event.event == AuthChangeEvent.signedOut) {
        passwordRecoveryPending = false;
      }
      final next = event.session?.user.id;
      if (next != _userId) {
        _sessionVersion++;
        _userId = next;
        cloudLoaded = false;
        busy = false;
        watchError = null;
        _readLocal();
        _notify();
        unawaited(refreshWatchlist());
      }
    });
    await refreshWatchlist();
  }

  void _readLocal() {
    try {
      entries =
          (jsonDecode(preferences.getString('watchlist_$scope') ?? '[]')
                  as List)
              .map(
                (e) => WatchEntry.fromJson(Map<String, dynamic>.from(e as Map)),
              )
              .toList();
    } catch (_) {
      entries = [];
      watchError = 'Die lokale Watchlist konnte nicht gelesen werden.';
    }
  }

  Future<void> _persist() async {
    if (!await preferences.setString(
      'watchlist_$scope',
      jsonEncode(entries.map((e) => e.toJson()).toList()),
    )) {
      throw StateError('Die Watchlist konnte lokal nicht gespeichert werden.');
    }
  }

  Future<void> refreshWatchlist() async {
    if (busy) return;
    if (!signedIn || backend == null) {
      _notify();
      return;
    }
    final version = _sessionVersion;
    final mutation = _mutationVersion;
    try {
      final rows = await backend!
          .from('watchlist')
          .select()
          .eq('user_id', _userId!)
          .timeout(const Duration(seconds: 15));
      if (version != _sessionVersion ||
          mutation != _mutationVersion ||
          _disposed) {
        return;
      }
      entries = rows
          .map(
            (r) => WatchEntry.fromJson({
              'anime': r['anime_snapshot'],
              'status': r['status'],
              'watched': r['watched_episodes'],
            }),
          )
          .toList();
      await _persist();
      if (version != _sessionVersion || _disposed) return;
      cloudLoaded = true;
      watchError = null;
    } catch (_) {
      if (version == _sessionVersion && mutation == _mutationVersion) {
        watchError =
            'Synchronisierung nicht erreichbar. Deine zuletzt gespeicherte Liste bleibt sichtbar.';
        cloudLoaded = false;
      }
    }
    if (version == _sessionVersion) _notify();
  }

  Future<void> save(WatchEntry entry) async {
    if (busy) return;
    _mutationVersion++;
    busy = true;
    _notify();
    final version = _sessionVersion;
    try {
      if (signedIn) {
        await backend!
            .from('watchlist')
            .upsert({
              'user_id': _userId,
              'mal_id': entry.anime.id,
              'anime_snapshot': entry.anime.toJson(),
              'status': entry.status.name,
              'watched_episodes': entry.watched,
            }, onConflict: 'user_id,mal_id')
            .timeout(const Duration(seconds: 15));
      }
      if (version != _sessionVersion || _disposed) return;
      entries = [...entries.where((e) => e.anime.id != entry.anime.id), entry];
      await _persist();
      watchError = null;
    } finally {
      if (version == _sessionVersion) {
        busy = false;
        _notify();
      }
    }
  }

  Future<void> remove(int id) async {
    if (busy) return;
    _mutationVersion++;
    busy = true;
    _notify();
    final version = _sessionVersion;
    try {
      if (signedIn) {
        await backend!
            .from('watchlist')
            .delete()
            .eq('user_id', _userId!)
            .eq('mal_id', id)
            .timeout(const Duration(seconds: 15));
      }
      if (version != _sessionVersion || _disposed) return;
      entries = entries.where((e) => e.anime.id != id).toList();
      await _persist();
    } finally {
      if (version == _sessionVersion) {
        busy = false;
        _notify();
      }
    }
  }

  Future<void> importGuestList() async {
    if (busy) return;
    final version = _sessionVersion;
    if (!signedIn || !cloudLoaded) {
      throw StateError('Bitte lade zunächst deine Cloud-Watchlist.');
    }
    final guest =
        (jsonDecode(preferences.getString('watchlist_guest') ?? '[]') as List)
            .map(
              (e) => WatchEntry.fromJson(Map<String, dynamic>.from(e as Map)),
            )
            .toList();
    for (final entry in guest) {
      if (version != _sessionVersion || _disposed) {
        throw StateError('Das Konto wurde während des Imports gewechselt.');
      }
      if (!isSaved(entry.anime.id)) await save(entry);
    }
  }

  Future<void> setAppLanguage(String value) async {
    if (![...supportedLanguages, 'system'].contains(value)) return;
    await preferences.setStringList('dub_languages', dubLanguages);
    await preferences.setString('app_language', value);
    _notify();
  }

  Future<void> setNewsLanguage(String value) async {
    if (![...supportedLanguages, 'both', 'app'].contains(value)) return;
    await preferences.setString('news_language', value);
    _notify();
  }

  Future<void> setDubLanguages(List<String> values) async {
    final valid = supportedLanguages.where(values.contains).toList();
    if (valid.isEmpty) return;
    await preferences.setStringList('dub_languages', valid);
    _notify();
  }

  Future<void> setRegion(String value) async {
    if (!['DE', 'AT', 'CH', 'US', 'GB'].contains(value)) return;
    await preferences.setString('region', value);
    _notify();
  }

  Future<void> setCalendarMode(String value) async {
    if (!['any', 'dub'].contains(value)) return;
    await preferences.setString('language_mode', value);
    _notify();
  }

  Future<List<Map<String, dynamic>>> news() async {
    if (backend == null) return [];
    return await backend!
        .from('news')
        .select()
        .eq('published', true)
        .inFilter('language', newsLanguages)
        .order('published_at', ascending: false)
        .limit(40)
        .timeout(const Duration(seconds: 15));
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

  @override
  void dispose() {
    _disposed = true;
    _auth?.cancel();
    catalog.dispose();
    super.dispose();
  }
}
