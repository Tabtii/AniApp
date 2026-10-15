import 'package:aniapp/data/app_store.dart';
import 'package:aniapp/data/catalog.dart';
import 'package:aniapp/l10n/strings.dart';
import 'package:aniapp/models/anime.dart';
import 'package:aniapp/ui/catalog_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchCatalog extends Catalog {
  final queries = <String>[];
  @override
  Future<AnimePage> season(int year, String season, int page) async =>
      const AnimePage([Anime(id: 1, title: 'Season pick')], false);
  @override
  Future<AnimePage> search(String query, int page, {String? genre}) {
    queries.add(query);
    return Future.value(AnimePage([Anime(id: 2, title: 'Hit $query')], false));
  }
}

void main() {
  testWidgets('an empty search returns to the season view', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final catalog = SearchCatalog();
    final store = AppStore(
      await SharedPreferences.getInstance(),
      catalog: catalog,
    );
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: CatalogScreen(store: store)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Season pick'), findsWidgets);

    final field = find.byType(TextField);
    await tester.enterText(field, 'frieren');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(find.text('Hit frieren'), findsWidgets);

    await tester.enterText(field, '  ');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(catalog.queries, ['frieren']);
    expect(find.text('Season pick'), findsWidgets);
    await tester.pumpWidget(const SizedBox());
    store.dispose();
  });
}
