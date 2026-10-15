-- A publisher may announce a day without announcing a time. Keep that precision.
alter table public.release_events
  add column starts_on date,
  add column release_note text check (release_note is null or length(release_note) <= 500);
alter table public.release_events drop constraint release_events_check1;
alter table public.release_events add constraint release_events_confirmed_date
  check (status not in ('confirmed','estimated') or starts_at is not null or starts_on is not null);
alter table public.release_events add constraint release_events_date_precision
  check (starts_at is null or starts_on is null);
