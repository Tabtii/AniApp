# AniApp – current status

**As of 23 October 2026.** This page is the single current overview. Older
release notes (`COMPANION_0_4.md`, `COMPANION_0_5.md`) describe the state at
their release and are kept for history.

AniApp is run as a non-commercial passion project without planned revenue (see
"Monetarisierung" in `DATA_RIGHTS.md`).

## Code and branches

| Item | State |
| --- | --- |
| App version | `0.5.0+15` (Flutter, Android + iOS, DE/EN) |
| Development branch | `feature/anime-companion`; `master` still holds the original Kotlin app |
| Merged since 0.5 | Anime2You permission and retention (#3), source kill switch, AniNews off and migration history alignment (#4), privacy policy and support links (#5), watchlist pagination (#6), source monitoring (#7), status docs (#8), advisor migration (#9), AppStore split (#10), offline news/calendar cache (#11), inbox count/paging (#12), dub retry timing (#21), Android upload-key signing and release workflow (#22), privacy notice with controller, DPA and STRATO details (#23–#25, #28, #29), auth email templates DE/EN (#26, #27), ADN permission (#31) |
| Google Play | `0.5.0+15` (bundle uploaded 21 Oct) is available to testers in the closed test track "Alpha" (full roll-out, 3 countries/regions, Play Console 23 Oct); no production release yet |
| Release to `master` | Open: PR #1 is a draft; `master` still holds the original Kotlin app |

## Live backend (Supabase, Frankfurt)

| Function | Version | Notes |
| --- | --- | --- |
| `content-sync` | 20 | Hourly import, Anime2You every 15 minutes, register kill switch, import health in `source_status`, removed articles leave observation, dub retries run up to two minutes early |
| `catalog` | 4 | Kill switch; tells the app not to fall back when Tenrai is blocked |
| `anime-enrichment` | 5 | Kill switch for Kitsu, TMDb, MyDubList, AniList |
| `companion-account` | 2 | Export, deletion (incl. reviewer invitation), reviewer queue |

- Migrations: repository and live history use the same versions, all applied
  (last: `20261015090000_security_advisor_fixes`). Do not apply them again.
  The only open security advisor finding is leaked-password protection (owner decision).
- Any source can be switched off by setting `source_rights.status = 'blocked'`
  (see `DATA_RIGHTS.md`).

## Sources and permissions

- **Approved and enabled in `source_rights`:** Anime2You (written permission 14 Oct), Anime News Network (written permission 15 Oct; feed only, max. one request per minute), ADN calendar and News (written permission 22 Oct from its CTO, register set to `approved` the same day; images allowed, commercial use not covered), MyDubList (CC BY 4.0).
- **Running under review in the test phase:** Crunchyroll DE/EN, Kitsu. The catalog uses the official MAL API (app registered as non-commercial, `MAL_CLIENT_ID` set) with Tenrai as fallback.
- **Off until permission:** AniNews, AniList, TMDb, HIDIVE, Netflix, Joyn, AnimeSchedule.
- **Open enquiries:** first round 12 Oct (AniList, TMDb, AniNews, MyAnimeList);
  second round 15 Oct (Crunchyroll; ANN, Anime UK News, Anime Corner,
  LiveChart.me, aniSearch, AnimeNachrichten); follow-ups on 16 Oct. MyAnimeList
  answered on 21 Oct without an individual permission and pointed to the app
  registration at `myanimelist.net/apiconfig`, which is done (non-commercial).
  No answer means no use.

## Data protection and accounts

- `PRIVACY.md` (DE/EN) reflects the actual data flow and names the controller,
  contact (`info@tabtisworld.de`) and minimum age (16). The Supabase DPA is part
  of its terms; the STRATO data-processing agreement is concluded. No
  placeholders remain.
- Auth mails are sent through STRATO SMTP (sender `info@tabtisworld.de`); a
  password-reset mail was delivered in a real test. The bilingual templates in
  `docs/email-templates/` still have to be pasted into Supabase for each type
  (reset is done). Registration and the other mails still need an end-to-end
  test on devices.

## Next priorities

| Priority | Item |
| --- | --- |
| P0 | Run the closed test: invite testers, collect feedback on `0.5.0+15`; a new release in the same track would restart the review, so batch fixes |
| P0 | Paste the remaining email templates into Supabase and test registration end to end |
| P1 | Physical Android/iPhone acceptance; TestFlight |
| P1 | Decide on leaked-password protection (only remaining security advisor finding) |
| P2 | German descriptions: set `TMDB_READ_ACCESS_TOKEN` (TMDb, non-commercial); wait for the remaining publisher answers |
| P2 | Push notifications, further sources |
