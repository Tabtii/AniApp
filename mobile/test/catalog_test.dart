import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:aniapp/data/catalog.dart';

void main() {
  test(
    'search encodes user query, safe filter and genre; repeated requests are cached',
    () async {
      var calls = 0;
      final catalog = Catalog(
        client: MockClient((request) async {
          calls++;
          expect(request.url.queryParameters['q'], 'A & B');
          expect(request.url.queryParameters['sfw'], 'true');
          expect(request.url.queryParameters['genres'], '7');
          return http.Response(
            '{"data":[],"pagination":{"has_next_page":false}}',
            200,
          );
        }),
      );
      await catalog.search('A & B', 1, genre: '7');
      await catalog.search('A & B', 1, genre: '7');
      expect(calls, 1);
      catalog.dispose();
    },
  );
  test('rate limit becomes useful error, not empty results', () async {
    final catalog = Catalog(
      client: MockClient((_) async => http.Response('{}', 429)),
    );
    await expectLater(
      catalog.search('Test', 1),
      throwsA(isA<CatalogException>()),
    );
    catalog.dispose();
  });
}
