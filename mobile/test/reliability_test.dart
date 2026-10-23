import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:aniapp/data/app_store.dart';
import 'package:aniapp/models/anime.dart';
import 'package:aniapp/models/content.dart';
import 'package:aniapp/l10n/strings.dart';
import 'package:aniapp/ui/home_screen.dart';

class MemoryCloud {
  final rows = <int, Map<String, dynamic>>{};
  bool offline = false;
  // Like PostgREST max-rows: a single response never exceeds this many rows.
  int maxRows = 1000;
  int reads = 0;
  Completer<void>? holdRead, holdReply;
  Completer<void>? writeApplied;
  int revision = 0;
  late final client = SupabaseClient(
    'https://example.supabase.co',
    'test',
    authOptions: const AuthClientOptions(autoRefreshToken: false),
    httpClient: MockClient((request) async {
      http.Response reply(Object data) => http.Response(
        jsonEncode(data),
        200,
        headers: {'content-type': 'application/json'},
        request: request,
      );
      if (request.url.path.contains('/functions/')) {
        return reply({'reviewer': false});
      }
      if (!request.url.path.contains('watchlist')) return reply([]);
      if (offline) throw http.ClientException('offline');
      if (request.url.path.endsWith('/rpc/sync_watchlist')) {
        final args = jsonDecode(request.body) as Map;
        final id = args['p_mal_id'] as int;
        final row = rows[id];
        final desired = args['p_entry'];
        final current = row == null
            ? null
            : {
                'anime': row['anime_snapshot'],
                'status': row['status'],
                'watched': row['watched_episodes'],
              };
        if (jsonEncode(current) == jsonEncode(desired)) {
          return reply({
            'applied': true,
            'entry': current,
            'revision': row?['revision'],
          });
        }
        if (args['p_expected_revision'] != row?['revision']) {
          return reply({
            'applied': false,
            'entry': current,
            'revision': row?['revision'],
          });
        }
        if (desired == null) {
          rows.remove(id);
        } else {
          rows[id] = {
            'mal_id': id,
            'anime_snapshot': desired['anime'],
            'status': desired['status'],
            'watched_episodes': desired['watched'],
            'revision': 'r${++revision}',
          };
        }
        writeApplied?.complete();
        writeApplied = null;
        if (holdReply != null) await holdReply!.future;
        return reply({
          'applied': true,
          'entry': desired,
          'revision': rows[id]?['revision'],
        });
      }
      if (holdRead != null) await holdRead!.future;
      reads++;
      final sorted = rows.values.toList()
        ..sort((a, b) => (a['mal_id'] as int).compareTo(b['mal_id'] as int));
      final query = request.url.queryParameters;
      final offset = int.tryParse(query['offset'] ?? '') ?? 0;
      final limit = int.tryParse(query['limit'] ?? '') ?? maxRows;
      return reply(
        sorted.skip(offset).take(limit < maxRows ? limit : maxRows).toList(),
      );
    }),
  );
  Future<void> signIn(String id) async {
    String enc(Object data) =>
        base64Url.encode(utf8.encode(jsonEncode(data))).replaceAll('=', '');
    await client.auth.setInitialSession(
      jsonEncode({
        'access_token':
            '${enc({'alg': 'HS256'})}.${enc({'sub': id, 'exp': DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600})}.sig',
        'refresh_token': 'test',
        'token_type': 'bearer',
        'expires_in': 3600,
        'user': {
          'id': id,
          'aud': 'authenticated',
          'email': 'test@example.com',
          'created_at': '2026-01-01T00:00:00Z',
        },
      }),
    );
  }
}

class HomeStore extends AppStore {
  HomeStore(super.preferences);
  int newsLoads = 0, calendarLoads = 0;
  @override
  Future<List<Map<String, dynamic>>> news() async {
    newsLoads++;
    return [];
  }

