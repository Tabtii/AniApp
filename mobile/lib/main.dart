import 'package:flutter/material.dart';
import 'l10n/strings.dart';
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
  ThemeData _theme(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF806B),
          brightness: brightness,
        ).copyWith(
          primary: dark ? const Color(0xFFFF806B) : const Color(0xFFB93D2D),
          onPrimary: dark ? const Color(0xFF18141C) : Colors.white,
          secondary: dark ? const Color(0xFFB9A5FF) : const Color(0xFF6652AB),
          surface: dark ? const Color(0xFF0D111B) : const Color(0xFFFAF8F5),
          surfaceContainer: dark ? const Color(0xFF171D2A) : Colors.white,
          surfaceContainerHighest: dark
              ? const Color(0xFF222938)
              : const Color(0xFFEEEAE5),
          onSurface: dark ? const Color(0xFFF5F4F9) : const Color(0xFF182030),
          onSurfaceVariant: dark
              ? const Color(0xFFA9AFBE)
              : const Color(0xFF626773),
          outlineVariant: dark
              ? const Color(0xFF2A3141)
              : const Color(0xFFDDDAD5),
        );
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
    );
    return base.copyWith(
      scaffoldBackgroundColor: scheme.surface,
      textTheme: base.textTheme
          .apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface)
          .copyWith(
            headlineLarge: TextStyle(
              fontFamily: base.textTheme.headlineLarge?.fontFamily,
              fontSize: 32,
              height: 1.06,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
              color: scheme.onSurface,
            ),
            titleMedium: TextStyle(
              fontFamily: base.textTheme.titleMedium?.fontFamily,
              fontSize: 16,
              height: 1.2,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
            bodyMedium: TextStyle(
              fontFamily: base.textTheme.bodyMedium?.fontFamily,
              fontSize: 14,
              height: 1.5,
              color: scheme.onSurface,
            ),
          ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainer,
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      chipTheme: base.chipTheme.copyWith(
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: scheme.surfaceContainer,
        selectedColor: scheme.primary.withValues(alpha: .18),
        showCheckmark: false,
        labelStyle: TextStyle(
          fontFamily: base.textTheme.labelLarge?.fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainer,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        hintStyle: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: TextStyle(
            fontFamily: base.textTheme.labelLarge?.fontFamily,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        height: 72,
        indicatorColor: scheme.primary.withValues(alpha: .16),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 10,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w800
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 23,
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) => MaterialApp(
      title: 'AniApp',
      debugShowCheckedModeBanner: false,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
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
