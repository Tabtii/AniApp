import 'package:aniapp/data/app_store.dart';
import 'package:aniapp/data/catalog.dart';
import 'package:aniapp/main.dart';
import 'package:aniapp/models/anime.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EmptyCatalog extends Catalog {
  @override
  Future<AnimePage> season(int year, String season, int page) async =>
      const AnimePage([], false);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('the header chip switches app language and region', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'app_language': 'en'});
    final store = AppStore(
      await SharedPreferences.getInstance(),
      catalog: EmptyCatalog(),
    );
    await tester.pumpWidget(AniApp(store: store));
    await tester.pumpAndSettle();
    expect(find.text('Discover'), findsOneWidget);
    expect(find.text('DE'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('region-language-chip')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('sheet-app-language')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Deutsch').last);
    await tester.pumpAndSettle();
    expect(store.appLanguage, 'de');

    await tester.tap(find.byKey(const ValueKey('sheet-region')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Österreich').last);
    await tester.pumpAndSettle();
    expect(store.region, 'AT');

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.text('Entdecken'), findsOneWidget);
    expect(find.text('AT'), findsOneWidget);
  });
}
