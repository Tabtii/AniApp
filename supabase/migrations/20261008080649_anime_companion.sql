-- Shared Android/iOS data model. Public content is published only after review.
create table public.watchlist (
  user_id uuid not null references auth.users(id) on delete cascade,
  mal_id bigint not null check (mal_id > 0),
  anime_snapshot jsonb not null check (jsonb_typeof(anime_snapshot) = 'object' and anime_snapshot ? 'id' and (anime_snapshot->>'id')::bigint = mal_id),
  status text not null default 'planned' check (status in ('planned','watching','completed','paused','dropped')),
  watched_episodes integer not null default 0 check (watched_episodes between 0 and 1000000),
  primary key (user_id, mal_id)
);
alter table public.watchlist enable row level security;
create policy own_watchlist on public.watchlist for all to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
grant select, insert, update, delete on public.watchlist to authenticated;

create table public.anime_sources (
  mal_id bigint not null check (mal_id > 0),
  provider text not null check (provider in ('myanimelist','jikan','tmdb','imdb','streaming_availability')),
  external_id text not null,
  verified boolean not null default false,
  checked_at timestamptz not null default now(),
  primary key (provider, external_id),
  unique (mal_id, provider)
);
alter table public.anime_sources enable row level security;
create policy verified_sources on public.anime_sources for select to anon, authenticated using (verified);
grant select on public.anime_sources to anon, authenticated;

create table public.news (
  id uuid primary key default gen_random_uuid(),
  mal_id bigint check (mal_id > 0),
  headline text not null check (length(headline) between 1 and 250),
  summary text not null check (length(summary) between 1 and 1500),
  category text not null check (category in ('season','dub','streaming','announcement')),
  source_name text not null,
  source_url text not null unique check (source_url like 'https://%'),
  published_at timestamptz,
  checked_at timestamptz not null default now(),
  published boolean not null default false
);
alter table public.news enable row level security;
create policy published_news on public.news for select to anon, authenticated using (published);
grant select on public.news to anon, authenticated;
create index news_published_at on public.news (published_at desc) where published;

create table public.release_events (
  id uuid primary key default gen_random_uuid(),
  mal_id bigint not null check (mal_id > 0),
  title text not null,
  episode integer check (episode > 0),
  kind text not null check (kind in ('japan','streaming','dub')),
  starts_at timestamptz,
  provider text not null,
  region text not null check (region ~ '^[A-Z]{2}$'),
  audio_language text check (audio_language ~ '^[a-z]{2,3}$'),
  status text not null check (status in ('confirmed','estimated','announced','delayed')),
  source_url text not null check (source_url like 'https://%'),
  checked_at timestamptz not null default now(),
  published boolean not null default false,
  check (kind <> 'dub' or audio_language is not null),
  check (status not in ('confirmed','estimated') or starts_at is not null),
  unique nulls not distinct (mal_id, episode, kind, provider, region, audio_language, source_url)
);
alter table public.release_events enable row level security;
create policy published_releases on public.release_events for select to anon, authenticated using (published);
grant select on public.release_events to anon, authenticated;
create index releases_region_time on public.release_events (region, starts_at) where published;
create index releases_anime on public.release_events (mal_id, starts_at) where published;

create table public.availability (
  id uuid primary key default gen_random_uuid(),
  mal_id bigint not null check (mal_id > 0),
  provider text not null,
  region text not null check (region ~ '^[A-Z]{2}$'),
  scope text not null check (scope in ('series','season','episode')),
  season_number integer check (season_number > 0),
  episode integer check (episode > 0),
  audio_languages text[], -- null means unknown, never infer from provider or country.
  subtitle_languages text[],
  status text not null check (status in ('available','announced')),
  watch_url text check (watch_url like 'https://%'),
  source_url text not null check (source_url like 'https://%'),
  checked_at timestamptz not null default now(),
  published boolean not null default false,
  check (scope <> 'episode' or episode is not null),
  check (scope <> 'season' or season_number is not null),
  unique nulls not distinct (mal_id, provider, region, scope, season_number, episode, source_url)
);
alter table public.availability enable row level security;
create policy published_availability on public.availability for select to anon, authenticated using (published);
grant select on public.availability to anon, authenticated;
create index availability_anime_region on public.availability (mal_id, region) where published;

-- Privileged imports run only in trusted server tooling, not in the app.
grant all on public.news, public.release_events, public.availability, public.anime_sources, public.watchlist to service_role;
