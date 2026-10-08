import 'package:flutter_test/flutter_test.dart';
import 'package:aniapp/models/anime.dart';
import 'package:aniapp/models/content.dart';

void main() {
  test('last episode completes series and decrement resumes watching', () {
    const anime = Anime(id: 1, title: 'Test', episodes: 12);
    const entry = WatchEntry(
      anime: anime,
      status: WatchStatus.watching,
      watched: 11,
    );
    expect(entry.progress(1).status, WatchStatus.completed);
    expect(entry.progress(10).watched, 12);
    expect(entry.progress(1).progress(-1).status, WatchStatus.watching);
  });
  test('unknown episode total never implies completion', () {
    const entry = WatchEntry(anime: Anime(id: 1, title: 'Test'));
    expect(entry.progress(1).status, WatchStatus.watching);
    expect(entry.progress(-1).watched, 0);
  });
  test('old cache retains sensible defaults', () {
    final entry = WatchEntry.fromJson({
      'anime': {'id': 1, 'title': 'Old entry'},
    });
    expect(entry.watched, 0);
    expect(entry.status, WatchStatus.planned);
  });
  test('unknown language data is not marked unavailable', () {
    final a = Availability({
      'provider': 'Test',
      'region': 'DE',
      'status': 'announced',
    });
    expect(a.audio, null);
    expect(a.subtitles, null);
    expect(a.status, 'announced');
  });
  test('season follows current month', () {
    expect(currentSeason(DateTime(2026, 10, 8)), 'fall');
    expect(currentSeason(DateTime(2027, 1, 1)), 'winter');
  });
}
