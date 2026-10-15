import 'dart:convert';

import 'package:aniapp/data/app_store.dart';
import 'package:aniapp/l10n/strings.dart';
import 'package:aniapp/ui/companion_screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const userId = '11111111-1111-4111-8111-111111111111';

// A signed-in store whose inbox requests are answered by [inbox].
Future<(AppStore, SupabaseClient)> signedInStore(
  http.Response Function(http.Request request) inbox,
) async {
  final backend = SupabaseClient(
    'https://example.supabase.co',
    'test',
    authOptions: const AuthClientOptions(autoRefreshToken: false),
    httpClient: MockClient(
      (request) async => request.url.path.endsWith('/release_inbox')
          ? inbox(request)
          : http.Response(
              '[]',
              200,
              headers: {'content-type': 'application/json'},
              request: request,
            ),
    ),
  );
  String enc(Object data) =>
      base64Url.encode(utf8.encode(jsonEncode(data))).replaceAll('=', '');
  await backend.auth.setInitialSession(
    jsonEncode({
      'access_token':
          '${enc({'alg': 'HS256'})}.${enc({'sub': userId, 'exp': DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600})}.sig',
      'refresh_token': 'test',
      'token_type': 'bearer',
      'expires_in': 3600,
      'user': {
        'id': userId,
        'aud': 'authenticated',
        'email': 'test@example.com',
        'created_at': '2026-01-01T00:00:00Z',
      },
    }),
  );
  SharedPreferences.setMockInitialValues({});
  final store = AppStore(
    await SharedPreferences.getInstance(),
    backend: backend,
  );
  await store.initialize();
  return (store, backend);
}

Map<String, Object?> message(int i) => {
  'id': 'm$i',
  'kind': 'announcement',
  'created_at': '2026-10-15T08:00:00Z',
  'read_at': null,
  'superseded': true,
  'event': {'title': 'Anime $i'},
};

void main() {
  test('the unread badge shows the server total, not one page', () async {
    String? prefer;
    final (store, backend) = await signedInStore((request) {
      prefer = request.headers['Prefer'];
      return http.Response(
        '[{"id":"a"}]',
        200,
        headers: {
          'content-type': 'application/json',
          'content-range': '0-0/250',
        },
        request: request,
      );
    });
    await store.refreshUnreadCount();
    expect(store.unreadCount, 250);
    expect(prefer, contains('count=exact'));
    store.dispose();
    await backend.dispose();
  });

  testWidgets('the inbox loads older messages page by page', (tester) async {
    final limits = <int>[];
    final created = await tester.runAsync(
      () => signedInStore((request) {
        final limit = int.parse(request.url.queryParameters['limit'] ?? '0');
        if (request.headers['Prefer']?.contains('count') != true) {
          limits.add(limit);
        }
        const total = 70;
        return http.Response(
          jsonEncode([
            for (var i = 0; i < (limit < total ? limit : total); i++)
              message(i),
          ]),
          200,
          headers: {'content-type': 'application/json'},
          request: request,
        );
      }),
    );
    final (store, backend) = created!;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: InboxScreen(store: store),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Ältere laden'), 500);
    await tester.tap(find.text('Ältere laden'));
    await tester.pumpAndSettle();
    expect(limits, [60, 120]);
    expect(find.text('Ältere laden'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    store.dispose();
    await tester.runAsync(backend.dispose);
  });
}
