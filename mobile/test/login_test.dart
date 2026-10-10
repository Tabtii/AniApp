import 'package:aniapp/l10n/strings.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aniapp/ui/login_dialog.dart';
import 'package:aniapp/data/app_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

final testUser = {
  'id': '00000000-0000-0000-0000-000000000001',
  'aud': 'authenticated',
  'role': 'authenticated',
  'email': 'tester@example.com',
  'app_metadata': <String, dynamic>{},
  'user_metadata': <String, dynamic>{},
  'created_at': '2026-01-01T00:00:00Z',
};
http.Response response(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);
http.Response session() => response({
  'access_token': 'test-access-token',
  'refresh_token': 'test-refresh-token',
  'token_type': 'bearer',
  'expires_in': 3600,
  'user': testUser,
});
SupabaseClient client(Future<http.Response> Function(http.Request) handle) =>
    _AuthBackend(
      GoTrueClient(
        url: 'https://example.supabase.co/auth/v1',
        autoRefreshToken: false,
        httpClient: MockClient(handle),
        asyncStorage: _MemoryStorage(),
      ),
    );

class _AuthBackend extends Fake implements SupabaseClient {
  _AuthBackend(this.auth);
  @override
  final GoTrueClient auth;
  @override
  Future<void> dispose() async {
    auth.dispose();
  }
}

