import 'dart:convert';
import 'package:aniapp/data/app_store.dart';
import 'package:aniapp/data/catalog.dart';
import 'package:aniapp/l10n/strings.dart';
import 'package:aniapp/main.dart';
import 'package:aniapp/models/anime.dart';
import 'package:aniapp/ui/content_screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EmptyCatalog extends Catalog {
  @override
  Future<AnimePage> season(int year, String season, int page) async =>
      const AnimePage([], false);
}

class LanguageNewsStore extends AppStore {
  LanguageNewsStore(super.preferences);
  final requests = <List<String>>[];
  @override
  Future<List<Map<String, dynamic>>> news() async {
    final selected = List<String>.from(newsLanguages);
    requests.add(selected);
    return [
      for (final language in selected)
        {
          'headline': language == 'de' ? 'Deutsche Meldung' : 'English story',
          'language': language,
          'source_name': 'Test source',
          'source_url': 'https://example.com',
          'published_at': '2026-10-10T08:00:00Z',
          'category': 'dub',
        },
    ];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('device locale resolves DE and EN with English fallback', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final store = AppStore(
      await SharedPreferences.getInstance(),
      catalog: EmptyCatalog(),
      deviceLanguage: () =>
          tester.platformDispatcher.locales.first.languageCode,
    );
    tester.platformDispatcher.localesTestValue = const [Locale('fr', 'FR')];
    addTearDown(tester.binding.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(AniApp(store: store));
    await tester.pumpAndSettle();
    expect(find.text('Discover'), findsOneWidget);
    expect(store.newsLanguages, ['en']);
    tester.platformDispatcher.localesTestValue = const [Locale('de', 'AT')];
    await tester.pumpAndSettle();
    expect(find.text('Entdecken'), findsOneWidget);
    expect(store.newsLanguages, ['de']);
    await store.setAppLanguage('en');
    await tester.pumpAndSettle();
    expect(find.text('Discover'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    store.dispose();
  });

  test(
    'language preferences persist independently and validate old choices',
    () async {
      SharedPreferences.setMockInitialValues({
        'app_language': 'de',
        'language': 'fr',
        'region': 'AT',
      });
      final prefs = await SharedPreferences.getInstance();
      final store = AppStore(prefs);
      expect(store.dubLanguages, ['de']);
      await store.setDubLanguages(['en']);
      await store.setNewsLanguage('both');
      await store.setRegion('GB');
      expect(store.appLanguage, 'de');
      expect(store.newsLanguages, ['de', 'en']);
      expect(store.dubLanguages, ['en']);
      await store.setDubLanguages([]);
      await store.setAppLanguage('fr');
      expect(store.dubLanguages, ['en']);
      expect(store.appLanguage, 'de');
      final restored = AppStore(prefs);
      expect(restored.region, 'GB');
      expect(restored.dubLanguages, ['en']);
      expect(restored.newsLanguage, 'both');
      store.dispose();
      restored.dispose();
    },
  );

  test(
    'news language is filtered before limiting, independent of audio/country',
    () async {
      SharedPreferences.setMockInitialValues({
        'app_language': 'de',
        'news_language': 'en',
        'dub_languages': ['de'],
        'region': 'DE',
      });
      final requests = <Uri>[];
      final backend = SupabaseClient(
        'https://example.supabase.co',
        'test-key',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient((request) async {
          requests.add(request.url);
          return http.Response(
            '[]',
            200,
            headers: {'content-type': 'application/json'},
            request: request,
          );
        }),
      );
      final store = AppStore(
        await SharedPreferences.getInstance(),
        backend: backend,
      );
      await store.news();
      expect(requests.last.queryParameters['language'], 'in.("en")');
      expect(requests.last.queryParameters['limit'], '40');
      await store.setNewsLanguage('both');
      await store.news();
      expect(requests.last.queryParameters['language'], 'in.("de","en")');
      expect(store.dubLanguages, ['de']);
      expect(store.region, 'DE');
      store.dispose();
      await backend.dispose();
    },
  );

  test(
    'calendar keeps original/streaming and both chosen dubs but no other region',
    () async {
      SharedPreferences.setMockInitialValues({
        'app_language': 'de',
        'dub_languages': ['de', 'en'],
        'region': 'DE',
      });
      final requests = <Uri>[];
      final backend = SupabaseClient(
        'https://example.supabase.co',
        'test-key',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient((request) async {
          requests.add(request.url);
          return http.Response(
            jsonEncode([
              for (final tuple in [
                ('japan', 'JP', 'ja'),
                ('streaming', 'DE', 'ja'),
                ('dub', 'DE', 'de'),
                ('dub', 'DE', 'en'),
                ('dub', 'US', 'en'),
                ('dub', 'DE', 'fr'),
              ])
                {
                  'kind': tuple.$1,
                  'region': tuple.$2,
                  'audio_language': tuple.$3,
                  'title': '${tuple.$1}-${tuple.$2}-${tuple.$3}',
                  'status': 'announced',
                },
            ]),
            200,
            headers: {'content-type': 'application/json'},
            request: request,
          );
        }),
      );
      final store = AppStore(
        await SharedPreferences.getInstance(),
        backend: backend,
      );
      final all = await store.releases();
      expect(
        all.map((e) => e.title),
        containsAll([
          'japan-JP-ja',
          'streaming-DE-ja',
          'dub-DE-de',
          'dub-DE-en',
        ]),
      );
      expect(all.length, 4);
      await store.setCalendarMode('dub');
      final dubs = await store.releases();
      expect(dubs.map((e) => e.language).toSet(), {'de', 'en'});
      expect(dubs.every((e) => e.kind == 'dub' && e.region == 'DE'), isTrue);
      expect(requests.last.queryParameters['audio_language'], 'in.("de","en")');
      await store.setDubLanguages(['en']);
      final english = await store.releases();
      expect(english.single.title, 'dub-DE-en');
      store.dispose();
      await backend.dispose();
    },
  );

  testWidgets(
    'visible news refresh when language changes, not when audio changes',
    (tester) async {
      SharedPreferences.setMockInitialValues({'app_language': 'de'});
      final store = LanguageNewsStore(await SharedPreferences.getInstance());
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: NewsScreen(store: store)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Deutsche Meldung'), findsOneWidget);
      await store.setNewsLanguage('en');
      await tester.pumpAndSettle();
      expect(find.text('English story'), findsOneWidget);
      expect(find.text('Deutsche Meldung'), findsNothing);
      await store.setDubLanguages(['en']);
      await tester.pumpAndSettle();
      expect(store.requests.length, 2);
      await store.setNewsLanguage('both');
      await tester.pumpAndSettle();
      expect(store.requests.last, ['de', 'en']);
      await tester.pumpWidget(const SizedBox());
      store.dispose();
    },
  );

  testWidgets(
    'English profile fits narrow large-text screen; controls remain independent',
    (tester) async {
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      SharedPreferences.setMockInitialValues({
        'app_language': 'en',
        'dub_languages': ['de'],
      });
      final store = AppStore(
        await SharedPreferences.getInstance(),
        catalog: EmptyCatalog(),
      );
      await tester.pumpWidget(AniApp(store: store));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('dub-en')),
        300,
      );
      await tester.tap(find.byKey(const ValueKey('dub-en')));
      await tester.pumpAndSettle();
      expect(store.dubLanguages, ['de', 'en']);
      expect(store.appLanguage, 'en');
      expect(store.newsLanguage, 'app');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      store.dispose();
    },
  );
}
