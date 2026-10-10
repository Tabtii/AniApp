import 'package:aniapp/l10n/strings.dart';
import 'package:aniapp/data/app_store.dart';
import 'package:aniapp/ui/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GuestAuth extends Fake implements GoTrueClient {
  @override
  User? get currentUser => null;
  @override
  Stream<AuthState> get onAuthStateChange => const Stream.empty();
}

class GuestBackend extends Fake implements SupabaseClient {
  @override
  final GoTrueClient auth = GuestAuth();
}

void main() {
  testWidgets('focused login can close and reopen without a lifecycle error', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final backend = GuestBackend();
    final store = AppStore(
      await SharedPreferences.getInstance(),
      backend: backend,
    );
    await store.initialize();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: ProfileScreen(store: store)),
      ),
    );
    await tester.tap(find.text('Anmelden oder registrieren'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'E-Mail'),
      'tester@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Passwort'),
      'test-password',
    );
    await tester.tap(find.byTooltip('Schließen'));
    // Include the dismissal animation: showDialog completes before its fields unmount.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Anmelden oder registrieren'));
    await tester.pumpAndSettle();
    expect(find.text('tester@example.com'), findsNothing);
    await tester.enterText(
      find.widgetWithText(TextField, 'E-Mail'),
      'again@example.com',
    );
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Anmelden oder registrieren'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Passwort'),
      'test-password',
    );
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    store.dispose();
  });
}
