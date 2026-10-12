# AniApp mobile

Shared Flutter application for **Android and iOS**, version **0.3.6+13**, with a German/English interface. The current code is on `feature/anime-companion`.

[Project overview](../README.md) · [Data sources](../docs/DATA_SOURCES.md) · [Release readiness](../docs/RELEASE_READINESS.md)

## Start the app

Use **Flutter 3.47.6**, matching `.github/workflows/flutter.yml`. Android needs the Android SDK and a device/emulator; iOS development needs macOS and Xcode.

From this directory:

```bash
flutter pub get
flutter run --dart-define-from-file=config/supabase.json
```

The configuration connects to the active AniApp backend. It contains only the public project URL and publishable client key. For a different project, supply your own file with the same two fields and pass its path to `--dart-define-from-file`:

```json
{
  "SUPABASE_URL": "https://YOUR_PROJECT.supabase.co",
  "SUPABASE_PUBLISHABLE_KEY": "YOUR_PUBLISHABLE_KEY"
}
```

Never include a database password, service-role key or provider secret in app configuration. Backend schema/function setup is separate; see [implementation details](../docs/IMPLEMENTATION.md).

Without cloud configuration, catalog browsing and a local guest watchlist work. Supabase enables shared news, release events, account access and cloud watchlists. Automatic announcement extraction runs server-side; the app reads published, sourced records rather than scraping websites itself.

## Language and calendar settings

- **Interface:** device language, German or English. The device default is German for a German device locale, otherwise English.
- **News:** follow the app language, German, English or both.
- **Dub audio:** German, English or both, independent of interface language.
- **Country:** DE, AT, CH, US or GB, independent of language.
- **Calendar:** include original/provider releases, or show selected dubs only. Continuing shows from older seasons remain eligible.

Article text and source notes retain their source language. Unknown dates remain TBA, date-only releases do not invent a clock time, and missing provider/language evidence is not treated as availability.

## Authentication

The app includes login, registration and password recovery. Confirmation/recovery links use:

```text
com.tabtii.aniapp://login-callback/
```

Configure the allowed redirect and email delivery for your Supabase project. The current test deployment still needs owned SMTP and end-to-end confirmation/recovery tests for public signup. A local guest watchlist can be used without an account.

## Validate and build

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug --dart-define-from-file=config/supabase.json
```

Android output: `build/app/outputs/flutter-apk/app-debug.apk`.

On macOS, for the simulator:

```bash
flutter build ios --simulator --debug --dart-define-from-file=config/supabase.json
```

Physical iPhone distribution requires Apple signing. CI produces Android debug artifacts and validates the iOS simulator build; neither is a public store release.

Localization resources live in `lib/l10n/app_de.arb` and `lib/l10n/app_en.arb`. Run `flutter gen-l10n` after editing them.
