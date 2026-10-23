import 'dart:convert';

import 'package:aniapp/data/app_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  var offline = false;
  final backend = SupabaseClient(
    'https://example.supabase.co',
    'test',
    authOptions: const AuthClientOptions(autoRefreshToken: false),
    httpClient: MockClient((request) async {
      if (offline) throw http.ClientException('offline');
      final body = request.url.path.endsWith('/rpc/companion_news')
          ? [
              {
                'id': 1,
                'headline': 'Neue Staffel',
                'source_url': 'https://example.com/news/1',
              },
            ]
          : <Object>[];
      return http.Response(
        jsonEncode(body),
        200,
        headers: {'content-type': 'application/json'},
        request: request,
      );
    }),
  );

  Future<AppStore> store([Map<String, Object> values = const {}]) async {
    SharedPreferences.setMockInitialValues(values);
    return AppStore(
      await SharedPreferences.getInstance(),
      backend: backend,
      deviceLanguage: () => 'de',
    );
  }

  test('news falls back to the last successful result with its age', () async {
    offline = false;
    final s = await store();
    expect((await s.news()).single['headline'], 'Neue Staffel');
    expect(s.newsCachedAt, isNull);
    offline = true;
    final cached = await s.news();
    expect(cached.single['headline'], 'Neue Staffel');
    expect(s.newsCachedAt, isNotNull);
    offline = false;
    await s.news();
    expect(s.newsCachedAt, isNull);
    s.dispose();
  });

  test('news without a cache for the current filters still fails', () async {
    offline = false;
    final s = await store();
    await s.news();
    await s.setRegion('US');
    offline = true;
    await expectLater(s.news(), throwsA(anything));
    s.dispose();
  });

  test('a cached calendar drops events that have already passed', () async {
    final now = DateTime.now();
    Map<String, Object?> event(String title, Duration offset) => {
      'title': title,
      'kind': 'dub',
      'region': 'DE',
      'audio_language': 'de',
      'starts_at': now.add(offset).toUtc().toIso8601String(),
    };
    offline = true;
    final s = await store({
      'calendar_cache': jsonEncode({
        'filters': jsonEncode([
          'DE',
          ['de'],
          'any',
        ]),
        'saved_at': now.subtract(const Duration(days: 2)).toIso8601String(),
        'rows': [
          event('Vorbei', const Duration(days: -1)),
          event('Bald', const Duration(days: 3)),
        ],
      }),
    });
    final events = await s.calendarReleases();
    expect(events.map((e) => e.title), ['Bald']);
    expect(s.calendarCachedAt, isNotNull);
    s.dispose();
  });

  tearDownAll(() => backend.dispose());
}
