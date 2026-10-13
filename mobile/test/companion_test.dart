import 'dart:async';
import 'dart:convert';
import 'package:aniapp/data/app_store.dart';
import 'package:aniapp/data/list_transfer.dart';
import 'package:aniapp/models/anime.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'MAL import preserves exact IDs, previews bad entries and never expands entities',
    () {
      final result = parseWatchlist(
        '''<?xml version="1.0"?><myanimelist><anime><series_animedb_id>12</series_animedb_id><series_title><![CDATA[Season & Two]]></series_title><series_episodes>12</series_episodes><my_status>Watching</my_status><my_watched_episodes>3</my_watched_episodes></anime><anime><series_animedb_id>bad</series_animedb_id></anime></myanimelist>''',
      );
      expect(result.entries.single.anime.id, 12);
      expect(result.entries.single.anime.title, 'Season & Two');
      expect(result.entries.single.watched, 3);
      expect(result.skipped, 1);
      expect(
        () => parseWatchlist(
          '<!DOCTYPE a [<!ENTITY x SYSTEM "file:///etc/passwd">]><myanimelist/>',
        ),
        throwsFormatException,
      );
      expect(
        parseWatchlist(exportWatchlist(result.entries)).entries.single.toJson(),
        result.entries.single.toJson(),
      );
    },
  );
  test(
    'import keeps existing progress and guest legacy state migrates',
    () async {
      const original = WatchEntry(
        anime: Anime(id: 12, title: 'Season 2'),
        watched: 7,
      );
      SharedPreferences.setMockInitialValues({
        'watchlist_guest': jsonEncode([original.toJson()]),
      });
      final store = AppStore(await SharedPreferences.getInstance());
      await store.initialize();
      expect(
        await store.importEntries([
          original.progress(-4),
          const WatchEntry(anime: Anime(id: 13, title: 'Season 3')),
        ]),
        1,
      );
      expect(store.entries.firstWhere((e) => e.anime.id == 12).watched, 7);
      store.dispose();
    },
  );
  test(
    'offline saves/removals survive restart and replay without losing a newer edit',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      const user = '11111111-1111-4111-8111-111111111111';
      var offline = true;
      final remote = <int, Map<String, dynamic>>{};
      Completer<void>? hold;
      final client = SupabaseClient(
        'https://example.supabase.co',
        'test-key',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient((request) async {
          if (request.url.path.contains('/functions/')) {
            return http.Response(
              '{"reviewer":false}',
              200,
              headers: {'content-type': 'application/json'},
              request: request,
            );
          }
          if (!request.url.path.contains('watchlist')) {
            return http.Response(
              '{}',
              200,
              headers: {'content-type': 'application/json'},
              request: request,
            );
          }
          if (offline) throw http.ClientException('offline');
          if (request.url.path.endsWith('/rpc/sync_watchlist')) {
            final data = jsonDecode(request.body) as Map;
            if (hold != null) await hold.future;
            final id = data['p_mal_id'] as int;
            final value = data['p_entry'] as Map?;
            final revision = '${DateTime.now().microsecondsSinceEpoch}';
            if (value == null) {
              remote.remove(id);
            } else {
              remote[id] = {
                'mal_id': id,
                'anime_snapshot': value['anime'],
                'status': value['status'],
                'watched_episodes': value['watched'],
                'revision': revision,
              };
            }
            return http.Response(
              jsonEncode({
                'applied': true,
                'revision': value == null ? null : revision,
                'entry': value,
              }),
              200,
              headers: {'content-type': 'application/json'},
              request: request,
            );
          }
          return http.Response(
            jsonEncode(remote.values.toList()),
            200,
            headers: {'content-type': 'application/json'},
            request: request,
          );
        }),
      );
      String enc(Object v) =>
          base64Url.encode(utf8.encode(jsonEncode(v))).replaceAll('=', '');
      await client.auth.setInitialSession(
        jsonEncode({
          'access_token':
              '${enc({'alg': 'HS256'})}.${enc({'sub': user, 'exp': DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600})}.signature',
          'refresh_token': 'test-refresh',
          'token_type': 'bearer',
          'expires_in': 3600,
          'user': {
            'id': user,
            'aud': 'authenticated',
            'email': 'test@example.com',
            'created_at': '2026-01-01T00:00:00Z',
          },
        }),
      );
      var store = AppStore(prefs, backend: client);
      await store.initialize();
      await store.save(
        const WatchEntry(anime: Anime(id: 1, title: 'Season 1'), watched: 3),
      );
      while (store.syncing) {
        await Future<void>.delayed(Duration.zero);
      }
      expect(store.pendingChanges, 1);
      expect(store.entries.single.watched, 3);
      store.dispose();
      store = AppStore(prefs, backend: client);
      await store.initialize();
      expect(store.entries.single.watched, 3);
      expect(store.pendingChanges, 1);
      offline = false;
      hold = Completer<void>();
      final flushing = store.flushPending();
      final refreshing = store.refreshWatchlist();
      await Future<void>.delayed(Duration.zero);
      await store.save(store.entries.single.progress(1));
      hold.complete();
      hold = null;
      await flushing;
      await refreshing;
      expect(store.entries.single.watched, 4);
      expect(store.pendingChanges, 0, reason: store.watchError);
      expect(remote[1]!['watched_episodes'], 4);
      expect(store.pendingChanges, 0);
      offline = true;
      await store.remove(1);
      while (store.syncing) {
        await Future<void>.delayed(Duration.zero);
      }
      store.dispose();
      store = AppStore(prefs, backend: client);
      await store.initialize();
      expect(store.entries, isEmpty);
      expect(store.pendingChanges, 1);
      offline = false;
      await store.refreshWatchlist();
      expect(remote, isEmpty);
      expect(store.entries, isEmpty);
      expect(store.pendingChanges, 0);
      await client.auth.signOut(scope: SignOutScope.local);
      await Future<void>.delayed(Duration.zero);
      expect(store.scope, 'guest');
      expect(store.entries, isEmpty);
      store.dispose();
      await client.dispose();
    },
  );
  test(
    'rapid progress taps are serialized against the latest local value',
    () async {
      SharedPreferences.setMockInitialValues({});
      final store = AppStore(await SharedPreferences.getInstance());
      await store.initialize();
      const entry = WatchEntry(anime: Anime(id: 1, title: 'A', episodes: 12));
      await store.save(entry);
      await Future.wait([
        store.changeProgress(entry, 1),
        store.changeProgress(entry, 1),
        store.changeProgress(entry, 1),
      ]);
      expect(store.entries.single.watched, 3);
      store.dispose();
    },
  );
}
