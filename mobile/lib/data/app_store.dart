import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/anime.dart';
import '../models/content.dart';
import '../models/enrichment.dart';
import '../models/watch_sync.dart';
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
  bool syncing = false;
  Future<void>? _syncFuture;
  int _syncSession = -1;
  Map<String, dynamic> _pending = {};
  Map<String, String?> _revisions = {};
  Map<String, String?> _bases = {};
  Map<int, WatchConflict> _conflicts = {};
  final Map<int, int> _edits = {};
  List<WatchConflict> get conflicts => List.unmodifiable(_conflicts.values);
  Future<void> backgroundSync = Future.value();
  Future<void> _writes = Future.value();
  int get pendingChanges => _pending.length;
  List<String> get providers => preferences.getStringList('providers') ?? [];
  List<String> get mutedSources =>
      preferences.getStringList('muted_sources') ?? [];
  bool get spoilerSafe => preferences.getBool('spoiler_safe') ?? false;
  bool get personalNews => preferences.getBool('personal_news') ?? false;
  Future<void> setPreference(String key, Object value) async {
    if (value is bool) await preferences.setBool(key, value);
    if (value is List<String>) await preferences.setStringList(key, value);
    _notify();
  }

  bool get isReviewer => _isReviewer;
  int unreadCount = 0;
  Future<void> refreshUnreadCount() async {
    final session = _sessionVersion;
    if (!signedIn || backend == null) {
      unreadCount = 0;
      _notify();
      return;
    }
    try {
      final rows = await backend!
          .from('release_inbox')
          .select('id')
          .eq('user_id', _userId!)
          .isFilter('read_at', null)
          .eq('superseded', false)
          .limit(100)
          .timeout(const Duration(seconds: 10));
      if (session == _sessionVersion && !_disposed) {
        unreadCount = rows.length;
        _notify();
      }
    } catch (_) {
      /* An optional badge never blocks local progress. */
    }
  }

  bool _isReviewer = false;
  Future<void> checkReviewer() async {
    _isReviewer = false;
    if (signedIn) {
      final version = _sessionVersion;
      try {
        final response = await backend!.functions.invoke(
          'companion-account',
          body: {'action': 'role'},
        );
        if (version == _sessionVersion) {
          _isReviewer = response.data?['reviewer'] == true;
        }
      } catch (_) {
        /* Optional editorial access never blocks the app. */
      }
    }
    _notify();
  }

  bool cloudLoaded = false;
  String? watchError;
  bool passwordRecoveryPending = false;
  void finishPasswordRecovery() {
    passwordRecoveryPending = false;
    _notify();
  }

  int _sessionVersion = 0;
  int _mutationVersion = 0;
  int _refreshVersion = 0;
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

  Future<void> initialize({bool waitForCloud = true}) async {
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
        syncing = false;
        _edits.clear();
        unreadCount = 0;
        unawaited(refreshUnreadCount());
        unawaited(checkReviewer());
        watchError = null;
        _readLocal();
        _notify();
        unawaited(refreshWatchlist());
      }
    });
    unawaited(checkReviewer());
    unawaited(refreshUnreadCount());
    backgroundSync = refreshWatchlist();
    if (waitForCloud) await backgroundSync;
  }

  void _readLocal() {
    try {
      final raw = preferences.getString('watch_state_$scope');
      final state = raw == null ? null : jsonDecode(raw) as Map;
      entries =
          ((state?['entries'] ??
                      jsonDecode(
                        preferences.getString('watchlist_$scope') ?? '[]',
                      ))
                  as List)
              .map(
                (e) => WatchEntry.fromJson(Map<String, dynamic>.from(e as Map)),
              )
              .toList();
      _pending = Map<String, dynamic>.from(state?['pending'] as Map? ?? {});
      _revisions = Map<String, String?>.from(state?['revisions'] as Map? ?? {});
      _bases = Map<String, String?>.from(state?['bases'] as Map? ?? {});
      _conflicts = {
        for (final item in state?['conflicts'] as List? ?? [])
          (item['id'] as num).toInt(): WatchConflict.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
      };
    } catch (_) {
      entries = [];
      _pending = {};
      _revisions = {};
      _bases = {};
      _conflicts = {};
      watchError = 'Die lokale Watchlist konnte nicht gelesen werden.';
    }
  }

  // Entries and the outbox are one durable record: a process exit cannot save
  // progress without also saving the operation needed to synchronise it.
  Future<void> _persist() async {
    final key = 'watch_state_$scope';
    final value = jsonEncode({
      'entries': entries.map((e) => e.toJson()).toList(),
      'pending': _pending,
      'revisions': _revisions,
      'bases': _bases,
      'conflicts': _conflicts.values.map((e) => e.toJson()).toList(),
    });
    if (!await preferences.setString(key, value)) {
      throw StateError('Die Watchlist konnte lokal nicht gespeichert werden.');
    }
  }

  Future<void> flushPending() {
    if (_syncFuture != null && _syncSession == _sessionVersion) {
      return _syncFuture!;
    }
    final running = _flushPending();
    _syncFuture = running;
    _syncSession = _sessionVersion;
    running.whenComplete(() {
      if (identical(_syncFuture, running)) _syncFuture = null;
    });
    return running;
  }

  Future<void> _flushPending() async {
    if (syncing || !signedIn || backend == null || _disposed) return;
    final version = _sessionVersion;
    syncing = true;
    _notify();
    try {
      while (_pending.isNotEmpty && version == _sessionVersion && !_disposed) {
        final id = _pending.keys
            .where((key) => !_conflicts.containsKey(int.parse(key)))
            .firstOrNull;
        if (id == null) break;
        final operation = _pending[id];
        final fingerprint = jsonEncode(operation);
        final response = Map<String, dynamic>.from(
          await backend!
                  .rpc(
                    'sync_watchlist',
                    params: {
                      'p_mal_id': int.parse(id),
                      'p_expected_revision': _bases[id],
                      'p_entry': operation,
                    },
                  )
                  .timeout(const Duration(seconds: 15))
              as Map,
        );
        final applying = _writes.then((_) async {
          if (version != _sessionVersion || _disposed) return;
          final revision = response['revision'] as String?;
          _revisions[id] = revision;
          if (response['applied'] != true) {
            _conflicts[int.parse(id)] = WatchConflict(
              id: int.parse(id),
              revision: revision,
              remote: response['entry'] == null
                  ? null
                  : WatchEntry.fromJson(
                      Map<String, dynamic>.from(response['entry'] as Map),
                    ),
            );
            await _persist();
            return;
          }
          // A newer tap during a request must remain queued.
          if (_pending.containsKey(id) &&
              jsonEncode(_pending[id]) == fingerprint) {
            _pending.remove(id);
            _bases.remove(id);
          } else if (_pending.containsKey(id)) {
            _bases[id] = revision;
          }
          await _persist();
        });
        _writes = applying.catchError((Object _) {});
        await applying;
      }
      if (version == _sessionVersion) watchError = null;
    } catch (_) {
      if (version == _sessionVersion) {
        watchError =
            'Offline: Änderungen sind auf diesem Gerät gespeichert und werden erneut synchronisiert.';
      }
    } finally {
      if (version == _sessionVersion) {
        syncing = false;
        _notify();
      }
    }
  }

  Future<void> refreshWatchlist() async {
    await _writes;
    await flushPending();
    if (!signedIn || backend == null) {
      _notify();
      return;
    }
    final version = _sessionVersion;
    final mutation = _mutationVersion;
    final refresh = ++_refreshVersion;
    try {
      // The API caps every response (possibly below the page size), so long
      // lists are read in a stable key order until an empty page arrives.
      const pageSize = 500;
      final deadline = DateTime.now().add(const Duration(seconds: 15));
      final rows = <Map<String, dynamic>>[];
      while (true) {
        final remaining = deadline.difference(DateTime.now());
        if (remaining <= Duration.zero || rows.length >= 100000) {
          throw TimeoutException('Watchlist could not be loaded completely.');
        }
        final batch = await backend!
            .from('watchlist')
            .select()
            .eq('user_id', _userId!)
            .order('mal_id')
            .range(rows.length, rows.length + pageSize - 1)
            .timeout(remaining);
        if (batch.isEmpty) break;
        rows.addAll(batch);
      }
      final applying = _writes.then((_) async {
        if (version != _sessionVersion ||
            mutation != _mutationVersion ||
            refresh != _refreshVersion ||
            _disposed) {
          return;
        }
        final merged = <int, WatchEntry>{
          for (final r in rows)
            (r['mal_id'] as num).toInt(): WatchEntry.fromJson({
              'anime': r['anime_snapshot'],
              'status': r['status'],
              'watched': r['watched_episodes'],
            }),
        };
        _revisions = {
          for (final r in rows) '${r['mal_id']}': r['revision'] as String?,
        };
        for (final op in _pending.entries) {
          if (op.value == null) {
            merged.remove(int.parse(op.key));
          } else {
            merged[int.parse(op.key)] = WatchEntry.fromJson(
              Map<String, dynamic>.from(op.value as Map),
            );
          }
        }
        for (final id in {...entries.map((e) => e.anime.id), ...merged.keys}) {
          final before = entries.where((e) => e.anime.id == id).firstOrNull;
          if (jsonEncode(before?.toJson()) !=
              jsonEncode(merged[id]?.toJson())) {
            _edits[id] = (_edits[id] ?? 0) + 1;
          }
        }
        entries = merged.values.toList();
        await _persist();
        if (version != _sessionVersion || _disposed) return;
        cloudLoaded = true;
        if (_pending.isEmpty) watchError = null;
      });
      _writes = applying.catchError((Object _) {});
      await applying;
    } catch (_) {
      if (version == _sessionVersion && mutation == _mutationVersion) {
        watchError =
            'Synchronisierung nicht erreichbar. Deine lokale Liste bleibt verfügbar.';
        cloudLoaded = false;
      }
    }
    if (version == _sessionVersion) _notify();
  }

  Future<void> _change(
    int id,
    WatchEntry? entry, {
    int? delta,
    WatchStatus? status,
    int? watched,
    ProgressUndo? undo,
    void Function(ProgressUndo)? onUndo,
  }) {
    final version = _sessionVersion;
    final next = _writes.then((_) async {
      if (version != _sessionVersion || _disposed) {
        throw StateError('Das Konto wurde gewechselt.');
      }
      final latest = entries.where((e) => e.anime.id == id).firstOrNull;
      if (undo != null &&
          (undo.session != _sessionVersion || _edits[id] != undo.edit)) {
        throw StateError('undo_expired');
      }
      if (delta != null || status != null || watched != null) {
        if (latest == null) return;
        entry = delta != null
            ? latest.progress(delta)
            : status != null
            ? latest.withStatus(status)
            : latest.progress(watched! - latest.watched);
      }
      final changedEntry = entry;
      final previous = entries;
      final previousPending = Map<String, dynamic>.from(_pending);
      final previousBases = Map<String, String?>.from(_bases);
      _mutationVersion++;
      entries = [
        ...entries.where((e) => e.anime.id != id),
        if (changedEntry != null) changedEntry,
      ];
      if (signedIn) {
        if (!_pending.containsKey('$id')) _bases['$id'] = _revisions['$id'];
        _pending['$id'] = entry?.toJson();
      }
      try {
        await _persist();
      } catch (_) {
        if (version == _sessionVersion) {
          entries = previous;
          _pending = previousPending;
          _bases = previousBases;
        }
        rethrow;
      }
      if (version == _sessionVersion) {
        final edit = (_edits[id] ?? 0) + 1;
        _edits[id] = edit;
        if (latest != null) onUndo?.call(ProgressUndo(latest, version, edit));
        _notify();
        unawaited(flushPending());
      }
    });
    // Keep the queue usable after a failed disk write, while reporting it to the caller.
    _writes = next.catchError((Object _) {});
    return next;
  }

  Future<void> save(WatchEntry entry) => _change(entry.anime.id, entry);
  Future<void> remove(int id) => _change(id, null);
  Future<void> changeProgress(WatchEntry entry, int delta) =>
      _change(entry.anime.id, entry, delta: delta);
  Future<void> setStatus(int id, WatchStatus status) =>
      _change(id, null, status: status);
  Future<void> setWatched(int id, int count) =>
      _change(id, null, watched: count);

  Future<ProgressUndo?> changeProgressWithUndo(
    WatchEntry entry,
    int delta,
  ) async {
    ProgressUndo? token;
    await _change(
      entry.anime.id,
      entry,
      delta: delta,
      onUndo: (value) => token = value,
    );
    return token;
  }

  Future<bool> undoProgress(ProgressUndo token) async {
    if (token.session != _sessionVersion ||
        _edits[token.before.anime.id] != token.edit) {
      return false;
    }
    try {
      await _change(token.before.anime.id, token.before, undo: token);
      return true;
    } on StateError catch (e) {
      if (e.message == 'undo_expired') return false;
      rethrow;
    }
  }

  Future<void> resolveConflict(
    WatchConflict conflict, {
    required bool keepLocal,
  }) async {
    final session = _sessionVersion;
    final next = _writes.then((_) async {
      if (session != _sessionVersion ||
          !identical(_conflicts[conflict.id], conflict)) {
        return;
      }
      final key = '${conflict.id}';
      final oldEntries = entries;
      final oldPending = Map<String, dynamic>.from(_pending);
      final oldBases = Map<String, String?>.from(_bases);
      final oldRevisions = Map<String, String?>.from(_revisions);
      if (keepLocal) {
        _bases[key] = conflict.revision;
      } else {
        _revisions[key] = conflict.revision;
        _pending.remove(key);
        _bases.remove(key);
        entries = [
          ...entries.where((e) => e.anime.id != conflict.id),
          if (conflict.remote != null) conflict.remote!,
        ];
      }
      _conflicts.remove(conflict.id);
      _mutationVersion++;
      _edits[conflict.id] = (_edits[conflict.id] ?? 0) + 1;
      try {
        await _persist();
      } catch (_) {
        if (session == _sessionVersion) {
          entries = oldEntries;
          _pending = oldPending;
          _bases = oldBases;
          _revisions = oldRevisions;
          _conflicts[conflict.id] = conflict;
        }
        rethrow;
      }
      if (session == _sessionVersion) _notify();
    });
    _writes = next.catchError((Object _) {});
    await next;
    if (session == _sessionVersion) await flushPending();
  }

  Future<int> importEntries(List<WatchEntry> incoming) async {
    final version = _sessionVersion;
    var added = 0;
    for (final entry in incoming) {
      if (version != _sessionVersion || _disposed) {
        throw StateError('Das Konto wurde gewechselt.');
      }
      // Existing progress always wins; importing a file never resets it.
      if (!isSaved(entry.anime.id)) {
        await save(entry);
        added++;
      }
    }
    return added;
  }

  Future<void> importGuestList() async {
    if (!signedIn || !cloudLoaded) {
      throw StateError('Bitte lade zunächst deine Cloud-Watchlist.');
    }
    final state = preferences.getString('watch_state_guest');
    final rows = state == null
        ? jsonDecode(preferences.getString('watchlist_guest') ?? '[]')
        : jsonDecode(state)['entries'];
    await importEntries(
      (rows as List)
          .map((e) => WatchEntry.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }

  Future<List<Map<String, dynamic>>> inbox() async {
    if (!signedIn || backend == null) return [];
    return await backend!
        .from('release_inbox')
        .select()
        .eq('user_id', _userId!)
        .order('created_at', ascending: false)
        .limit(60);
  }

  Future<void> markRead(String id) async {
    if (signedIn) {
      await backend!
          .from('release_inbox')
          .update({'read_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', id)
          .eq('user_id', _userId!);
      await refreshUnreadCount();
    }
  }

  Future<List<Map<String, dynamic>>> follows(int id) async {
    if (!signedIn) return [];
    return await backend!
        .from('dub_follows')
        .select()
        .eq('user_id', _userId!)
        .eq('mal_id', id)
        .eq('region', region);
  }

  Future<void> followDub(int id, bool enabled) async {
    if (!signedIn) {
      throw StateError('Bitte melde dich für Dub-Mitteilungen an.');
    }
    if (enabled) {
      await backend!.from('dub_follows').upsert([
        for (final lang in dubLanguages)
          {
            'user_id': _userId!,
            'mal_id': id,
            'region': region,
            'audio_language': lang,
          },
      ], onConflict: 'user_id,mal_id,region,audio_language');
    } else {
      await backend!
          .from('dub_follows')
          .delete()
          .eq('user_id', _userId!)
          .eq('mal_id', id)
          .eq('region', region);
    }
    _notify();
  }

  Future<List<Map<String, dynamic>>> sourceHealth() async => backend == null
      ? []
      : await backend!.from('source_status').select().order('source_key');
  Future<dynamic> editorial(Map<String, dynamic> body) async {
    final result = await backend!.functions.invoke(
      'companion-account',
      body: body,
    );
    if (result.status != 200) throw StateError('Anfrage fehlgeschlagen');
    return result.data;
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

  @override
  void dispose() {
    _disposed = true;
    _auth?.cancel();
    catalog.dispose();
    super.dispose();
  }
}
