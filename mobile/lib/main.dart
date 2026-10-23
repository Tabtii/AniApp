import 'package:flutter/material.dart';
import 'l10n/strings.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'data/app_store.dart';
import 'ui/shell.dart';
import 'ui/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const url = String.fromEnvironment('SUPABASE_URL');
  const key = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  SupabaseClient? backend;
  String? startupWarning;
  if (url.isNotEmpty && key.isNotEmpty) {
    try {
      await Supabase.initialize(url: url, anonKey: key);
      backend = Supabase.instance.client;
    } catch (_) {
      startupWarning =
          'Cloud-Verbindung konnte nicht gestartet werden. Die lokale Watchlist ist weiter verfügbar.';
    }
  }
  final store = AppStore(
    await SharedPreferences.getInstance(),
    backend: backend,
  );
  await store.initialize(waitForCloud: false);
  runApp(AniApp(store: store, startupWarning: startupWarning));
}

class AniApp extends StatelessWidget {
  const AniApp({super.key, required this.store, this.startupWarning});
  final AppStore store;
  final String? startupWarning;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) => MaterialApp(
      title: 'AniApp',
      debugShowCheckedModeBanner: false,
      theme: aniAppTheme(Brightness.light),
      darkTheme: aniAppTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      locale: store.appLanguage == 'system' ? null : Locale(store.appLanguage),
      localeResolutionCallback: (locale, supported) =>
          Locale(locale?.languageCode == 'de' ? 'de' : 'en'),
      supportedLocales: const [Locale('en'), Locale('de')],
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: AppShell(store: store, startupWarning: startupWarning),
    ),
  );
}