Future<void> openLogin(
  WidgetTester tester,
  SupabaseClient backend, {
  LoginMode mode = LoginMode.signIn,
}) async {
  await tester.binding.setSurfaceSize(const Size(390, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('de'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showDialog<bool>(
              context: context,
              builder: (_) => LoginDialog(backend: backend, initialMode: mode),
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

Future<void> fill(WidgetTester tester, String label, String value) async {
  final f = find.widgetWithText(TextFormField, label);
  await tester.ensureVisible(f);
  await tester.enterText(f, value);
}

Future<void> submit(WidgetTester tester, String label) async {
  final f = find.widgetWithText(FilledButton, label);
  await tester.ensureVisible(f);
  await tester.tap(f);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'registration validates confirmation before a request and allows password visibility',
    (tester) async {
      var calls = 0;
      final backend = client((r) async {
        calls++;
        return response(testUser);
      });
      addTearDown(() => tester.runAsync(backend.dispose));
      await openLogin(tester, backend, mode: LoginMode.register);
      await fill(tester, 'E-Mail', 'tester@example.com');
      await fill(tester, 'Passwort', 'a-good-password');
      await fill(tester, 'Passwort wiederholen', 'different');
      await submit(tester, 'Konto erstellen');
      expect(
        find.text('Die Passwörter stimmen nicht überein.'),
        findsOneWidget,
      );
      expect(calls, 0);
      await tester.ensureVisible(find.byTooltip('Passwort anzeigen'));
      await tester.tap(find.byTooltip('Passwort anzeigen'));
      await tester.pump();
      expect(
        tester
            .widget<TextField>(find.widgetWithText(TextField, 'Passwort'))
            .obscureText,
        false,
      );
      await fill(tester, 'Passwort wiederholen', 'a-good-password');
      await submit(tester, 'Konto erstellen');
      expect(calls, 1);
      expect(find.text('Schau in dein Postfach.'), findsOneWidget);
    },
  );
  testWidgets(
    'login errors are readable and a retry can succeed without losing the email',
    (tester) async {
      var calls = 0;
      final backend = client(
        (r) async => ++calls == 1
            ? response({
                'error_code': 'invalid_credentials',
                'msg': 'Invalid login credentials',
              }, 400)
            : session(),
      );
      addTearDown(() => tester.runAsync(backend.dispose));
      await openLogin(tester, backend);
      await fill(tester, 'E-Mail', 'tester@example.com');
      await fill(tester, 'Passwort', 'password');
      await submit(tester, 'Anmelden');
      expect(
        find.textContaining('E-Mail oder Passwort stimmen nicht'),
        findsOneWidget,
      );
      expect(find.text('tester@example.com'), findsOneWidget);
      await submit(tester, 'Anmelden');
      expect(find.byType(LoginDialog), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'recovery retains entered email and sends the app callback without claiming account existence',
    (tester) async {
      http.Request? request;
      final backend = client((r) async {
        request = r;
        return response({});
      });
      addTearDown(() => tester.runAsync(backend.dispose));
      await openLogin(tester, backend);
      await fill(tester, 'E-Mail', 'tester@example.com');
      await tester.ensureVisible(find.text('Passwort vergessen?'));
      await tester.tap(find.text('Passwort vergessen?'));
      await tester.pumpAndSettle();
      expect(find.text('tester@example.com'), findsOneWidget);
      await submit(tester, 'Link senden');
      expect(request!.url.path, '/auth/v1/recover');
      expect(
        request!.url.queryParameters['redirect_to'],
        'com.tabtii.aniapp://login-callback/',
      );
      expect(jsonDecode(request!.body)['email'], 'tester@example.com');
      expect(find.textContaining('Falls ein Konto'), findsOneWidget);
    },
  );
  testWidgets('new password is updated only after matching confirmation', (
    tester,
  ) async {
    var writes = 0;
    final backend = client((r) async {
      if (r.method == 'PUT') {
        writes++;
        expect(jsonDecode(r.body)['password'], 'new-password');
        return response(testUser);
      }
      return session();
    });
    addTearDown(() => tester.runAsync(backend.dispose));
    await backend.auth.signInWithPassword(
      email: 'tester@example.com',
      password: 'old-password',
    );
    await openLogin(tester, backend, mode: LoginMode.newPassword);
    await fill(tester, 'Neues Passwort', 'new-password');
    await fill(tester, 'Passwort wiederholen', 'new-password');
    await submit(tester, 'Passwort speichern');
    expect(writes, 1);
    expect(find.byType(LoginDialog), findsNothing);
  });
  testWidgets('a dismissed in-flight login never pops the underlying screen', (
    tester,
  ) async {
    final pending = Completer<http.Response>();
    final backend = client((_) => pending.future);
    addTearDown(() => tester.runAsync(backend.dispose));
    await openLogin(tester, backend);
    await fill(tester, 'E-Mail', 'tester@example.com');
    await fill(tester, 'Passwort', 'password');
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Anmelden'));
    await tester.tap(find.widgetWithText(FilledButton, 'Anmelden'));
    await tester.pump();
    await tester.binding.handlePopRoute();
    await tester.pump(const Duration(seconds: 1));
    pending.complete(session());
    await tester.pumpAndSettle();
    expect(find.text('Open'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'login remains scrollable on a small screen with large text and keyboard',
    (tester) async {
      final backend = client((_) async => response({}));
      addTearDown(() => tester.runAsync(backend.dispose));
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(1.3),
              viewInsets: const EdgeInsets.only(bottom: 250),
            ),
            child: child!,
          ),
          home: Scaffold(
            body: LoginDialog(
              backend: backend,
              initialMode: LoginMode.register,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Ohne Konto weitermachen'));
      await tester.pumpAndSettle();
      // Report the full layout error when present.
    },
  );
  test(
    'store keeps a recovery event pending until the UI handles it',
    () async {
      SharedPreferences.setMockInitialValues({});
      final events = StreamController<AuthState>.broadcast();
      final backend = _EventBackend(events.stream);
      final store = AppStore(
        await SharedPreferences.getInstance(),
        backend: backend,
      );
      await store.initialize();
      events.add(const AuthState(AuthChangeEvent.passwordRecovery, null));
      await Future<void>.delayed(Duration.zero);
      expect(store.passwordRecoveryPending, true);
      store.finishPasswordRecovery();
      expect(store.passwordRecoveryPending, false);
      store.dispose();
      await events.close();
    },
  );
}

class _EventAuth extends Fake implements GoTrueClient {
  _EventAuth(this.events);
  final Stream<AuthState> events;
  @override
  User? get currentUser => null;
  @override
  Stream<AuthState> get onAuthStateChange => events;
}

class _EventBackend extends Fake implements SupabaseClient {
  _EventBackend(Stream<AuthState> events) : auth = _EventAuth(events);
  @override
  final GoTrueClient auth;
}

class _MemoryStorage extends GotrueAsyncStorage {
  final values = <String, String>{};
  @override
  Future<String?> getItem({required String key}) async => values[key];
  @override
  Future<void> setItem({required String key, required String value}) async {
    values[key] = value;
  }

  @override
  Future<void> removeItem({required String key}) async {
    values.remove(key);
  }
}
