import 'package:aniapp/l10n/strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aniapp/models/content.dart';
import 'package:aniapp/ui/dub_panel.dart';

void main() {
  testWidgets('announced dub remains undated and is not shown as available', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: DubPanel(
            language: 'de',
            region: 'DE',
            loading: false,
            availability: const [],
            onRetry: () {},
            events: [
              ReleaseEvent({
                'kind': 'dub',
                'status': 'announced',
                'provider': 'Publisher',
                'source_url': 'https://example.com',
              }),
            ],
          ),
        ),
      ),
    );
    expect(find.text('Angekündigt'), findsOneWidget);
    expect(find.text('Starttermin noch offen'), findsOneWidget);
    expect(find.text('Als verfügbar gemeldet'), findsNothing);
  });
  testWidgets('a load error offers retry without claiming no dub exists', (
    tester,
  ) async {
    var retried = false;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: DubPanel(
            language: 'de',
            region: 'DE',
            loading: false,
            availability: const [],
            events: const [],
            error: 'Nicht erreichbar',
            onRetry: () {
              retried = true;
            },
          ),
        ),
      ),
    );
    expect(find.textContaining('keine belegte'), findsNothing);
    await tester.tap(find.text('Erneut laden'));
    expect(retried, isTrue);
  });
  test('day-only announcement never invents midnight', () {
    final e = ReleaseEvent({
      'starts_on': '2026-10-15',
      'kind': 'dub',
      'status': 'confirmed',
    });
    expect(dubDateLabel(e), '15.10.2026 · Uhrzeit offen');
  });
}
