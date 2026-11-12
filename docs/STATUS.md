# AniApp – current status

**As of 23 October 2026.** This page is the single current overview. Older
release notes (`COMPANION_0_4.md`, `COMPANION_0_5.md`) describe the state at
their release and are kept for history.

AniApp is run as a non-commercial passion project without planned revenue (see
"Monetarisierung" in `DATA_RIGHTS.md`).

## Code and branches

| Item | State |
| --- | --- |
| App version | `0.5.2+17` in the repository (Flutter, Android + iOS, DE/EN); the Play test runs `0.5.0+15` until a newer bundle is uploaded (a signed `0.5.1+16` bundle was built on 10 Nov) |
| Development branch | `master`. `feature/anime-companion` is kept only because app builds up to 0.5.1 link the privacy notice there |
| Merged since 0.5 | Anime2You permission and retention (#3), source kill switch, AniNews off and migration history alignment (#4), privacy policy and support links (#5), watchlist pagination (#6), source monitoring (#7), status docs (#8), advisor migration (#9), AppStore split (#10), offline news/calendar cache (#11), inbox count/paging (#12), dub retry timing (#21), Android upload-key signing and release workflow (#22), privacy notice with controller, DPA and STRATO details (#23–#25, #28, #29), auth email templates DE/EN (#26, #27), ADN permission (#31) |
| Google Play | `0.5.0+15` (bundle uploaded 21 Oct) is available to testers in the closed test track "Alpha" (full roll-out, 3 countries/regions, Play Console 23 Oct); no production release yet |
| Release to `master` | Open: PR #1 is a draft; `master` still holds the original Kotlin app |

## Live backend (Supabase, Frankfurt)

| Function | Version | Notes |
| --- | --- | --- |
| `content-sync` | 22 | Hourly import, Anime2You every 15 minutes, register kill switch, import health in `source_status`, removed articles leave observation, dub retries run up to two minutes early |
| `catalog` | 6 | Kill switch; tells the app not to fall back when Tenrai is blocked |
| `anime-enrichment` | 8 | Kill switch for Kitsu, TMDb, MyDubList, AniList, Wikidata, Wikipedia, ANN; German Wikipedia and ANN encyclopedia descriptions via Wikidata (deployed 5 Nov; shown by the app from the next release) |
| `companion-account` | 4 | Export, deletion (incl. reviewer invitation), reviewer queue |

- Migrations: repository and live history use the same versions, all applied
  (last: `20261015090000_security_advisor_fixes`). Do not apply them again.
  The only open security advisor finding is leaked-password protection (owner decision).
- Any source can be switched off by setting `source_rights.status = 'blocked'`
  (see `DATA_RIGHTS.md`).

## Sources and permissions

- **Approved and enabled in `source_rights`:** Anime2You (written permission 14 Oct), Anime News Network (written permission 15 Oct; feed only, max. one request per minute), ADN calendar and News (written permission 22 Oct from its CTO, register set to `approved` the same day; images allowed, commercial use not covered), MyDubList (CC BY 4.0).
- **Running under review in the test phase:** Kitsu. The catalog uses the official MAL API (register `jikan` approved: app registered as non-commercial, `MAL_CLIENT_ID` set) with Tenrai as fallback.
- **Switched off 12 Nov:** Crunchyroll DE/EN (`cr_de`, `cr_en` blocked) after three unanswered enquiries.
- **Public terms, live in the backend since 5 Nov:** ANN encyclopedia (credit and link), German Wikipedia (CC BY-SA 4.0), Wikidata (CC0) for descriptions; `wikidata` and `wikipedia` are in the register since 12 Nov. The current app build ignores them; the next release shows them.
- **Running on public non-commercial terms:** TMDb (register `tmdb` approved 12 Nov; German descriptions and streaming offers; token set 27 Oct, attribution on the Sources screen). Valid only while the project stays non-commercial.
- **Off until permission:** AniNews, AniList, HIDIVE, Netflix, Joyn, AnimeSchedule.
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
| P0 | Upload the newest bundle (`0.5.1+16`: header language sheet, Wikipedia/ANN descriptions; `0.5.2+17` adds the clearer Today line, feedback by email and the privacy link on `master`) to the closed test; this restarts the review. Invite testers and collect feedback |
| P0 | Paste the remaining email templates into Supabase and test registration end to end |
| P1 | Physical Android/iPhone acceptance; TestFlight |
| P1 | Decide on leaked-password protection (only remaining security advisor finding) |
| P2 | Ask TMDb to confirm that the personal/non-commercial key covers a free app distributed to testers; wait for the remaining publisher answers |
| P2 | Push notifications, further sources |
