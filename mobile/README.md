# AniApp mobile

Shared Flutter application for Android and iOS. See [implementation and setup](../docs/IMPLEMENTATION.md).

Without cloud configuration, catalog browsing and a local guest watchlist work. With Supabase configured, the app supports account sign-in and cloud watchlists. News, releases and streaming-language cards read reviewed content from the backend.

Use `flutter pub get`, then `flutter run --dart-define-from-file=config/supabase.json` to connect to the active AniApp project. The file contains only the public project URL and publishable client key. CI uses this configuration for both Android and iOS builds.

Email confirmation opens `com.tabtii.aniapp://login-callback/`. The default Supabase mail service currently allows confirmation emails only to organization team members; custom SMTP is required for other testers. Never put a database password, service-role key or provider secret in the app configuration.
