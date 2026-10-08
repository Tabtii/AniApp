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

void main() {
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
