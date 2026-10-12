# AniApp 0.4.0 — implementation and operational notes

## Implemented

- **Today:** personal continue-watching cards, atomic +1 progress, undo,
  watchlist-linked upcoming releases and live news. Navigation is Today,
  Discover, Calendar, News, My List; profile is in the header.
- **Preferences:** streaming services, independent DE/EN UI/news/audio, news
  source muting, exact-ID personal news and optional hidden news images/summary.
  Hidden previews do not guarantee spoiler-free headlines.
- **Offline watchlist:** account-scoped durable local state plus operation
  outbox, local-first changes, idempotent upserts/deletions, coalesced replay,
  retry on refresh and foreground resume. Pending operations overlay remote
  snapshots. Existing device progress is never overwritten by file import.
- **Transfer:** MAL XML and AniApp JSON import with preview, validation, size/
  entry limits and duplicate handling; JSON export via native share sheet.
  Unknown/malformed entries are reported as skipped. No fuzzy series matching.
- **Calendar export:** confirmed dates only, stable event IDs/revisions,
  UTC timestamps or actual all-day dates, RFC 5545 escaping/UTF-8 folding.
  This is a file snapshot, not a live subscribed calendar; re-export after changes.
- **Dub follows:** per user, exact MAL identity, country and DE/EN audio.
  New announcements and date/status changes create a private in-app inbox;
  hourly sync adds idempotent scheduled-today/now reminders for confirmed dates.
  Older messages are marked superseded. Reaching a date never claims a live
  provider availability check. There is no FCM/APNs device push yet.
- **Editorial:** authenticated owner/reviewer queue, original-source/evidence
  display, editable verified event, approve/reject with mandatory note, stale
  review rejection and audit trail. Unchanged scraping preserves human decisions;
  changed content goes back to review. A reviewer cannot be self-assigned through
  editable profile metadata.
- **Account:** authenticated paginated data export and permanent deletion after
  a recent sign-in and explicit in-app confirmation. Watchlist, follows and inbox
  cascade with the Auth user. Reviewer audit retains decisions with a null actor.
- **Sources:** public sanitised health and permissions; four additional publisher
  collectors are implemented but require recorded permission before any fetch.

## Important limits

Offline merge policy is **last replayed absolute value wins**, not a CRDT: two
simultaneously edited devices may conflict. Only the watchlist/progress is
promised offline; news, accounts and dates require a connection. A failed disk
write reports an error and restores the preceding in-memory state. Import limits
are 2 MiB / 5,000 entries. Back up important lists before changing devices.

Provider and country preferences filter known evidence; unknown-territory global
news can remain visible. Personal news uses only exact IDs, so sparse mappings
can yield an empty personal feed. A source being reachable is not a reuse licence.

The new collectors are not a claim of comprehensive real-world coverage. They
require live revalidation after permission; a site can serve only JS, block robots,
change markup or omit metadata. They do not automatically turn headline dates
into confirmed dub events. Existing DE/EN dub parsers remain conservative.

## Reviewer provisioning

`companion_reviewers` and `companion_reviewer_invitations` are server-only.
An operator can add an exact owner email to the private invitation table. The
account edge function grants a role only after Supabase Auth verifies that email
and its confirmation timestamp. No client can read/write invitations or roles.
On 12 October 2026 the owner explicitly approved one account for persistent
review privileges: reading, editing, rejecting and publishing dub proposals.
Its invitation is configured in the private table. The account has not yet
registered; activation requires sign-up and a confirmed email matching that
invitation. No existing user has been promoted and no owner address is stored
in source control. Anonymous and authenticated clients cannot read invitations
or grant roles; the saved invitation and these restrictions were checked live.

## Deployment

Apply `companion_experience`, deploy `companion-account` and updated `content-sync`.
Both use custom authentication: verified Supabase bearer session for account
operations; existing Vault-backed sync token for the cron worker. The service-role
key remains server-only. Existing hourly cron is reused; no new paid job/provider.

Run `refresh_source_status()` after migration to initialise health/verified news
links. Source permissions are updated separately from schema migrations; record
outbound enquiries as requested, never approved. See [DATA_RIGHTS.md](DATA_RIGHTS.md).

## Still required for a public product

- Provider replies/project-specific data and image licences; commercial budget
  approval if needed. Direct MAL, Crunchyroll, ADN, Kitsu and additional publisher
  permissions remain open beyond the five dispatched enquiries.
- Firebase/APNs configuration and actual device delivery tests for OS push;
  final-season-complete notices need explicit provider evidence and a complete
  season episode mapping. Neither is inferred from catalogue episode totals.
- Apple signing/TestFlight and signed Android release distribution. CI provides
  an Android debug APK and iOS simulator validation.
- Home-screen widgets, OAuth list synchronisation, store billing, final legal
  imprint/privacy text and real-device/user acceptance sessions are later release
  work, not silently marked complete by this version.
