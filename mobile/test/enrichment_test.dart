import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aniapp/data/app_store.dart';
import 'package:aniapp/models/content.dart';
import 'package:aniapp/models/enrichment.dart';
import 'package:aniapp/ui/dub_panel.dart';
import 'package:aniapp/ui/sources_screen.dart';
import 'package:aniapp/ui/kitsu_panel.dart';

void main() {
  test(
    'reviewed pause suppresses calculated slots but preserves local releases',
    () {
      final result = mergeJapanSchedule(
        [
          ReleaseEvent({
            'mal_id': 21,
            'kind': 'japan',
            'provider': 'ADN News',
            'status': 'delayed',
          }),
          ReleaseEvent({
            'mal_id': 21,
            'kind': 'japan',
            'provider': 'Tenrai / MyAnimeList',
            'starts_on': '2026-10-11',
          }),
          ReleaseEvent({
            'mal_id': 21,
            'kind': 'dub',
            'provider': 'Provider',
            'starts_on': '2026-10-12',
          }),
        ],
        [
          ReleaseEvent({
            'mal_id': 21,
            'kind': 'japan',
            'provider': 'AniList',
            'starts_on': '2026-10-11',
          }),
        ],
      );
      expect(result.length, 2);
      expect(result.where((e) => e.kind == 'japan').single.date, isNull);
      expect(result.where((e) => e.kind == 'dub').length, 1);
    },
  );
  testWidgets(
    'Kitsu metadata and source fit large text without implying German releases',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 740));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(1.3)),
            child: child!,
          ),
          home: const Scaffold(
            body: SingleChildScrollView(
              child: KitsuPanel(
                data: {
                  'status': 'ok',
                  'airing_status': 'finished',
                  'episodes': 28,
                  'episode_minutes': 24,
                  'start_date': '2023-09-29',
                  'end_date': '2024-03-22',
                  'checked_at': '2026-10-08T17:00:00Z',
                  'source': 'https://kitsu.app/anime/46474',
                  'trailer_url': 'https://www.youtube.com/watch?v=qgQunxD0qCk',
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('28 Folgen'), findsOneWidget);
      expect(find.textContaining('Originalausstrahlung:'), findsOneWidget);
      expect(
        find.textContaining('deutsche Veröffentlichungen'),
        findsOneWidget,
      );
      expect(find.text('Quelle: Kitsu'), findsOneWidget);
      expect(find.text('Trailer auf YouTube'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  test(
    'episode schedule replaces only corresponding estimated Japanese slots',
    () {
      ReleaseEvent event(int id, String kind, String provider) => ReleaseEvent({
        'mal_id': id,
        'kind': kind,
        'provider': provider,
        'starts_on': '2026-10-15',
      });
      final result = mergeJapanSchedule(
        [
          event(21, 'japan', 'Tenrai / MyAnimeList'),
          event(21, 'dub', 'Crunchyroll'),
          event(1, 'japan', 'Tenrai / MyAnimeList'),
        ],
        [event(21, 'japan', 'AniList')],
      );
      expect(result.length, 3);
      expect(result.where((e) => e.provider == 'Crunchyroll').length, 1);
      expect(
        result
            .where((e) => e.provider == 'Tenrai / MyAnimeList')
            .single
            .animeId,
        1,
      );
    },
  );
  test(
    'detail request keeps region and language and rejects a wrong identity',
    () async {
      SharedPreferences.setMockInitialValues({
        'region': 'AT',
        'language': 'fr',
      });
      var wrong = false;
      final backend = SupabaseClient(
        'https://example.supabase.co',
        'test-key',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient((r) async {
          final body = jsonDecode(r.body) as Map;
          expect(body['mal_id'], 21);
          expect(body['region'], 'AT');
          expect(body['language'], 'fr');
          return http.Response(
            jsonEncode({
              ...body,
              'mal_id': wrong ? 22 : 21,
              'dub': {'status': 'available'},
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      final store = AppStore(
        await SharedPreferences.getInstance(),
        backend: backend,
      );
      expect((await store.enrichment(21)).dub['status'], 'available');
      wrong = true;
      await expectLater(store.enrichment(21), throwsStateError);
      store.dispose();
      await backend.dispose();
    },
  );
  testWidgets('dub existence is not presented as a provider or release date', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DubPanel(
            language: 'de',
            region: 'DE',
            events: const [],
            availability: const [],
            loading: false,
            onRetry: () {},
            observation: const {'status': 'available'},
          ),
        ),
      ),
    );
    expect(find.text('Synchronfassung vorhanden'), findsOneWidget);
    expect(find.textContaining('Anbieter, Region'), findsOneWidget);
    expect(find.text('Als verfügbar gemeldet'), findsNothing);
    expect(find.text('Angekündigter Start'), findsNothing);
  });
  testWidgets(
    'dub source failure preserves independently known announcements',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DubPanel(
                language: 'de',
                region: 'DE',
                events: [
                  ReleaseEvent({'provider': 'ADN', 'status': 'announced'}),
                ],
                availability: const [],
                loading: false,
                onRetry: () {},
                observation: const {'status': 'unavailable'},
              ),
            ),
          ),
        ),
      );
      expect(find.textContaining('nicht erreichbar'), findsOneWidget);
      expect(find.text('ADN'), findsOneWidget);
      expect(find.text('Starttermin noch offen'), findsOneWidget);
    },
  );
  testWidgets(
    'credits fit narrow screen with large text and contain required attribution',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 740));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(1.3)),
            child: child!,
          ),
          home: const SourcesScreen(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Dub data © MyDubList'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.textContaining('This product uses the TMDB API'),
        300,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
