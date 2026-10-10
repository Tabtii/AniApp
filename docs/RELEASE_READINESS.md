# Product readiness — 10 October 2026

AniApp 0.3.6 is a functioning Android/iOS companion with live content, but is not yet a complete public store release. A successful debug or simulator build does not verify email delivery, physical-device behavior or full provider coverage.

## Where the data comes from

| Content | Active source | Coverage and precision |
| --- | --- | --- |
| Search and seasonal catalog | Tenrai / MyAnimeList | MAL IDs, titles, covers and catalog data. Both share the MAL catalog. |
| Additional detail metadata | Kitsu public API | Independent detail metadata, original dates, episode totals and trailers; not German streaming dates. |
| Regular Japanese broadcasts | Tenrai / MyAnimeList schedules | Calculated weekly estimates, all currently airing seasons. No invented episode numbers. Reviewed pauses take precedence. |
| Provider episode dates | Official ADN calendar | Exact provided episode/language/time for reviewed show+season identities. Now 14 mapped titles, including older catalog additions. Unknown matches are excluded. |
| Other provider and dub announcements | Automatic DE/EN announcement importer; prior reviewed sources retained | Recognized Crunchyroll RSS, ADN cards and explicit Anime2You/AniNews claims are reconciled hourly. Unsupported/ambiguous articles require review. Partial provider/region coverage. |
| Dub existence | MyDubList | DE/EN/FR/ES/IT observations; no inferred provider, country or dub premiere. |
| News and previews | Anime2You, MyAnimeList via Tenrai, ADN News, AniNews, official Crunchyroll DE/EN RSS | Hourly feed checks; bounded excerpts and original source links. News metadata caches remain daily; separate dub watchers revisit article bodies every six hours. |

The additional ADN matches checked on 9 October: Utena (TV MAL 440; movie 441), Madoka Magica Movie 1 (11977), Yuusanchi! from Yuu-hachi (64717). Official ADN titles, type and descriptions were compared against MAL catalog entries. A same-name Dreamland movie is not the French ADN series; the matching title alone is insufficient. Chiikawa provider season numbering remains unverified. Adult/absent entries and a promotional clip were not treated as the missing TV series.

## Additional sources researched again

