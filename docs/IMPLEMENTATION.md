# AniApp: Flutter companion

The shared application lives in `mobile/` and targets Android and iOS. The original Kotlin training application remains in `app/` as a reference. It has not been migrated or replaced in place.

## Working application features

- Seasonal catalog with dynamic years, search and genre selection.
- Anime details, responsive cover cards and system light/dark themes.
- Guest watchlist stored on device, five statuses and bounded episode progress.
- Supabase email/password sign-in and user-isolated cloud watchlists; CI builds connect to the active AniApp project.
- Explicit guest-list import that retains existing cloud entries.
- News, release calendar and per-region provider/language detail screens, reading published Supabase data.
- Source links, last-check timestamps and distinct announced/confirmed/estimated statuses.

## Data sources

The app uses [Tenrai v1](https://api.tenrai.org/documentation) directly when no backend is configured or the backend is unavailable. The `catalog` Edge Function uses the official MyAnimeList API when `MAL_CLIENT_ID` is configured and the request is supported, otherwise Tenrai. Tenrai follows the Jikan v4 response schema and preserves MAL IDs, so existing watchlists retain their identity. MAL and Tenrai ultimately share the MyAnimeList catalog; they are not independent confirmation of a fact. The unreachable public Jikan host is no longer part of the Flutter or server request path.

MAL does not support the UI's genre search or empty search in the same way as Tenrai. Those requests go to Tenrai. Official search results have their provider's native ranking; genre searches and direct fallback use score ordering. Public Tenrai requests need no credentials; its documented public limits are 120 requests/minute and 4 requests/second. The client and gateway rate limits remain below these limits per instance, with caching and bounded timeouts.

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

With the configured AniApp Supabase project:

```sh
flutter run --dart-define-from-file=config/supabase.json
```

Only publishable keys belong in the app. Provider keys, Firecrawl keys and Supabase secret keys remain in backend environment variables. Flutter's production bundle IDs and Apple signing team must be finalized before store submission.

## Cloud setup

The dedicated **AniApp** project `pisonrhjrqpqazimiiln` is active in organization **Wolff**, Frankfurt (`eu-central-1`), on the Free plan. Both migrations in `supabase/migrations/` and the read-only `catalog` function are deployed. Existing unrelated projects were not modified. Configure `MAL_CLIENT_ID` as a function secret if using MAL.

Email/password sign-up and email confirmation are enabled. The site URL and allowed redirect URL are `com.tabtii.aniapp://login-callback/`, handled by the Android and iOS app. Custom SMTP is **not configured**: [Supabase's default mail service](https://supabase.com/docs/guides/auth/auth-smtp) only sends to organization team members. Public email sign-up needs a mail provider; email confirmation has not been disabled to bypass this requirement. No real user confirmation email or physical-device sign-in has been tested.

The schema enables RLS on every exposed table. Only an owner can read/write their watchlist. Public users can read only published content and verified ID mappings; publication writes are server-only. The catalog function validates the project's publishable key and catalog paths, with isolate-local caching and rate limits. The key identifies a public client; it is not user authorization or an abuse-prevention secret. At production scale add durable shared quotas; this first implementation does not claim a global distributed quota. The automatic RLS event trigger remains enabled, while its internal SECURITY DEFINER function is not executable by API roles.

The Flutter app's Supabase accounts are separate from the existing Firebase accounts. Existing Firebase users and favorites need a verified export/import migration before switching production users. Neither identity mappings nor passwords are guessed or overwritten.

## Tests and build checks

Version **0.2.3+5** switches the live Supabase catalog and the direct mobile fallback to Tenrai. Live HTTP checks on 2026-10-08 returned 200 for the current fall season, page 2, Naruto search, Fantasy filtering and Frieren details, including a synopsis and MAL IDs. Two returned cover URLs also returned 200 with JPEG images. News, release-events and availability endpoints return 200 with empty lists, correctly reflecting that no reviewed content has been published yet. Supabase recorded approximately 0.5–0.7 seconds of server execution on sampled requests; this is not total device latency. Current validation: 13 Flutter tests and 8 backend tests pass; Flutter analysis has no findings.

Version **0.2.2+4** fixes a reproduced login-dialog crash: text controllers now live in the dialog's own State and are disposed only after the dismissal animation, not when `showDialog` completes. Regression coverage includes focused-field cancellation, Android back, outside-tap dismissal and reopening. Catalog requests have a 12-second overall deadline, a shorter gateway timeout, request coalescing and shared result caching; a failed gateway is skipped briefly. Loading and retry states remain visible when the external anime source is unavailable. That hotfix addressed UI and waiting behavior; version 0.2.3 replaces the failing upstream. The hotfix passes 13 Flutter tests and static analysis.

```sh
cd mobile
flutter analyze
flutter test
flutter build apk --debug --dart-define-from-file=config/supabase.json
# On macOS with Xcode:
flutter build ios --simulator --debug --dart-define-from-file=config/supabase.json
```

Backend tests use embedded PostgreSQL to exercise RLS as two distinct authenticated users and an anonymous role, plus provider normalization and fallback tests:

```sh
npm ci --prefix backend
npm test --prefix backend
python -m unittest discover -s scripts -p 'test_*.py'
```

GitHub Actions checks Flutter analysis/tests and Android/iOS builds. A simulator build is not a signed App Store release. Device testing, end-to-end email confirmation and streaming-language coverage verification remain required before release.

Verification on 2026-10-08: Flutter 3.47.6 analysis reports no issues, all 13 Flutter tests pass (including catalog-to-watchlist episode progress on a 390px viewport), all 8 provider/key/RLS tests pass and the earlier 6 Python importer tests and web build pass. Live Supabase checks confirm public published-content reads, denial of anonymous watchlist access, owner read/update isolation and rejection of cross-user writes. Temporary database test data was rolled back. Security Advisor reports no findings. The catalog rejects missing keys with 401. The original Jikan requests returned 503; the Tenrai replacement has since passed the live catalog checks listed above. No MAL key is configured. Android SDK and Xcode are not installed in the editing environment; native builds are delegated to CI.
