-- Opaque revisions protect offline edits, including delete/recreate cycles.
-- Deploy this additive migration before distributing the 0.5 mobile build.
alter table public.watchlist add column revision uuid not null default gen_random_uuid(),
  add column updated_at timestamptz not null default now();

create function public.bump_watchlist_revision() returns trigger
language plpgsql security invoker set search_path='' as $$
begin
  new.revision := gen_random_uuid();
  new.updated_at := now();
  return new;
end;
$$;
revoke all on function public.bump_watchlist_revision() from public,anon,authenticated;
create trigger watchlist_revision before insert or update on public.watchlist
for each row execute function public.bump_watchlist_revision();

-- Invoker rights and owner predicates both apply. The row lock covers the
-- comparison and write; concurrent first inserts use the unique constraint.
create function public.sync_watchlist(p_mal_id bigint,p_expected_revision uuid,p_entry jsonb)
returns jsonb language plpgsql security invoker set search_path='' as $$
declare
  actor uuid := auth.uid();
  current_row public.watchlist;
  current_entry jsonb;
  applied boolean := false;
begin
  if actor is null then raise exception 'Authentication required' using errcode='42501'; end if;
  if p_mal_id is null or p_mal_id <= 0 then raise exception 'Invalid title'; end if;
  if p_entry is not null and (
    jsonb_typeof(p_entry) is distinct from 'object' or
    not (p_entry ?& array['anime','status','watched']) or
    (p_entry->'anime'->>'id')::bigint is distinct from p_mal_id or
    (p_entry->>'watched')::integer is null or
    p_entry->>'status' is null
  ) then raise exception 'Invalid entry'; end if;

  select * into current_row from public.watchlist
    where user_id=actor and mal_id=p_mal_id for update;
  if found then
    current_entry := jsonb_build_object('anime',current_row.anime_snapshot,
      'status',current_row.status,'watched',current_row.watched_episodes);
    if current_entry is not distinct from p_entry then
      -- Safe retry after the response to a successful write was lost.
      applied := true;
    elsif current_row.revision = p_expected_revision then
      if p_entry is null then
        delete from public.watchlist where user_id=actor and mal_id=p_mal_id;
        current_row := null;
        current_entry := null;
      else
        update public.watchlist set anime_snapshot=p_entry->'anime',
          status=p_entry->>'status',watched_episodes=(p_entry->>'watched')::integer
          where user_id=actor and mal_id=p_mal_id returning * into current_row;
        current_entry := p_entry;
      end if;
      applied := true;
    end if;
  elsif p_entry is null then
    applied := true;
  elsif p_expected_revision is null then
    insert into public.watchlist(user_id,mal_id,anime_snapshot,status,watched_episodes)
      values(actor,p_mal_id,p_entry->'anime',p_entry->>'status',(p_entry->>'watched')::integer)
      on conflict(user_id,mal_id) do nothing returning * into current_row;
    applied := found;
    if not applied then
      select * into current_row from public.watchlist where user_id=actor and mal_id=p_mal_id;
    end if;
    if current_row.revision is not null then
      current_entry := jsonb_build_object('anime',current_row.anime_snapshot,
        'status',current_row.status,'watched',current_row.watched_episodes);
    end if;
  end if;
  return jsonb_build_object('applied',applied,'revision',current_row.revision,'entry',current_entry);
end;
$$;
revoke all on function public.sync_watchlist(bigint,uuid,jsonb) from public,anon;
grant execute on function public.sync_watchlist(bigint,uuid,jsonb) to authenticated;

-- Apply all personal filters before the result limit. No account data is read
-- here: the caller supplies title IDs and all returned news remains public.
create function public.companion_news(p_languages text[],p_region text,
  p_providers text[],p_muted text[],p_ids bigint[] default null)
returns setof public.news language sql stable security invoker set search_path='' as $$
  select n.* from public.news n
  where n.published and n.language=any(p_languages)
    and not (n.source_name=any(coalesce(p_muted,'{}')))
    and (cardinality(n.regions)=0 or p_region=any(n.regions))
    and (cardinality(coalesce(p_providers,'{}'))=0 or cardinality(n.providers)=0 or n.providers && p_providers)
    and (p_ids is null or n.mal_id=any(p_ids))
  order by n.published_at desc nulls last,n.id
  limit 120;
$$;
revoke all on function public.companion_news(text[],text,text[],text[],bigint[]) from public;
grant execute on function public.companion_news(text[],text,text[],text[],bigint[]) to anon,authenticated;
create index news_title_time on public.news(mal_id,published_at desc) where published;
