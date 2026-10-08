import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:aniapp/data/catalog.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test(
    'slow gateway falls back, caches results and skips the failed gateway briefly',
    () async {
      var gatewayCalls = 0, directCalls = 0;
      final gatewayResponse = Completer<http.Response>();
      final backend = SupabaseClient(
        'https://example.supabase.co',
        'test-key',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient((_) {
          gatewayCalls++;
          return gatewayResponse.future;
        }),
      );
      final catalog = Catalog(
        backend: backend,
        backendTimeout: const Duration(milliseconds: 20),
        requestTimeout: const Duration(seconds: 2),
        client: MockClient((_) async {
          directCalls++;
          return http.Response(
            '{"data":[{"mal_id":1,"title":"Fallback"}]}',
            200,
          );
        }),
      );
      final results = await Future.wait([
        catalog.search('test', 1),
        catalog.search('test', 1),
      ]);
      expect(
        results.every((page) => page.items.single.title == 'Fallback'),
        isTrue,
      );
      await catalog.search('test', 1);
      expect(directCalls, 1);
      await catalog.search('another', 1);
      expect(gatewayCalls, 1);
      expect(directCalls, 2);
      gatewayResponse.complete(http.Response('{}', 503));
      catalog.dispose();
      await backend.dispose();
    },
  );

  test(
    'unresponsive sources stop at the deadline and can be retried',
    () async {
      var calls = 0;
      final slow = Completer<http.Response>();
      final catalog = Catalog(
        requestTimeout: const Duration(milliseconds: 100),
        client: MockClient((_) {
          calls++;
          return slow.future;
        }),
      );
      await expectLater(
        catalog.search('test', 1),
        throwsA(isA<CatalogException>()),
      );
      await expectLater(
        catalog.search('test', 1),
        throwsA(isA<CatalogException>()),
      );
      // An expired request queued for rate limiting must not reach the network.
      slow.complete(http.Response('{"data":[]}', 200));
      await Future<void>.delayed(const Duration(seconds: 1));
      expect(calls, 1);
      catalog.dispose();
    },
  );
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
