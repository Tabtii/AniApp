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

News runs without Firecrawl or paid API credentials. The `content-sync` Edge Function reads the public [Anime2You RSS feed](https://www.anime2you.de/feed/) and [Tenrai news endpoint](https://api.tenrai.org/documentation). It publishes current headlines with publisher, language, original date, source image, a short excerpt (at most 20 words), and direct source URL. Image URLs are restricted to the source CDN over HTTPS. It does not copy full articles or infer anime IDs from news IDs. The old `scripts/ingest_news.py` is an optional, unused manual draft tool; no scheduled task invokes it.

The server-side `scripts/ingest_availability.py` adapter fetches Streaming Availability API data for an explicitly reviewed MAL/provider ID match. It imports series-wide audio and subtitle data as unpublished drafts, never infers episode releases from a provider detection timestamp and never silently matches by title. Set `STREAMING_API_KEY` in the server environment. For example: `python scripts/ingest_availability.py --mal-id 123 --show-id tt1234567 --mapping-reviewed --region DE`. Review the ID mapping before invoking it.

Live content is active: the first successful scheduled import on 2026-10-08 produced 40 news items and 87 broadcast events. `pg_cron` invokes `content-sync` at minute 15 every hour. A random internal token stays in Supabase Vault; the function validates it through a service-role-only RPC and claims a database lease, preventing overlapping/repeated imports. No client can write content or trigger a privileged refresh. Failed sources preserve previously published data and are recorded separately in the private sync status table.

The release importer reads every page of Tenrai's currently airing schedule and calculates the next weekly slot in Asia/Tokyo. These are **estimated Japanese broadcast slots**, not confirmed episode numbers, German streaming releases or dub dates. Unknown times are excluded, finished series are excluded, and no episode numbers are extrapolated. The app shows the qualification and original source, and links calendar entries to the relevant anime detail.

Five German Crunchyroll series pages were retrieved live and reviewed for audio and subtitles: Frieren, The Apothecary Diaries, Black Clover, Solo Leveling and DAN DA DAN. The factual observations and source URLs are recorded in `supabase/content/availability-reviewed-2026-10-08.json` and published in Supabase. These are dated series-level observations, **not an automatically refreshed or comprehensive language feed**, and are not copied to unverified seasons or other regions. Other titles retain an explicit unknown-language state and a link to the MAL provider overview. Provider access/subscriptions may still differ per region and episode. Push notifications and a comprehensive German dub calendar are not implemented.

Version 0.3.3 adds the `anime-enrichment` gateway and mobile panels for MyDubList, TMDb/JustWatch and AniList. MyDubList runs without credentials. TMDb requires a server-side API credential; AniList is implemented but disabled pending permission under its competing-tracker restriction. See [source behavior, activation and limitations](DATA_SOURCES.md). Japanese broadcasts never imply a confirmed local streaming or dub release.

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

The dedicated **AniApp** project `pisonrhjrqpqazimiiln` is active in organization **Wolff**, Frankfurt (`eu-central-1`), on the Free plan. All migrations in `supabase/migrations/`, the read-only `catalog` function and the scheduled `content-sync` function are deployed. Existing unrelated projects were not modified. Configure `MAL_CLIENT_ID` as a function secret if using MAL.

Email/password sign-up and email confirmation are enabled. The site URL and allowed redirect URL are `com.tabtii.aniapp://login-callback/`, handled by the Android and iOS app. Custom SMTP is **not configured**: [Supabase's default mail service](https://supabase.com/docs/guides/auth/auth-smtp) only sends to organization team members. Public email sign-up needs a mail provider; email confirmation has not been disabled to bypass this requirement. No real user confirmation email or physical-device sign-in has been tested.

The schema enables RLS on every exposed table. Only an owner can read/write their watchlist. Public users can read only published content and verified ID mappings; publication writes are server-only. The catalog function validates the project's publishable key and catalog paths, with isolate-local caching and rate limits. The key identifies a public client; it is not user authorization or an abuse-prevention secret. At production scale add durable shared quotas; this first implementation does not claim a global distributed quota. The automatic RLS event trigger remains enabled, while its internal SECURITY DEFINER function is not executable by API roles.

The Flutter app's Supabase accounts are separate from the existing Firebase accounts. Existing Firebase users and favorites need a verified export/import migration before switching production users. Neither identity mappings nor passwords are guessed or overwritten.

## Tests and build checks

Version **0.2.3+5** switches the live Supabase catalog and the direct mobile fallback to Tenrai. Live HTTP checks on 2026-10-08 returned 200 for the current fall season, page 2, Naruto search, Fantasy filtering and Frieren details, including a synopsis and MAL IDs. Two returned cover URLs also returned 200 with JPEG images. News, release-events and availability endpoints return 200 with empty lists, correctly reflecting that no reviewed content has been published yet. Supabase recorded approximately 0.5–0.7 seconds of server execution on sampled requests; this is not total device latency. Validation for that version: 13 Flutter tests and 8 backend tests passed; Flutter analysis had no findings.

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


## Live content verification (0.2.4)

- Public REST API returned HTTP 200 with 40 news records, 87 future broadcast records and the reviewed Frieren language record using only the app publishable key.
- Scheduled Edge invocation returned `ok` for all three sources; a second invocation within the lease returned 202 without fetching again. Missing internal token returned 401.
- Backend tests cover RSS freshness/source checks, timezone/day rollover, unknown times, news-vs-anime IDs, content-write permissions and sync lease/authentication. Flutter checks cover the app and earlier navigation/dialog regressions.
- News collection uses free public endpoints. It consumes the existing Supabase project's normal function/network/database quotas; it needs no separate crawler subscription or Firecrawl credits.


## Visual redesign (0.3.0+7)

- Discovery features a large real anime cover followed by a responsive poster grid. Season/search/genre filters, pagination and watchlist actions are retained.
- News features a leading image card, compact illustrated headlines, short source excerpts and topic filters. Original articles open externally. Missing images use a neutral icon instead of invented artwork.
- The calendar groups upcoming events by day with date filters, source links and series posters. Estimated Japanese broadcast labels remain visible.
- Detail pages, watchlists, profile, navigation and typography share the new coral/lavender palette in both light and dark mode. Text scaling is supported.
- Live `content-sync` version 2 imported 40 news previews and 87 broadcast posters successfully. The hourly free RSS/API pipeline remains unchanged; no paid crawling or new provider account is required.
- Visual checks render production Flutter widgets with snapshots of the live API and the actual source images. They are UI renders, not physical Android/iOS device captures. The app itself reads the live APIs.


## AniApp mark and dub announcements (0.3.1+8)

The custom vector A/play mark replaces the lightning badge and stock launcher icons. `mobile/lib/ui/brand.dart` is the editable source; run `flutter test tool/export_brand_test.dart` from `mobile/` to regenerate native and web icon sizes. Android has an adaptive launcher icon.

Anime details now have a dedicated panel for the preferred dubbing language and region. Published dub announcements remain visible independently of the calendar filter and distinguish availability observations, announcements without dates, dates without times, and timestamped releases. A date-only release never invents midnight or shifts to another day when changing timezones. A past announced date does not prove current availability. Calendar users can filter directly to dubs in their preferred language.

Thirteen autumn 2026 German Crunchyroll dub announcements were reviewed against the official seasonal dub announcement and lineup on 2026-10-08, mapped to their specific MAL season IDs, and published to Supabase. All thirteen currently have an unknown start date. The review record is `supabase/content/dubs-reviewed-2026-10-08.json`. These reviewed dub records are **not automatically refreshed** and do not constitute a comprehensive dub feed; the existing hourly news/Japanese-broadcast pipeline continues independently. New exact dates require a verified source update, not extrapolation from Japanese broadcasts. The app reads the published database records live.

Validation includes database constraints for date precision, a public REST read returning all 13 dub announcements, explicit undated/error/availability UI states and the existing regression suite. The security advisor retains the [pg_net namespace warning](https://supabase.com/docs/guides/database/database-linter?lint=0014_extension_in_public) and reports [leaked-password protection disabled](https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection); neither setting was changed by this feature. Public email confirmation still requires custom SMTP.


## Provider calendar and continuing seasons (0.3.2+9)

The calendar is independent of the seasonal discovery selector. Tenrai's 87 currently airing Japanese broadcast slots already include long-running titles such as One Piece and Case Closed. A regression test now explicitly covers an anime that started in a previous season.

`content-sync/adn.ts` adds the free public ADN episode calendar, read with German distribution headers. Each hourly import reads the coming 14 days, checks the returned distribution and German source URL independently of those headers, and maps reviewed provider show **and season** IDs to MAL IDs. The initial ten mappings include spring 2026's Rilakkuma, continuing with episodes 27 and 28, six current series and four Bleach films. No fuzzy title matching, guessed languages or inferred episode numbers are used. Unmapped IDs are counted in the private import report for review. The mapping file is intentionally a reviewed subset, not a claim to cover every ADN title.

ADN timestamps and episode languages are read from the actual provider response. Films are labeled as catalog additions, not new dub productions. An unknown audio list stays unknown. New/changed events are upserted first; stale events are unpublished only for calendar days that were successfully fetched and validated. A failed day keeps its previous records. These two writes are not atomic: if cleanup fails, the sync reports the error and retries next hour. Manual ADN announcements use their news source URLs and are unaffected. No database schema change or paid crawler is needed.

Five additional reviewed records are in `supabase/content/provider-releases-reviewed-2026-10-08.json`: the delayed German Bookworm episode from the spring season, ADN's October 22 German Dragon Hatchling announcement, Netflix's next Blue Box weekly slot, and two aniverse / Prime Video weekly slots. These five records are **manual dated observations**, not automatically refreshed feeds. Weekly-pattern slots are marked estimated, not confirmed episode releases; Netflix audio remains unknown. The Bookworm language is cross-checked against the official German dub announcement. Dates must be reviewed again before extending this subset.

Calendar cards expose the provider, release note, review date and source. Provider filters are generated from actual records; Japanese TV is a separate choice. All available date filters remain reachable, including later-month and undated announcements. Paging removes the old 200-record cutoff, with stable ordering, region/audio filtering and a bounded request deadline. Switching filters clears stale day selections. The same anime may correctly appear once for Japanese TV and again for local streaming or a dub.

Live verification on 2026-10-08: content-sync version 4 returned HTTP 200, 25 Anime2You headlines, 15 MAL headlines, 87 Japanese slots and **18 ADN events across 13 read days**. Five reviewed additions bring the published total to 123 events across Japanese TV, Crunchyroll, ADN, Netflix and aniverse / Prime Video. Coverage remains incomplete for provider episode schedules and German dubs. The existing Supabase security advisories documented above are unchanged.

Validation: 19 Flutter tests, 16 backend tests and 6 Python tests, including paging past 200 rows, later-day/provider filtering, older-season schedules, locale mismatches, unknown audio, skipped days, rescheduling and DST-safe cleanup boundaries. The visual check uses production Flutter widgets and live API snapshots/source posters; it is not a physical-device screenshot.