| Source | Result of actual check | Decision |
| --- | --- | --- |
| [AnimeSchedule API](https://animeschedule.net/api/v3/documentation) | Documented API requires an account/application bearer token. Its internal public endpoints are explicitly not the developer API. [RSS](https://animeschedule.net/rss) exists but requests here returned 403. | Useful candidate after obtaining an own app token and verifying languages/territories; not active and no access workaround. |
| [Crunchyroll calendar](https://www.crunchyroll.com/de/simulcastcalendar) | HTTP 200 but this public response contained no actual episode cards. German interface does not establish German audio or country availability. | Keep official announcements; don't import the empty response as a complete calendar. |
| [AniNews calendar](https://www.aninews.de/simulcast-kalender) | Public embedded WoAni weekly response for 5–11 October returned seven empty days. | Not a dependable live calendar in this check. Its separate news RSS and article metadata worked. |
| [AnimeRadar calendar](https://www.animeradar.de/kalender) | Public page lists episode times, but does not establish independent DACH provider/audio coverage or a documented reusable API. | Useful comparison/source link, not a provider availability feed. No reuse of embedded credentials. |
| [KSM / aniverse](https://ksm-anime.de/) | Publisher homepage returned 502 here. | Existing reviewed announcements stay; no claim of live automatic provider coverage. |
| [AnimeNachrichten old calendar](https://www.animenachrichten.de/simulcast-kalender) | Returned a spring 2021 calendar. | Excluded as stale. |
| TMDb / JustWatch | Adapter already present; own server credential still needed. | Provides regional offers, not verified German episode/dub times. |
| AniList | Existing adapter remains gated pending provider usage permission. | Do not activate merely to increase apparent coverage. |

## Login upgrade

Separate login/registration modes, AniApp brand treatment, password visibility, autofill, field validation and confirmation, accessible errors and a keyboard-friendly scrolling layout. Password recovery sends a link to the configured application callback and opens the new-password form on the Supabase passwordRecovery event. Controllers remain owned by dialog State through dismissal animations. Passwords are not stored in preferences or logged. No OAuth button is shown for an unconfigured provider.

Live public auth settings on 9 October show email enabled, signup enabled and email confirmation required; social providers disabled. This read does not prove SMTP delivery. The previously identified custom SMTP setup and a real signup/confirmation/recovery test remain outstanding. No real user emails were sent during automated testing.

## Verification for 0.3.5

34 Flutter tests, 42 backend tests and 6 Python tests pass locally. Flutter analysis, formatting and the AniNews TypeScript check pass. The new auth tests cover validation, recovery requests/callbacks, error/retry behavior, dismissal during an in-flight request and small screens with large text and keyboard insets. Actual Flutter login/registration widgets were also visually checked in the production dark/light themes; this is not a physical-device email-link test.

Deployed content-sync v6 completed all six source checks: 25 Anime2You records, 15 MAL news records, 88 weekly broadcast estimates, 60 ADN episode/catalog records across 12 days, eight cached ADN News articles and eight new AniNews articles. Public-key reads confirmed all eight AniNews previews and image URLs. ADN public reads include an additional previously reviewed, date-only dub announcement; these are distinct from the 60 calendar records. Counts are a snapshot, not a guarantee of complete catalog coverage.

## Required before a public release

1. Configure an owned SMTP sender and allowed app redirect; verify signup, confirmation, recovery and cold-start app links on Android and iOS with controlled test accounts. Do not disable email verification to hide a delivery problem.
2. Obtain own TMDb credentials and, if chosen, an AnimeSchedule app token; verify actual DACH/language coverage before claiming it. AniList additionally needs usage authorization.
3. Complete provider coverage and ongoing mapping review. A missing or blocked source is unknown, not evidence of no releases. No scraper can infer an unannounced German dub date.
4. Verify account deletion/data export and publish an appropriate privacy policy/contact/support flow before accepting public accounts. Existing Firebase identities have not been migrated.
5. Physical-device accessibility/offline/background-link testing, signed Android release, Apple developer signing/device build and store submission details. Current artifacts are debug/simulator builds.

These are concrete remaining release gates, not features claimed as finished. No paid subscriptions, account creation or terms acceptance was performed for new services.

## German / English launch scope — 10 October 2026 (0.3.6+13)

The mobile UI now uses Flutter ARB localization resources for German and English,
including login, validation, source credits, watchlists, calendar and detail pages.
The initial UI follows the device language (German, otherwise English); users can
choose either language explicitly or return to the device setting. iOS declares
both supported localizations.

Preferences are independent and persisted on the device:
- **App language:** device / German / English.
- **News language:** follow app / German / English / both. The Supabase language
  filter is applied before the 40-item limit. An already mounted news screen
  reloads when its effective language filter changes.
- **Dub audio:** German, English or both; at least one remains selected. Existing
  German/English audio preferences are migrated. Unsupported earlier preferences
  fall back to the initial UI language. UI changes do not change saved audio choices.
- **Country:** Germany, Austria, Switzerland, US or UK, independent of language.
  Selecting a country does not imply that all providers have verified coverage.
- **Calendar:** original/streaming releases plus selected dubs, or selected dubs
  only. Japanese broadcasts stay independent of country; local provider releases
  must match the selected country. Detail pages show separate dub evidence and
  announcements for each selected audio language.

Original news articles, synopses and source notes retain their source language;
AniApp does not generate translations or invent local release dates. The existing
language update left hourly ingestion unchanged. The automatic announcement importer
added later on 10 October is described below; full Netflix/aniverse direct coverage
is not implied.

Validation for this language update: all 40 Flutter tests pass locally and Flutter
analysis reports no issues. New tests cover device-language fallback, live locale
changes, preference persistence/migration, filtering before the news limit,
multiple dub languages with country isolation, immediate news reloads and a
320px English profile with enlarged text. The app wordmark now scales down when
needed to avoid a narrow-screen overflow. Read-only requests with the app's public
key verified German/English news filtering and combined calendar filters against
live Supabase data. Android/iOS artifacts are verified separately in CI.

The enrichment gateway now accepts GB as well as DE/AT/CH/US, matching all mobile
country choices. Its existing publishable-key authentication is retained. All
43 backend tests pass, including a DE/EN × country validation check.

## Automatic dub calendar import — live, 10 October 2026

Content-sync **v8** and the `automatic_dub_announcements` migration are deployed.
The existing hourly `15 * * * *` job is active. The first live import published a
new German YAIBA: Samurai Legend premiere (MAL 58812, ProSieben MAXX, 5 November)
and adopted/refreshed the existing German Dragon Hatchling premiere (MAL 61207,
ADN, 22 October) without creating a duplicate. Dates are day-precise, not invented
timestamps. Both rows were verified through the same public API used by Flutter.
No new APK is needed to receive this server-side feature.

The next run completed at **2026-10-10 09:04:10 UTC** with all seven adapters
successful: existing live catalog/calendar sources retained, 50 German and 50
English official Crunchyroll news previews, eight checked announcement documents,
seven conservative review candidates and no newly published dates in that run.
That is a real snapshot, not mock data or a completeness claim. The RSS adapter
was corrected to subscribe directly to the publisher's official RSS paths; the
API host's unrelated `/robots.txt` path is not a public resource. Website article
crawling retains robots checks and stops on access/rate-limit errors.

Two older saved Crunchyroll articles currently lack readable article metadata/body
and remain marked unavailable in the watch table. They are retried, not treated
as cancellations or silently assigned dates. Unsupported language/region/season
claims and conflicts remain in the private review queue. Explicit EN-region
publication is covered by tests; no new EN release date was present in this live
snapshot. Direct comprehensive Netflix/aniverse coverage remains outstanding.

Validation: **57 backend tests** and **6 Python tests**, strict TypeScript checking
for the new modules, and clean whitespace checks. Tests cover DE/EN/territories,
real calendar date parsing, TBA, explicit episodes/batches, continuing seasons,
wrong-season/ambiguous matches, scope isolation, duplicate/corrected dates,
source conflicts, manual-row adoption, precise provider timestamps, transaction
rollback, feed disappearance, conditional requests and outages. Public requests
can read published dates but cannot read the candidate/watch tables. Security
advisors report no new warnings; the pre-existing
[pg_net namespace](https://supabase.com/docs/guides/database/database-linter?lint=0014_extension_in_public)
and [leaked-password protection](https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection)
notices remain unchanged. Mobile code/version is unchanged by this server update.
