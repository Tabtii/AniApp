import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'data/app_store.dart';
import 'ui/shell.dart';

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
  await store.initialize();
  runApp(AniApp(store: store, startupWarning: startupWarning));
}

class AniApp extends StatelessWidget {
  const AniApp({super.key, required this.store, this.startupWarning});
  final AppStore store;
  final String? startupWarning;
  ThemeData _theme(Brightness brightness) => ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF7954DF),
      brightness: brightness,
    ),
    scaffoldBackgroundColor: brightness == Brightness.dark
        ? const Color(0xFF13101C)
        : const Color(0xFFF7F5FC),
    cardTheme: const CardThemeData(
      elevation: 0,
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'AniApp',
    debugShowCheckedModeBanner: false,
    theme: _theme(Brightness.light),
    darkTheme: _theme(Brightness.dark),
    themeMode: ThemeMode.system,
    locale: const Locale('de'),
    supportedLocales: const [Locale('de'), Locale('en')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    home: AppShell(store: store, startupWarning: startupWarning),
  );
}