  @override
  Future<List<ReleaseEvent>> calendarReleases() async {
    calendarLoads++;
    return [];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const original = WatchEntry(
    anime: Anime(id: 1, title: 'Test', episodes: 12),
    status: WatchStatus.watching,
    watched: 3,
  );
  test(
    'undo refuses a stale action and restores only the latest progress edit',
    () async {
      SharedPreferences.setMockInitialValues({});
      final store = AppStore(await SharedPreferences.getInstance());
      await store.initialize();
      await store.save(original);
      final first = await store.changeProgressWithUndo(original, 1);
      final second = await store.changeProgressWithUndo(original, 1);
      expect(store.entries.single.watched, 5);
      expect(await store.undoProgress(first!), false);
      expect(store.entries.single.watched, 5);
      expect(await store.undoProgress(second!), true);
      expect(store.entries.single.watched, 4);
      expect(await store.undoProgress(second), false);
      store.dispose();
    },
  );
  test(
    'two-device conflict survives restart and requires an explicit choice',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final cloud = MemoryCloud();
      await cloud.signIn('11111111-1111-4111-8111-111111111111');
      final first = AppStore(prefs, backend: cloud.client);
      await first.initialize();
      await first.save(original);
      await first.flushPending();
      var second = AppStore(prefs, backend: cloud.client);
      await second.initialize();
      await first.setWatched(1, 8);
      await first.flushPending();
      await second.setWatched(1, 4);
      await second.flushPending();
      expect(second.conflicts.single.remote!.watched, 8);
      expect(second.entries.single.watched, 4);
      expect(cloud.rows[1]!['watched_episodes'], 8);
      second.dispose();
      second = AppStore(prefs, backend: cloud.client);
      await second.initialize();
      expect(second.conflicts.single.remote!.watched, 8);
      expect(second.entries.single.watched, 4);
      await second.resolveConflict(second.conflicts.single, keepLocal: true);
      expect(cloud.rows[1]!['watched_episodes'], 4);
      expect(second.conflicts, isEmpty);
      await first.setWatched(1, 9);
      await first.flushPending();
      expect(first.conflicts, isNotEmpty);
      await first.resolveConflict(first.conflicts.single, keepLocal: false);
      expect(first.entries.single.watched, 4);
      expect(first.pendingChanges, 0);
      first.dispose();
      second.dispose();
      await cloud.client.dispose();
    },
  );
  test(
    'startup returns local data while cloud read is pending; undo cannot cross accounts',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final cloud = MemoryCloud();
      await cloud.signIn('11111111-1111-4111-8111-111111111111');
      await prefs.setString(
        'watchlist_11111111-1111-4111-8111-111111111111',
        jsonEncode([original.toJson()]),
      );
      cloud.holdRead = Completer<void>();
      final store = AppStore(prefs, backend: cloud.client);
      await store
          .initialize(waitForCloud: false)
          .timeout(const Duration(seconds: 1));
      expect(store.entries.single.watched, 3);
      final undo = await store.changeProgressWithUndo(original, 1);
      await cloud.client.auth.signOut(scope: SignOutScope.local);
      await Future<void>.delayed(Duration.zero);
      expect(await store.undoProgress(undo!), false);
      expect(store.entries, isEmpty);
      cloud.holdRead!.complete();
      await store.backgroundSync;
      store.dispose();
      await cloud.client.dispose();
    },
  );
  test(
    'new taps during a cloud write survive its delayed acknowledgement',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final cloud = MemoryCloud();
      await cloud.signIn('11111111-1111-4111-8111-111111111111');
      final store = AppStore(prefs, backend: cloud.client);
      await store.initialize();
      await store.save(original);
      await store.flushPending();
      cloud.holdReply = Completer<void>();
      final applied = cloud.writeApplied = Completer<void>();
      await store.setWatched(1, 4);
      await applied.future;
      await store.setWatched(1, 6);
      expect(store.entries.single.watched, 6);
      cloud.holdReply!.complete();
      await store.flushPending();
      expect(cloud.rows[1]!['watched_episodes'], 6);
      expect(store.pendingChanges, 0);
      store.dispose();
      final restored = AppStore(prefs, backend: cloud.client);
      await restored.initialize();
      expect(restored.entries.single.watched, 6);
      expect(restored.conflicts, isEmpty);
      restored.dispose();
      await cloud.client.dispose();
    },
  );
  testWidgets('Today refreshes on calendar mode and list membership changes', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'app_language': 'en',
      'personal_news': true,
    });
    final store = HomeStore(await SharedPreferences.getInstance());
    await store.initialize();
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: HomeScreen(store: store, navigate: (_) {}),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final before = store.calendarLoads;
    await store.setCalendarMode('dub');
    await tester.pumpAndSettle();
    expect(store.calendarLoads, before + 1);
    final newsBefore = store.newsLoads;
    await store.save(original);
    await tester.pumpAndSettle();
    expect(store.newsLoads, newsBefore + 1);
    await store.changeProgress(original, 1);
    await tester.pumpAndSettle();
    expect(store.newsLoads, newsBefore + 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    store.dispose();
  });

  test(
    'a watchlist longer than one server response is loaded completely',
    () async {
      SharedPreferences.setMockInitialValues({});
      final cloud = MemoryCloud()..maxRows = 300;
      for (var id = 1; id <= 1203; id++) {
        cloud.rows[id] = {
          'mal_id': id,
          'anime_snapshot': {'id': id, 'title': 'Anime $id'},
          'status': 'planned',
          'watched_episodes': 0,
          'revision': 'r$id',
        };
      }
      await cloud.signIn('11111111-1111-4111-8111-111111111111');
      final store = AppStore(
        await SharedPreferences.getInstance(),
        backend: cloud.client,
      );
      await store.initialize(waitForCloud: true);
      expect(store.entries.length, 1203);
      expect(store.entries.map((e) => e.anime.id).toSet().length, 1203);
      expect(cloud.reads, greaterThan(1));
      store.dispose();
      await cloud.client.dispose();
    },
  );
}
