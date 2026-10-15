import 'package:aniapp/l10n/strings.dart';
import 'package:aniapp/ui/companion_screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('source health flags stale and pending checks', (tester) async {
    final now = DateTime.utc(2026, 10, 15, 12);
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (c) {
            context = c;
            return const SizedBox();
          },
        ),
      ),
    );
    String label(String state, DateTime? checked) => healthLabel(context, {
      'state': state,
      'checked_at': checked?.toIso8601String(),
    }, now);
    final recent = now.subtract(const Duration(minutes: 40));
    final old = now.subtract(const Duration(hours: 5));
    expect(label('ok', recent), startsWith('Läuft'));
    expect(label('degraded', recent), startsWith('Gestört'));
    expect(label('ok', old), startsWith('Veraltet'));
    expect(label('degraded', old), startsWith('Veraltet'));
    expect(label('pending', null), 'Noch nicht geprüft');
    expect(label('ok', null), 'Noch nicht geprüft');
  });
}
