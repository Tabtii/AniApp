# Enrichment sources (0.3.4)

`anime-enrichment` is a read-only Edge Function. The mobile app calls it with a MAL ID, selected country and language; the project publishable key is required. It has bounded requests, timeouts, input validation, in-flight request coalescing and isolate-local caches/quotas. There are no new tables, no service-role client operations, and no edits to users' watchlists.

## Kitsu — active public detail API

The public JSON:API at <https://kitsu.app/api/edge> adds an independent source for episode totals, running time, original airing dates/status, cover/banner images, synopsis fallback and external YouTube trailer links. It needs no account/API credential. Official API reference: <https://hummingbird-me.github.io/api-docs/>.

`mappings?filter[externalSite]=myanimelist/anime&filter[externalId]=<MAL_ID>&include=item` resolves exact identities. Returned mapping IDs are checked even if upstream filters were ignored. Missing, conflicting, paginated or adult mappings are not used. Detail requests are cached for an hour per instance and fail independently of dub/streaming sources. The UI labels Kitsu and original airing dates; they do not imply local streaming availability or a German dub date. Banner failures fall back to the catalog cover: Kitsu's image CDN returned 403 to the development runner even though the data API was available. No CDN restriction is bypassed. Primary search/season discovery still uses the existing catalog gateway; Kitsu is a detail supplement, not a complete offline catalog replacement.

## Own ADN News scraper — active, no paid crawler service

`content-sync/adn-news.ts` reads <https://news.animationdigitalnetwork.com/robots.txt>, discovers German articles through `/de/feed/` (or the public German index only when the feed is missing), and fetches up to eight dated article pages. It stores only headline, a maximum 20-word preview, source image URL, article publication date, fetch time and source link in the existing `news` table. It does not copy full articles or infer anime IDs, episode dates or dub dates from a news publication date.

Only the fixed ADN News origin and dated German article paths are permitted. The scraper respects matching robots rules/crawl-delay, spaces requests by at least one second, rejects redirects, and stops on access/rate-limit responses. Each page has an eight-second timeout and 1.5 MB response limit; the total crawl budget is 45 seconds. Each article is refreshed at most once per day. Feed/metadata failures preserve previously published rows and appear in the private sync report. There is no browser login, CAPTCHA workaround, Firecrawl or additional scraping subscription. Existing Supabase quota/hosting limits still apply.

The existing hourly content-sync schedule also collects Anime2You/MyAnimeList news and provider episode data. Flutter reads the shared published news through Supabase; each phone does not crawl the publisher independently.

### Reviewed pause notices

ADN's [4 October One Piece announcement](https://news.animationdigitalnetwork.com/de/2026/10/04/warum-gibt-es-diese-woche-keine-neue-folge-one-piece/) says the series pauses after episode 1180 and does not confirm a resumption date (reviewed 8 October 2026). `reviewed-pauses.ts` suppresses this title's recurring Japanese estimate and publishes a sourced, undated `delayed` event. This is a **human-reviewed exception**, not automatic interpretation of every crawled article. Older-season shows otherwise stay in the calendar, and local dub/provider events remain separate.

When a publisher confirms resumption, remove/update the reviewed exception **and retire its exact ADN News pause row** before allowing weekly estimates again. Until then the app shows the dated source notice and an unknown return date. Never use article publication time as an episode time.

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

Deploy `supabase/functions/anime-enrichment/index.ts` with its `deno.json`, `providers.ts`, `kitsu.ts`, and `../catalog/auth.ts`. Deploy `content-sync/index.ts` with `deno.json`, `content.ts`, `adn.ts`, `adn-news.ts` and `reviewed-pauses.ts`. JWT gateway verification is disabled only because enrichment validates the project's publishable key itself, matching `catalog`; content-sync retains its private Vault-backed sync token and lease. Enrichment cannot read or mutate private database rows. No new schema or credentials are needed.

Tests cover ID/season/region separation, language uncertainty, outages, attribution, AniList approval gating, cooldown and calendar merging. Fixtures are test-only. MyDubList can be smoke-tested live immediately; TMDb and AniList require the prerequisites above before a real upstream smoke test can be claimed.

2026-10-08 live check: the deployed gateway returned HTTP 200 and sourced `available` observations for Frieren (MAL 52991, German), One Piece (MAL 21, English and French). It reported TMDb `unconfigured` and AniList `approval_required`; their live integrations are **not active**. Missing project keys returned 401; invalid regions returned 400. No production mock content was inserted.

0.3.4 live check: Kitsu returned `ok` for Frieren and One Piece. The deployed content-sync completed with eight new ADN News previews, 86 weekly Japanese estimates, one reviewed undated pause and 18 ADN provider episodes; all five source adapters succeeded. Missing ADN → MAL mappings remain excluded instead of guessed.
