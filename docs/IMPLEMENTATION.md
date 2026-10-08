# AniApp: Flutter companion

The shared application lives in `mobile/` and targets Android and iOS. The original Kotlin training application remains in `app/` as a reference. It has not been migrated or replaced in place.

## Working application features

- Seasonal catalog with dynamic years, search and genre selection.
- Anime details, responsive cover cards and system light/dark themes.
- Guest watchlist stored on device, five statuses and bounded episode progress.
- Optional Supabase email/password sign-in and user-isolated cloud watchlists.
- Explicit guest-list import that retains existing cloud entries.
- News, release calendar and per-region provider/language detail screens, reading published Supabase data.
- Source links, last-check timestamps and distinct announced/confirmed/estimated statuses.

## Data sources

The app uses Jikan directly when no backend is configured. The optional `catalog` Edge Function uses the official MyAnimeList API when `MAL_CLIENT_ID` is configured and the request is supported, otherwise Jikan. MAL and Jikan ultimately share the MyAnimeList catalog; they are not independent confirmation of a fact.

MAL does not support the UI's genre search or empty search in the same way as Jikan. Those requests go to Jikan. Official search results have their provider's native ranking; genre searches and direct fallback use Jikan score ordering.

News ingestion through `scripts/ingest_news.py` reads approved official HTTPS articles through Firecrawl and writes unpublished drafts. Review the extracted summary and source before publication. It does not infer release times, match series by fuzzy title, or publish a full article.

The server-side `scripts/ingest_availability.py` adapter fetches Streaming Availability API data for an explicitly reviewed MAL/provider ID match. It imports series-wide audio and subtitle data as unpublished drafts, never infers episode releases from a provider detection timestamp and never silently matches by title. Set `STREAMING_API_KEY` in the server environment. For example: `python scripts/ingest_availability.py --mal-id 123 --show-id tt1234567 --mapping-reviewed --region DE`. Review the ID mapping before invoking it.

Release and language data currently require source-grounded ingestion/review. Database tables and app screens are implemented, but no live source subscriptions, background schedule, push notifications or complete German dub feed have been activated. Unknown languages remain null; a series-wide language entry is never displayed as episode-specific evidence.

AniList is deliberately not integrated pending clarification of its competing-tracker restriction. Japanese broadcast schedules are displayed as regular Japanese broadcast information, never as a confirmed local streaming release.

## Run

Install Flutter stable and run from `mobile/`:

```sh
flutter pub get
flutter run
```

With an AniApp Supabase project:

```sh
flutter run --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
```

Only publishable keys belong in the app. Provider keys, Firecrawl keys and Supabase secret keys remain in backend environment variables. Flutter's production bundle IDs and Apple signing team must be finalized before store submission.

## Cloud setup

Choose a dedicated AniApp Supabase project; existing unrelated projects must not be modified.
Apply the SQL migration in `supabase/migrations/` to a fresh project and deploy the read-only `catalog` function. Configure `MAL_CLIENT_ID` as a function secret if using MAL. Enable email confirmation and production SMTP before public signup.

The schema enables RLS on every exposed table. Only an owner can read/write their watchlist. Public users can read only published content and verified ID mappings; publication writes are server-only. The catalog function is public, accepts only validated catalog paths and has isolate-local caching and rate limits. At production scale add durable shared quotas; this first implementation does not claim a global distributed quota.

The Flutter app's Supabase accounts are separate from the existing Firebase accounts. Existing Firebase users and favorites need a verified export/import migration before switching production users. Neither identity mappings nor passwords are guessed or overwritten.

## Tests and build checks

```sh
cd mobile
flutter analyze
flutter test
flutter build apk --debug
# On macOS with Xcode:
flutter build ios --simulator --debug
```

Backend tests use embedded PostgreSQL to exercise RLS as two distinct authenticated users and an anonymous role, plus provider normalization and fallback tests:

```sh
npm ci --prefix backend
npm test --prefix backend
python -m unittest discover -s scripts -p 'test_*.py'
```

GitHub Actions checks Flutter analysis/tests and Android/iOS builds. A simulator build is not a signed App Store release. Device testing, full live Supabase integration and streaming-language coverage verification remain required before release.

Local verification on 2026-10-08: Flutter 3.47.6 analysis reports no issues, all 9 Flutter tests pass (including catalog-to-watchlist episode progress on a 390px viewport), the web build succeeds, all 5 provider/RLS tests pass and all 6 Python importer tests pass. Android SDK and Xcode are not installed in the editing environment; native builds are delegated to the configured CI jobs.
