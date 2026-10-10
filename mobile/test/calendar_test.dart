import 'package:aniapp/l10n/strings.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aniapp/data/app_store.dart';
import 'package:aniapp/models/content.dart';
import 'package:aniapp/ui/content_screens.dart';

class CalendarStore extends AppStore {
  CalendarStore(super.preferences);
  @override
  Future<List<ReleaseEvent>> releases({int? animeId}) async => [
    for (var i = 1; i <= 10; i++)
      ReleaseEvent({
        'mal_id': i,
        'title': i == 1 ? 'Weiterlaufende Serie' : 'Anime $i',
        'provider': i == 1 ? 'ADN' : 'Netflix',
        'region': 'DE',
        'kind': 'streaming',
        'starts_on': '2026-10-${i + 10}',
        'status': 'confirmed',
      }),
    ReleaseEvent({
      'mal_id': 99,
      'title': 'Ältere deutsche Synchro',
      'provider': 'Crunchyroll',
      'region': 'DE',
      'kind': 'dub',
      'audio_language': 'de',
      'starts_on': '2026-10-22',
      'status': 'delayed',
      'release_note': 'Neue Folge am 22. Oktober.',
    }),
  ];
}

void main() {
  test(
    'loads more than 200 releases and keeps independent date/region filters',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final requests = <Uri>[];
      final backend = SupabaseClient(
        'https://example.supabase.co',
        'test-key',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient((request) async {
          requests.add(request.url);
          expect(request.url.queryParametersAll['or']!.length, 3);
          final offset = int.parse(
            request.url.queryParameters['offset'] ?? '0',
          );
          return http.Response(
            jsonEncode([
              for (var i = offset; i < (offset == 0 ? 200 : 205); i++)
                {
                  'id': '$i',
                  'mal_id': i + 1,
                  'title': 'Anime $i',
                  'region': 'DE',
                  'provider': 'ADN',
                  'kind': 'streaming',
                  'status': 'announced',
                },
            ]),
            200,
            headers: {'content-type': 'application/json'},
            request: request,
          );
        }),
      );
      final store = AppStore(prefs, backend: backend);
      final rows = await store.releases();
      expect(rows.length, 205);
      expect(requests.length, 2);
      expect(requests.last.queryParameters['offset'], '200');
      store.dispose();
      await backend.dispose();
    },
  );
  testWidgets(
    'provider/day filters retain later dates and reset stale selections',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final store = CalendarStore(await SharedPreferences.getInstance());
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: CalendarScreen(store: store)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Alle Seasons'), findsOneWidget);
      expect(
        find.text('22.10.'),
        findsOneWidget,
      ); // Previously hidden after eight dates.
      await tester.tap(find.widgetWithText(ChoiceChip, 'ADN'));
      await tester.pumpAndSettle();
      expect(find.text('Weiterlaufende Serie'), findsOneWidget);
      expect(find.text('Anime 2'), findsNothing);
      await tester.tap(find.widgetWithText(ChoiceChip, '11.10.'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.widgetWithText(ChoiceChip, 'Crunchyroll'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'Crunchyroll'));
      await tester.pumpAndSettle();
      expect(find.text('Ältere deutsche Synchro'), findsOneWidget);
      expect(find.text('Neue Folge am 22. Oktober.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      store.dispose();
    },
  );
}
