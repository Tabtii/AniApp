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

part 'store/settings.dart';
part 'store/companion.dart';
part 'store/content.dart';

// Watchlist sync and the account session live here; preferences, editorial
// and inbox features, and read-only content queries are split into mixins.
class AppStore extends ChangeNotifier with _Settings, _Companion, _Content {
  AppStore(
    this.preferences, {
    this.backend,
    Catalog? catalog,
    String Function()? deviceLanguage,
  }) : catalog = catalog ?? Catalog(backend: backend),
       _deviceLanguage =
           deviceLanguage ??
           (() => PlatformDispatcher.instance.locale.languageCode);
  @override
  final SharedPreferences preferences;
  @override
  final SupabaseClient? backend;
  final Catalog catalog;
  @override
  final String Function() _deviceLanguage;
  @override
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
  bool cloudLoaded = false;
  String? watchError;
  bool passwordRecoveryPending = false;
  void finishPasswordRecovery() {
    passwordRecoveryPending = false;
    _notify();
  }

  @override
  int _sessionVersion = 0;
  int _mutationVersion = 0;
  int _refreshVersion = 0;
  @override
  bool _disposed = false;
  @override
  String? _userId;
  StreamSubscription<AuthState>? _auth;
  String get scope => _userId ?? 'guest';
  String? get email => backend?.auth.currentUser?.email;
  @override
  bool get signedIn => _userId != null;
  static const supportedLanguages = ['de', 'en'];
  bool isSaved(int id) => entries.any((e) => e.anime.id == id);
  @override
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

  @override
  void dispose() {
    _disposed = true;
    _auth?.cancel();
    catalog.dispose();
    super.dispose();
  }
}
