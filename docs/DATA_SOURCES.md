# Enrichment sources (0.3.3)

`anime-enrichment` is a read-only Edge Function. The mobile app calls it with a MAL ID, selected country and language; the project publishable key is required. It has bounded requests, timeouts, input validation, in-flight request coalescing and isolate-local caches/quotas. There are no new tables, no service-role client operations, and no edits to users' watchlists.

## MyDubList — active without a key

Source: <https://github.com/Joelis57/MyDubList>. Reads the public `dubs/confidence/normal/dubbed_<language>.json` datasets for German, English, French, Spanish and Italian. These contain entries supported by at least two automatic sources **or manually curated entries**, plus a separate partial-dub list. The original Japanese-language selection does not imply that a dub dataset exists.

Data is cached for 24 hours per function instance. The app displays the fetch time, not a fabricated source verification date. Missing IDs are **unknown**; network or format errors are **unavailable**. A dub observation never supplies a streaming provider, country, episode number or release time. It does not generate calendar events or turn a TMDb provider into a German-language provider.

CC BY 4.0 attribution, license link and the filtering/translation changes are displayed in Profile → Datenquellen & Hinweise and the detail panel links to MyDubList. Original datasets are fetched, not bundled in the APK.

## TMDb / JustWatch — requires own API credential

Set **either** `TMDB_READ_ACCESS_TOKEN` (preferred) **or** `TMDB_API_KEY` in the AniApp Supabase project's Edge Function secrets. Never put either in Flutter defines, public config or Git. Without a credential the adapter reports `unconfigured`; no API request is made and existing content keeps working.

- Uses <https://github.com/Fribb/anime-lists> solely for exact MAL → TMDb ID mappings. Mapping data is cached for 24 hours; conflicting IDs, ambiguous multi-movie mappings and unsupported media types are excluded. The mapping source is linked in the UI; these are community mappings, not manually verified identities.
- Explicit film, series and season routes. If a known season request fails or has no regional offers, the adapter does **not** copy offers from a different season or the whole series. Unknown seasons use series-level availability and are labelled accordingly. Episode coverage still requires provider verification.
- Returns Abo, Kostenlos, Mit Werbung, Leihen and Kaufen separately. Audio/subtitles remain unknown. No date is inferred from provider availability.
- German descriptions are loaded from the same mapped film/series/season, with the existing catalog description retained if absent.
- Regional results are cached for one hour. Links lead to the TMDb watch page; no direct provider URLs are invented. Attribution names JustWatch and TMDb, including TMDb's required notice and approved logo in the credits. `mobile/assets/tmdb-logo.png` is an unchanged, proportionally rasterized official blue-short logo from <https://www.themoviedb.org/about/logos-attribution>.

TMDb documents free non-commercial use with attribution; commercial use requires a separate arrangement. See <https://developer.themoviedb.org/docs/faq> and <https://developer.themoviedb.org/reference/tv-season-watch-providers>.

## AniList — implemented, awaiting usage clarification/permission

The current <https://docs.anilist.co/guide/terms-of-use> prohibits competing, non-complementary anime list/tracker services, including media data. AniApp includes tracking, so **do not activate the adapter until AniList has authorized this use**. The user authorizing app development is not provider permission. Once permission is obtained, set `ANILIST_USAGE_APPROVED=true` server-side. No API key is needed for the public queries; no AniList account/list mutations are performed.

Prepared functionality:

- On-demand media lookup by exact `idMal`, banner and next episode, with explicit AniList source link.
- A rolling seven-day airing calendar without a season filter, so ongoing older shows are included. Bounded pagination; incomplete/error responses do not replace the existing calendar.
- Japanese episode events stay separate from local streaming and German dubs. Unmapped MAL IDs, adult media and past events are excluded; episode numbers are taken from the source.
- Existing estimated Tenrai weekly entries for a covered title are replaced in the display only; provider/dub events and uncovered shows are retained. No AniList catalog or schedules are persisted in the database.
- 15-minute transient cache; 2.2-second request spacing and `Retry-After` cooldown per isolate. Shared durable quotas are needed before high-traffic deployment; per-isolate throttling is not a distributed rate-limit guarantee. The app's optional calendar request has an eight-second budget, preserving the existing calendar on a cold/slow AniList response.

## Deployment and validation

Deploy `supabase/functions/anime-enrichment/index.ts` with its `deno.json`, `providers.ts`, and `../catalog/auth.ts`. JWT gateway verification is disabled only because the function validates the project's publishable key itself, matching `catalog`. This function cannot read or mutate private database rows.

Tests cover ID/season/region separation, language uncertainty, outages, attribution, AniList approval gating, cooldown and calendar merging. Fixtures are test-only. MyDubList can be smoke-tested live immediately; TMDb and AniList require the prerequisites above before a real upstream smoke test can be claimed.

2026-10-08 live check: the deployed gateway returned HTTP 200 and sourced `available` observations for Frieren (MAL 52991, German), One Piece (MAL 21, English and French). It reported TMDb `unconfigured` and AniList `approval_required`; their live integrations are **not active**. Missing project keys returned 401; invalid regions returned 400. No production mock content was inserted.
