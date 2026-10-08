import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aniapp/data/app_store.dart';
import 'package:aniapp/main.dart';
import 'package:aniapp/models/anime.dart';
import 'package:aniapp/data/catalog.dart';

class FakeCatalog extends Catalog {
  @override
  Future<AnimePage> season(int year, String season, int page) async =>
      const AnimePage([Anime(id: 1, title: 'Testserie', episodes: 12)], false);
}

void main() {
  testWidgets(
    'five navigation destinations and guest mode render without backend',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final store = AppStore(
        await SharedPreferences.getInstance(),
        catalog: FakeCatalog(),
      );
      await store.initialize();
      await tester.pumpWidget(AniApp(store: store));
      await tester.pumpAndSettle();
      expect(find.byType(NavigationDestination), findsNWidgets(5));
      await tester.tap(find.byTooltip('Zur Watchlist hinzufügen'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Meine Liste'));
      await tester.pumpAndSettle();
      expect(find.text('Testserie'), findsWidgets);
      await tester.tap(find.byTooltip('Eine Folge gesehen'));
      await tester.pumpAndSettle();
      expect(store.entries.single.watched, 1);
      expect(store.entries.single.status, WatchStatus.watching);
      await tester.tap(find.text('Kalender'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('News'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Profil'));
      await tester.pumpAndSettle();
      expect(find.text('Gastmodus'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      store.dispose();
    },
  );
}
