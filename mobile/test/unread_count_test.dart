import 'dart:convert';

import 'package:aniapp/data/app_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('the unread badge shows the server total, not one page', () async {
    String? prefer;
    final backend = SupabaseClient(
      'https://example.supabase.co',
      'test',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((request) async {
        final inbox = request.url.path.endsWith('/release_inbox');
        if (inbox) prefer = request.headers['Prefer'];
        return http.Response(
          inbox ? '[{"id":"a"}]' : '[]',
          200,
          headers: {
            'content-type': 'application/json',
            if (inbox) 'content-range': '0-0/250',
          },
          request: request,
        );
      }),
    );
    String enc(Object data) =>
        base64Url.encode(utf8.encode(jsonEncode(data))).replaceAll('=', '');
    await backend.auth.setInitialSession(
      jsonEncode({
        'access_token':
            '${enc({'alg': 'HS256'})}.${enc({'sub': '11111111-1111-4111-8111-111111111111', 'exp': DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600})}.sig',
        'refresh_token': 'test',
        'token_type': 'bearer',
        'expires_in': 3600,
        'user': {
          'id': '11111111-1111-4111-8111-111111111111',
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
    await store.refreshUnreadCount();
    expect(store.unreadCount, 250);
    expect(prefer, contains('count=exact'));
    store.dispose();
    await backend.dispose();
  });
}
