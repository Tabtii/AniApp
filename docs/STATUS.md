# AniApp – current status

**As of 15 October 2026.** This page is the single current overview. Older
release notes (`COMPANION_0_4.md`, `COMPANION_0_5.md`) describe the state at
their release and are kept for history.

## Code and branches

| Item | State |
| --- | --- |
| App version | `0.5.0+15` (Flutter, Android + iOS, DE/EN) |
| Development branch | `feature/anime-companion`; `master` still holds the original Kotlin app |
| Merged since 0.5 | Anime2You permission and retention (#3), source kill switch, AniNews off and migration history alignment (#4), privacy policy and support links (#5), watchlist pagination (#6) |
| Release to `master` | Open: PR #1 is a draft; no store build yet |

## Live backend (Supabase, Frankfurt)

| Function | Version | Notes |
| --- | --- | --- |
| `content-sync` | 14 | Hourly import, Anime2You every 15 minutes, register kill switch |
| `catalog` | 4 | Kill switch; tells the app not to fall back when Tenrai is blocked |
| `anime-enrichment` | 5 | Kill switch for Kitsu, TMDb, MyDubList, AniList |
| `companion-account` | 2 | Export, deletion (incl. reviewer invitation), reviewer queue |

- Migrations: repository and live history use the same versions. Only
  `20261015060000_aninews_ingestion_off` is pending (removes 19 stored AniNews
  previews); ingestion itself is already off in code.
- Any source can be switched off by setting `source_rights.status = 'blocked'`
  (see `DATA_RIGHTS.md`).

## Sources and permissions

- **Approved:** Anime2You (written permission 14 Oct), MyDubList (CC BY 4.0).
- **Running under review in the test phase:** Tenrai/MAL, ADN, Crunchyroll DE/EN, Kitsu.
- **Off until permission:** AniNews, AniList, TMDb, HIDIVE, Netflix, Joyn, ANN, AnimeSchedule.
- **Open enquiries:** first round 12 Oct (AniList, TMDb, AniNews, MyAnimeList);
  second round 15 Oct (Crunchyroll, ADN – ticket #7775, ANN, Anime UK News,
  Anime Corner, LiveChart.me, aniSearch, AnimeNachrichten).

## Data protection and accounts

- `PRIVACY.md` (DE/EN draft) reflects the actual data flow; controller details,
  minimum age and the final support channel are placeholders.
- Own SMTP sender is not configured yet; registration and password reset still
  need an end-to-end test on devices.

## Next priorities

| Priority | Item |
| --- | --- |
| P0 | Own SMTP (e.g. Gmail app password) and end-to-end auth test; fill privacy placeholders |
| P1 | Physical Android/iPhone acceptance; signed Android release and TestFlight |
| P1 | Crunchyroll pages that left the RSS feed fail identity checks (diagnostics deployed with source monitoring) |
| P1 | Split `app_store.dart`; review Supabase security advisor warnings |
| P2 | Durable news/calendar cache, search improvements, push notifications, further sources |
