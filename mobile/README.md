# AniApp mobile

Shared Flutter application for Android and iOS. See [implementation and setup](../docs/IMPLEMENTATION.md).

Without cloud configuration, catalog browsing and a local guest watchlist work. With Supabase configured, the app supports account sign-in and cloud watchlists. News, releases and streaming-language cards read reviewed content from the backend.

Use `flutter pub get`, then `flutter run`. Supply `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` through `--dart-define` when a dedicated project is ready.
