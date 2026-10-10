<p align="center">
  <img src="https://raw.githubusercontent.com/Tabtii/AniApp/feature/anime-companion/docs/brand/aniapp-mark.png" alt="AniApp logo" width="112">
</p>

# AniApp

**Your anime companion for Android and iOS.** Discover anime, keep a watchlist, follow episode releases and read news in German or English — with real sources and clear language availability.

**Current app:** `0.3.6+13` · Flutter · Deutsch / English · Development preview

[Download Android test build](https://github.com/Tabtii/AniApp/actions/runs/38038317106/artifacts/11663684733) · [Flutter source](https://github.com/Tabtii/AniApp/tree/feature/anime-companion/mobile) · [Development PR](https://github.com/Tabtii/AniApp/pull/1) · [Coverage and release status](https://github.com/Tabtii/AniApp/blob/feature/anime-companion/docs/RELEASE_READINESS.md)

> The current Flutter app lives on **`feature/anime-companion`**, in PR #1. The `master` branch still contains the original Kotlin application. Use the development branch to build or explore the current app.

## What you can do

- **Discover anime:** search the live catalog, browse seasons and view covers, descriptions, metadata and available trailers.
- **Track your watchlist:** start locally as a guest or use an account for a cloud-backed list and episode progress.
- **Follow releases:** see Japanese broadcast estimates, verified provider episode dates and supported dub announcements — including anime continuing from earlier seasons.
- **Choose languages independently:** German/English interface, news language and preferred dub audio. Country selection is separate: DE, AT, CH, US or GB.
- **Read live news:** image previews, short excerpts and links to original articles; filter German, English or both.
- **Check dub evidence:** distinguish a known dub from a verified provider offer, a dated announcement and a release whose date is still unknown.

## Automatic dub announcements

The backend checks supported sources in the existing **hourly content import**. Recognized DE/EN announcements are matched to an exact anime/season and reconciled with the calendar automatically.

- Explicit premiere dates create premiere entries. Explicit episode numbers or ranges create only the stated episode entries.
- Updates from the same source can correct a date without duplicating the calendar entry.
- Unknown dates stay **TBA**. Conflicting sources, ambiguous seasons and missing language/territory evidence go into a private review queue.
- Known article URLs remain watched after leaving a feed. Article pages are normally revisited every six hours; current Crunchyroll feed content is checked hourly. Queued work can take longer.
- A failed source does not erase existing releases. Japanese airing dates and weekly patterns never become confirmed dub dates.

This runs in Supabase; phones do not crawl websites. Backend content updates reach the existing test app without an APK reinstall.

**Coverage is partial.** Some older Crunchyroll pages do not provide readable article content, and not every provider publishes usable dub dates. English audio does not establish availability in every English-speaking country. [Source rules and limitations →](https://github.com/Tabtii/AniApp/blob/feature/anime-companion/docs/DATA_SOURCES.md)

## Live data sources

| Area | Active sources | What the data establishes |
| --- | --- | --- |
| Catalog and discovery | Tenrai / MyAnimeList | Anime identities, season listings, covers and metadata |
| Additional details | Kitsu | Independent metadata, original airing dates and available trailers |
| Japanese broadcasts | Tenrai / MyAnimeList schedules | Weekly estimates; reviewed pause notices take precedence |
| Provider episodes | Official ADN calendar | Exact language/date/time for reviewed show-and-season mappings |
| News | Anime2You, MyAnimeList via Tenrai, ADN News, AniNews, official Crunchyroll DE/EN RSS | Short previews with original source links |
| Dub announcements | Supported Crunchyroll RSS, ADN, Anime2You and AniNews formats | Explicit, sufficiently evidenced DE/EN premiere or episode dates |
| Dub existence | MyDubList | Evidence that a dub exists; not proof of a local provider offer or release date |

Netflix, aniverse and other providers may appear in supported news reports. This is **not** a comprehensive direct integration with every provider. TMDb and AniList adapters exist but are not active: TMDb needs a project-specific API credential; AniList additionally requires usage authorization.

## Try it on Android

1. Open the [verified 0.3.6+13 Android artifact](https://github.com/Tabtii/AniApp/actions/runs/38038317106/artifacts/11663684733). GitHub sign-in may be required.
2. Download and extract the ZIP, then install `app-debug.apk` on your Android device.
3. Allow installation from that download source if Android asks. You can begin with the guest watchlist.

This is a **debug build**, not a Play Store release. GitHub artifacts expire; newer successful builds are available under [GitHub Actions](https://github.com/Tabtii/AniApp/actions/workflows/flutter.yml).

**iOS:** the shared app builds for the simulator in CI. Installation on a physical iPhone still requires Apple signing and device distribution; no TestFlight release is available yet.

## Run locally

Use Flutter **3.47.6**, matching CI, plus the Android SDK or macOS/Xcode for iOS development.

```bash
git clone --branch feature/anime-companion https://github.com/Tabtii/AniApp.git
cd AniApp/mobile
flutter pub get
flutter run --dart-define-from-file=config/supabase.json
```

The checked-in configuration connects to the current AniApp backend and contains only the public project URL and publishable client key. To use your own backend, provide your own configuration file. Never put a database password, service-role key or provider secret in a mobile build.

Without Supabase configuration, catalog browsing and the local guest watchlist remain available; shared news, calendar data and cloud features require the backend. See the [mobile setup guide](https://github.com/Tabtii/AniApp/blob/feature/anime-companion/mobile/README.md).

## Project layout

Paths below refer to the development branch.

| Path | Purpose |
| --- | --- |
| [`mobile/`](https://github.com/Tabtii/AniApp/tree/feature/anime-companion/mobile) | Flutter app, Android/iOS projects, DE/EN localization and widget tests |
| [`supabase/functions/`](https://github.com/Tabtii/AniApp/tree/feature/anime-companion/supabase/functions) | Catalog gateway, enrichment and content import |
| [`supabase/migrations/`](https://github.com/Tabtii/AniApp/tree/feature/anime-companion/supabase/migrations) | Schema, access policies and server-only reconciliation |
| [`backend/test/`](https://github.com/Tabtii/AniApp/tree/feature/anime-companion/backend/test) | Source parsing, identity matching, reconciliation and database access tests |
| [`docs/`](https://github.com/Tabtii/AniApp/tree/feature/anime-companion/docs) | Implementation history, data sources and release readiness |

## Checks

From `mobile/`:

```bash
flutter analyze
flutter test
```

From the repository root:

```bash
npm ci --prefix backend
npm test --prefix backend
python -m unittest discover -s scripts -p 'test_*.py'
```

As of **10 October 2026**, the project has 40 passing Flutter tests, 57 passing backend tests and 6 passing Python tests. CI checks the app and backend, builds an Android debug APK and builds the iOS simulator app. Test fixtures are not production content.

## Before a public release

- Expand provider/region coverage and review unresolved announcement formats and title mappings.
- Configure an owned SMTP sender and verify registration, email confirmation, recovery and app links on real devices.
- Complete privacy/contact, account deletion/export and physical-device accessibility/offline checks.
- Prepare signed Android/iOS releases and store distribution.

See [release readiness](https://github.com/Tabtii/AniApp/blob/feature/anime-companion/docs/RELEASE_READINESS.md) for the verified status and remaining work.

## Original Kotlin project

AniApp began as **AniMe**, an Android training project for Syntax Institute. The Kotlin implementation and its 2023 screenshots are preserved as historical reference; those screenshots do not represent the current Flutter interface.

[Original project description and screenshots](https://github.com/Tabtii/AniApp/blob/559de9b49e0fa029213c5a3f789452ab357e6c33/README.md)

## License

See [LICENSE](https://github.com/Tabtii/AniApp/blob/master/LICENSE).
