<p align="center">
  <img src="https://raw.githubusercontent.com/Tabtii/AniApp/feature/anime-companion/docs/brand/aniapp-mark.png" alt="AniApp logo" width="112">
</p>

# AniApp

**Your anime companion for Android and iOS.** Discover anime, keep a watchlist, follow episode releases and read news in German or English — with real sources and clear language availability.

**Current app:** `0.5.0+15` · Flutter · Deutsch / English · Development preview

[**Current status**](https://github.com/Tabtii/AniApp/blob/feature/anime-companion/docs/STATUS.md) · [Android test builds](https://github.com/Tabtii/AniApp/actions/workflows/flutter.yml) · [Flutter source](https://github.com/Tabtii/AniApp/tree/feature/anime-companion/mobile) · [Development PR](https://github.com/Tabtii/AniApp/pull/1) · [Coverage and release status](https://github.com/Tabtii/AniApp/blob/feature/anime-companion/docs/RELEASE_READINESS.md)

> The current Flutter app lives on **`feature/anime-companion`**, in PR #1. The `master` branch still contains the original Kotlin application. Use the development branch to build or explore the current app.

## New in 0.5.0

Conflict-aware multi-device progress, safe undo, local-first startup, watchlist
search/sorting/direct count editing, focused detail sections and tablet navigation.
Personal news filters now run before the result limit. This version requires the
new additive database migration before distribution. It was applied and verified
on the connected AniApp backend on 13 October 2026; builds do not apply migrations.
See [implementation, validation and rollout](docs/COMPANION_0_5.md).

## Companion features from 0.4.0

Personal **Today** screen, offline-first progress with retry, MAL XML / AniApp JSON
import, list/account export, confirmed-calendar ICS export, provider filters,
source muting and optional hidden news previews. Follow DE/EN dubs for **in-app**
announcement/date-change messages. An authenticated reviewer queue verifies
ambiguous announcements and preserves audit history.

**Data rights:** Anime2You granted written permission on 14 October 2026 and
Tenrai permits API-service use without licensing the underlying content. Further
enquiries (12 and 15 October) are open; see the rights register for the current
list. No blanket commercial approval is claimed. Sources without permission stay
disabled, and any source can be switched off through the source register.
[Rights register](https://github.com/Tabtii/AniApp/blob/feature/anime-companion/docs/DATA_RIGHTS.md) · [Implementation and remaining gates](https://github.com/Tabtii/AniApp/blob/feature/anime-companion/docs/COMPANION_0_4.md)

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
| News | Anime2You, MyAnimeList via Tenrai, ADN News, official Crunchyroll DE/EN RSS (AniNews switched off until permission) | Publisher meta-descriptions for Anime2You; short previews and original links for other sources |
| Dub announcements | Supported Crunchyroll RSS, ADN and Anime2You formats (AniNews parser kept, ingestion off until permission) | Explicit, sufficiently evidenced DE/EN premiere or episode dates |
| Dub existence | MyDubList | Evidence that a dub exists; not proof of a local provider offer or release date |

Netflix, aniverse and other providers may appear in supported news reports. This is **not** a comprehensive direct integration with every provider. TMDb and AniList adapters exist but are not active: TMDb needs a project-specific API credential; AniList additionally requires usage authorization.

## Try it on Android

1. Open the latest successful [Android workflow run](https://github.com/Tabtii/AniApp/actions/workflows/flutter.yml) for `feature/anime-companion`, then download its `aniapp-android-debug` artifact. GitHub sign-in may be required.
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

As of **13 October 2026**, the project has 54 passing Flutter tests, 64 passing backend tests and 6 passing Python tests. CI checks the app and backend, builds an Android debug APK and builds the iOS simulator app. Test fixtures are not production content.

## Before a public release

- Expand provider/region coverage and review unresolved announcement formats and title mappings.
- Configure an owned SMTP sender and verify registration, email confirmation, recovery and app links on real devices.
- Complete privacy/contact information and physical-device acceptance of the implemented account deletion/export, accessibility and offline behavior.
- Obtain outstanding data permissions and configure/test Firebase/APNs before enabling device push.
- Prepare signed Android/iOS releases and store distribution.

See [release readiness](https://github.com/Tabtii/AniApp/blob/feature/anime-companion/docs/RELEASE_READINESS.md) for the verified status and remaining work.

## Original Kotlin project

AniApp began as **AniMe**, an Android training project for Syntax Institute. The Kotlin implementation and its 2023 screenshots are preserved as historical reference; those screenshots do not represent the current Flutter interface.

[Original project description and screenshots](https://github.com/Tabtii/AniApp/blob/559de9b49e0fa029213c5a3f789452ab357e6c33/README.md)

## License

See [LICENSE](https://github.com/Tabtii/AniApp/blob/master/LICENSE).


### Anime2You permission update (14 October 2026)

Anime2You has approved the described AniApp feed/news/calendar use without fees.
Its feed is checked every 15 minutes; previews use original publisher metadata,
corrections replace existing entries, and news/source-text caches expire after
30 days. Images retain publisher links and permission; the publisher explicitly
cannot grant third-party artwork rights. See [data rights](docs/DATA_RIGHTS.md).
This is a backend update compatible with the existing AniApp 0.5 Android build.
