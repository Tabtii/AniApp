import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aniapp/data/app_store.dart';
import 'package:aniapp/models/anime.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('guest watchlist survives restart and removal persists', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final first = AppStore(prefs);
    await first.initialize();
    await first.save(
      const WatchEntry(anime: Anime(id: 1, title: 'Example'), watched: 3),
    );
    first.dispose();
    final second = AppStore(prefs);
    await second.initialize();
    expect(second.entries.single.watched, 3);
    await second.remove(1);
    second.dispose();
    final third = AppStore(prefs);
    await third.initialize();
    expect(third.entries, isEmpty);
    third.dispose();
  });
}
