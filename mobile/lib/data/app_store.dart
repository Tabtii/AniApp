import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/anime.dart';
import '../models/content.dart';
import 'catalog.dart';

class AppStore extends ChangeNotifier {
  AppStore(this.preferences, {this.backend, Catalog? catalog})
    : catalog = catalog ?? Catalog(backend: backend);
  final SharedPreferences preferences;
  final SupabaseClient? backend;
  final Catalog catalog;
  List<WatchEntry> entries = [];
  bool busy = false;
  bool cloudLoaded = false;
  String? watchError;
  int _sessionVersion = 0;
  int _mutationVersion = 0;
  bool _disposed = false;
  String? _userId;
  StreamSubscription<AuthState>? _auth;
  String get scope => _userId ?? 'guest';
  String? get email => backend?.auth.currentUser?.email;
  bool get signedIn => _userId != null;
  String get region => preferences.getString('region') ?? 'DE';
  String get language => preferences.getString('language') ?? 'de';
  String get languageMode => preferences.getString('language_mode') ?? 'any';
  bool isSaved(int id) => entries.any((e) => e.anime.id == id);
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> initialize() async {
    _userId = backend?.auth.currentUser?.id;
    _readLocal();
    _auth = backend?.auth.onAuthStateChange.listen((event) {
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

  Future<void> setPreferences(
    String region,
    String language,
    String mode,
  ) async {
    await preferences.setString('region', region);
    await preferences.setString('language', language);
    await preferences.setString('language_mode', mode);
    _notify();
  }

  Future<List<Map<String, dynamic>>> news() async {
    if (backend == null) return [];
    return await backend!
        .from('news')
        .select()
        .eq('published', true)
        .order('published_at', ascending: false)
        .limit(40)
        .timeout(const Duration(seconds: 15));
  }

  Future<List<ReleaseEvent>> releases({int? animeId}) async {
    if (backend == null) return [];
    var query = backend!.from('release_events').select().eq('published', true);
    if (animeId != null) query = query.eq('mal_id', animeId);
    final rows = await query
        .or(
          'and(starts_at.is.null,starts_on.is.null),starts_at.gte.${DateTime.now().toUtc().subtract(const Duration(hours: 24)).toIso8601String()},starts_on.gte.${DateTime.now().toIso8601String().split('T').first}',
        )
        .order('starts_at', ascending: true, nullsFirst: false)
        .limit(200)
        .timeout(const Duration(seconds: 15));
    final result = rows.map((r) => ReleaseEvent(r)).where((e) {
      final location = e.kind == 'japan' || e.region == region;
      final audio =
          languageMode != 'dub' || (e.kind == 'dub' && e.language == language);
      return e.isUpcoming(DateTime.now()) && location && audio;
    }).toList();
    result.sort(
      (a, b) => a.date == null
          ? (b.date == null ? a.title.compareTo(b.title) : 1)
          : b.date == null
          ? -1
          : a.date!.compareTo(b.date!),
    );
    return result;
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
        .eq('audio_language', language)
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
