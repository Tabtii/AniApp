# AniApp 0.5.0 — reliability and everyday use

> **Historical release notes.** This page describes the state at this release. For the current state see [STATUS.md](STATUS.md).

This change targets `feature/anime-companion`, the current Flutter application.
The original Kotlin app on `master` is not the implementation base.

## Changed behavior

| Area | Result | Main files |
| --- | --- | --- |
| Multi-device watchlist | Each change compares an opaque server revision. A stale device keeps its local edit and displays the cloud version for an explicit choice. Successful retries are idempotent, including deletion; revision UUIDs protect delete/recreate cycles. | `mobile/lib/data/app_store.dart`, `mobile/lib/models/watch_sync.dart`, `supabase/migrations/20261013164647_watchlist_conflict_guard.sql` |
| Local progress | New taps are computed from the current entry, and edits/server acknowledgements share a disk-write queue. Undo applies only to the latest edit on the same account; it cannot overwrite a later status/progress change. | `app_store.dart`, `mobile/lib/ui/watch_actions.dart` |
| Startup | The first screen uses local state while cloud synchronisation continues in the background. Other navigation pages mount on first visit and retain their state afterwards. | `mobile/lib/main.dart`, `mobile/lib/ui/shell.dart` |
| Today | Shorter header, continue-watching controls, explicit pending/conflict state, and reloads when account, calendar mode or watchlist membership changes. Progress-only changes do not reload news. | `mobile/lib/ui/home_screen.dart` |
| Watchlist | Title search, status filters and sorting by recent changes, title or episode count. Count editing, minus/plus and status/removal actions share one component across list, home and details. The server records update time for the recent sort. | `mobile/lib/ui/watchlist_screen.dart`, `watch_actions.dart` |
| Details | Separate Overview, Episodes & Dubs and Providers sections; wrapping titles and progress controls. Provider evidence and original source links remain available. | `mobile/lib/ui/detail_screen.dart` |
| News | Language, territory, provider, muted sources and personal title IDs are filtered in SQL before limiting to 120 results. An empty personal list yields an empty personal feed. | `app_store.dart`, migration's `companion_news` function |
| Adaptive layout | Bottom navigation on phones, side rail from 720 logical pixels, bounded content width, larger small-text styles and shared light/dark theme. Header inbox badge refreshes on resume and read actions; account changes discard the old inbox snapshot. | `mobile/lib/ui/shell.dart`, `app_theme.dart`, `companion_screens.dart`, `visuals.dart`, `content_screens.dart` |

## Validation

- Flutter analysis and formatting; full existing and new Flutter tests.
- Interaction tests at 320 × 740 with 1.8× text, 390 × 844, and 1024 × 900 in dark mode. Tests exercise navigation, list search, increment/undo, exact count editing and detail sections.
- Sync tests cover two devices, durable conflicts after restart, choosing local/cloud, delayed server acknowledgements, account changes and nonblocking startup.
- Database tests exercise invoker/RLS ownership, anonymous rejection, stale revisions, intentional resets, deletion/recreation, legacy writes, retries, and filtering personal news behind more than 120 unrelated results.
- GitHub Actions runs Android debug and iOS simulator builds, backend tests and Python checks. Actual run status is recorded on the pull request.

Optional reproducible UI captures use `ANIAPP_PREVIEW_DIR` with `flutter test test/ux_test.dart`. To render readable fonts, set `ANIAPP_FONT_DIR` to Flutter's `bin/cache/artifacts/material_fonts`. Captures use clearly synthetic test data and fallback artwork; they do not establish live provider coverage.

## Deployment order and compatibility

1. Review and apply `20261013164647_watchlist_conflict_guard.sql` to the intended Supabase environment **before distributing 0.5**. It adds `watchlist.revision`, `watchlist.updated_at`, a revision trigger, two invoker RPC functions and a public-news index. Existing rows remain present, and existing RLS remains in force.
2. Verify authenticated `sync_watchlist` access and public `companion_news` access in that environment. Neither function bypasses RLS or needs a client secret.
3. Distribute the new Android/iOS client together. A 0.4 client can still write directly; its writes change the revision so 0.5 detects them, but the old client itself cannot detect conflicts. Full protection requires updating all active devices.
4. Existing local state/outboxes remain readable. An old pending edit without a known revision conflicts with an existing cloud row instead of silently replacing it. The user chooses the intended version.

The migration was applied to the connected **AniApp** project on **13 October 2026**, recorded by Supabase as `20261013164647_watchlist_conflict_guard`. The original prepared file (`20261013074350`) was renamed to this recorded version without changing its SQL, so it is not a second migration. Do not apply it again to this project. For a different environment, follow the deployment order above. Schema rollback is not needed to roll back the app: the additions are compatible with 0.4.

Live verification passed: invoker permissions and RLS, authenticated insert/update/idempotent retry, rejection of stale updates/deletes, valid deletion, and account isolation. All synthetic write tests ran inside a rolled-back transaction. The existing three watchlist rows retained an identical fingerprint of all original fields, and every row now has revision/update metadata. Public REST checks returned HTTP 200 for filtered news and an empty personal list; anonymous sync was rejected with HTTP 401 / SQLSTATE 42501.

The security advisor reported **no new findings**. Two pre-existing warnings remain outside this migration: [`pg_net` installed in `public`](https://supabase.com/docs/guides/database/database-linter?lint=0014_extension_in_public) and [leaked-password protection disabled](https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection). These settings were not changed. At the time of this note the app PR was unmerged; the previously successful Android/iOS builds contain the same application code.

For pre-existing rows the initial `updated_at` is migration time; historical edit ordering cannot be recovered. Future writes receive real update timestamps. The unread badge is capped at 100 fetched rows. News and calendar content still need network access; only watchlist state and pending operations are durable offline.

## Remaining priorities

| Priority | Next change | Acceptance evidence |
| --- | --- | --- |
| P1 | Physical Android/iPhone acceptance: offline/online, account switching, keyboard/safe areas, screen readers, Dynamic Type and deep links | Recorded runs on both devices; build success alone is insufficient |
| P1 | Signed Android release and iOS TestFlight distribution | Installable signed builds, owned signing credentials and successful device sign-in/recovery |
| P1 | Large-list pagination and store/repository separation | Lists above the server row cap load without truncation; sync tests retained as logic moves out of `AppStore` |
| P2 | Durable news/calendar cache with age indicators and explicit refresh behavior | Previously loaded content survives app restart without pretending stale dates are current |
| P2 | Catalog relevance/filtering and richer empty states | Search tasks measured against representative title/alias and provider/language examples |
| P2 | FCM/APNs push and source/provider expansion | Actual delivery, evidence and data permissions verified separately |

This release does not activate additional collectors, send permission enquiries,
change data-rights decisions, or claim store readiness. See `RELEASE_READINESS.md`
and `DATA_RIGHTS.md` for the remaining product gates.
