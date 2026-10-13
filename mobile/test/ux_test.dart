import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aniapp/data/app_store.dart';
import 'package:aniapp/data/catalog.dart';
import 'package:aniapp/models/anime.dart';
import 'package:aniapp/models/content.dart';
import 'package:aniapp/models/enrichment.dart';
import 'package:aniapp/main.dart';
import 'package:aniapp/ui/detail_screen.dart';
import 'package:aniapp/ui/dub_panel.dart';
import 'package:aniapp/ui/app_theme.dart';
import 'package:aniapp/l10n/strings.dart';

class UxCatalog extends Catalog {
  @override
  Future<AnimePage> season(int year, String season, int page) async =>
      const AnimePage([], false);
  @override
  Future<Anime> detail(int id) async => demo;
}

const demo = Anime(
  id: 1,
  title: 'Frieren: Nach dem Ende der Reise',
  episodes: 28,
  score: 9.2,
  synopsis:
      'Eine Reise über Freundschaft, Erinnerungen und die Zeit, die wir miteinander verbringen.',
  genres: ['Adventure', 'Fantasy'],
);

class UxStore extends AppStore {
  UxStore(super.prefs) : super(catalog: UxCatalog());
  @override
  Future<List<ReleaseEvent>> calendarReleases() async => [];
  @override
  Future<AnimeEnrichment> enrichment(int id, {String? audioLanguage}) async =>
      AnimeEnrichment.empty;
}

Future<void> capture(WidgetTester tester, GlobalKey key, String name) async {
  final target = Platform.environment['ANIAPP_PREVIEW_DIR'];
  if (target == null) return;
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await Directory(target).create(recursive: true);
    await File('$target/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final fonts = Platform.environment['ANIAPP_FONT_DIR'];
    if (fonts == null) return;
    for (final entry in {
      'Roboto': 'Roboto-Regular.ttf',
      'MaterialIcons': 'MaterialIcons-Regular.otf',
    }.entries) {
      final loader = FontLoader(entry.key);
      loader.addFont(
        File(
          '$fonts/${entry.value}',
        ).readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
      );
      await loader.load();
    }
  });
  for (final config in [
    (320.0, 740.0, 1.8),
    (390.0, 844.0, 1.0),
    (1024.0, 900.0, 1.0),
  ]) {
    testWidgets(
      'daily flow and list editing at ${config.$1}px with ${config.$3}x text',
      (tester) async {
        tester.view.physicalSize = Size(config.$1, config.$2);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.platformBrightnessTestValue =
            config.$1 == 1024 ? Brightness.dark : Brightness.light;
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
        tester.platformDispatcher.textScaleFactorTestValue = config.$3;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        SharedPreferences.setMockInitialValues({'app_language': 'de'});
        final store = UxStore(await SharedPreferences.getInstance());
        await store.initialize();
        await store.save(
          const WatchEntry(
            anime: demo,
            status: WatchStatus.watching,
            watched: 7,
          ),
        );
        final key = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(
            key: key,
            child: AniApp(store: store),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        if (config.$1 == 390) await capture(tester, key, 'today');
        await tester.tap(find.text('Meine Liste').last);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        if (config.$1 == 390) await capture(tester, key, 'watchlist');
        if (config.$1 == 1024) await capture(tester, key, 'tablet-dark');
        await tester.enterText(find.byType(TextField), 'frieren');
        await tester.pumpAndSettle();
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -200));
        await tester.pumpAndSettle();
        expect(find.text(demo.title), findsOneWidget);
        await Scrollable.ensureVisible(
          tester.element(find.byTooltip('Eine Folge gesehen')),
          alignment: 0.5,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Eine Folge gesehen'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'increment snackbar');
        expect(store.entries.single.watched, 8);
        await tester.tap(find.text('Rückgängig'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'undo');
        expect(store.entries.single.watched, 7);
        await Scrollable.ensureVisible(
          tester.element(find.text('7 / 28')),
          alignment: 0.5,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('7 / 28'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'progress dialog');
        await tester.enterText(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(TextField),
          ),
          '12',
        );
        await tester.tap(find.text('Speichern'));
        await tester.pumpAndSettle();
        expect(store.entries.single.watched, 12);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        store.dispose();
      },
    );
  }
  testWidgets(
    'detail sections preserve provider information and support large text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({'app_language': 'de'});
      final store = UxStore(await SharedPreferences.getInstance());
      await store.initialize();
      final key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: MaterialApp(
            locale: const Locale('de'),
            theme: aniAppTheme(Brightness.light),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.8)),
              child: child!,
            ),
            home: DetailScreen(anime: demo, store: store),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(find.text('Folgen & Dubs'), 250);
      await Scrollable.ensureVisible(
        tester.element(find.text('Folgen & Dubs')),
        alignment: 0.4,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Folgen & Dubs'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.byType(DubPanel), 150);
      expect(find.byType(DubPanel), findsWidgets);
      expect(tester.takeException(), isNull);
      await Scrollable.ensureVisible(
        tester.element(find.text('Anbieter')),
        alignment: 0.4,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Anbieter'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await capture(tester, key, 'detail-large-text');
      await tester.pumpWidget(const SizedBox());
      store.dispose();
    },
  );
}
