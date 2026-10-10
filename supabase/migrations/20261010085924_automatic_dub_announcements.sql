-- Server-only watch state and review queue. The mobile client only reads the
-- existing published release_events/news tables; source text is not republished.
create table public.dub_source_documents (
  source_url text primary key check (source_url like 'https://%' and length(source_url)<=2048),
  source_key text not null check (source_key in ('cr_de','cr_en','adn','anime2you','aninews')),
  headline text not null default '',
  published_at timestamptz,
  checked_at timestamptz,
  last_attempt_at timestamptz,
  next_check_at timestamptz not null default now(),
  watch_until timestamptz not null default now()+interval '180 days',
  content_hash text,
  parser_version integer,
  etag text,
  last_modified text,
  error text,
  needs_review boolean not null default false
);
create index dub_documents_due on public.dub_source_documents(next_check_at,source_url);
create table public.dub_title_matches (
  title_key text primary key,
  mal_id bigint check(mal_id>0),
  title text,
  image_url text,
  checked_at timestamptz not null default now()
);
create table public.dub_candidates (
  source_url text not null references public.dub_source_documents(source_url) on delete cascade,
  candidate_key text not null check(length(candidate_key)<=400),
  decision text not null check(decision in ('published','review','conflict','ignored')),
  reason text,
  evidence text not null check(length(evidence)<=1200),
  proposal jsonb not null check(jsonb_typeof(proposal)='object' and octet_length(proposal::text)<16000),
  event_id uuid references public.release_events(id) on delete set null,
  checked_at timestamptz not null default now(),
  primary key(source_url,candidate_key)
);
create index dub_candidates_review on public.dub_candidates(decision,checked_at) where decision in ('review','conflict');
create index dub_candidates_event on public.dub_candidates(event_id) where event_id is not null;
alter table public.dub_source_documents enable row level security;
alter table public.dub_title_matches enable row level security;
alter table public.dub_candidates enable row level security;
revoke all on public.dub_source_documents,public.dub_title_matches,public.dub_candidates from public,anon,authenticated;
grant all on public.dub_source_documents,public.dub_title_matches,public.dub_candidates to service_role;
create policy server_dub_documents on public.dub_source_documents for all to service_role using(true) with check(true);
create policy server_dub_matches on public.dub_title_matches for all to service_role using(true) with check(true);
create policy server_dub_candidates on public.dub_candidates for all to service_role using(true) with check(true);
-- Independent of date and URL: corrected dates and follow-up articles update the
-- same calendar identity. Manual/provider rows can be adopted without duplication.
alter table public.release_events add column announcement_key text unique;

create function public.apply_dub_candidates(p_source_url text,p_candidates jsonb) returns jsonb
language plpgsql security invoker set search_path='' as $$
declare
  c jsonb; e jsonb; k text; existing public.release_events%rowtype;
  event_id uuid; decision text; reason text; total integer:=0; review_count integer:=0; conflict_count integer:=0;
  identity_count integer;
begin
  if jsonb_typeof(p_candidates) is distinct from 'array' or jsonb_array_length(p_candidates)>100 then raise exception 'Invalid dub batch'; end if;
  perform 1 from public.dub_source_documents where source_url=p_source_url for update;
  if not found then raise exception 'Unknown source document'; end if;
  -- One sync normally holds the cron gate; serialize reconciliation as well to
  -- handle future separate workers safely, including across different articles.
  perform pg_advisory_xact_lock(741013);
  for c in select value from jsonb_array_elements(p_candidates) loop
    e:=c->'event'; decision:='review'; reason:=c->>'reason'; event_id:=null;
    if reason is null and e is not null and e<>'null'::jsonb then
      if e->>'source_url' is distinct from p_source_url or e->>'kind' is distinct from 'dub'
        or e->>'audio_language' not in ('de','en') or e->>'region' not in ('DE','AT','CH','US','GB')
        or e->>'provider' not in ('Crunchyroll','Netflix','ADN','aniverse / Prime Video','HIDIVE','ProSieben MAXX','Disney+','Paramount+')
        or e->>'status' not in ('announced','confirmed','delayed') then raise exception 'Invalid dub proposal'; end if;
      k:=concat_ws('|','dub',e->>'mal_id',e->>'provider',e->>'region',e->>'audio_language',coalesce(e->>'episode','premiere'));
      select count(*) into identity_count from public.release_events r
       where r.announcement_key=k or (r.published and r.kind='dub' and r.mal_id=(e->>'mal_id')::bigint
         and r.provider=e->>'provider' and r.region=e->>'region' and r.audio_language=e->>'audio_language'
         and r.episode is not distinct from (e->>'episode')::integer);
      select r.* into existing from public.release_events r
       where r.announcement_key=k or (r.published and r.kind='dub' and r.mal_id=(e->>'mal_id')::bigint
         and r.provider=e->>'provider' and r.region=e->>'region' and r.audio_language=e->>'audio_language'
         and r.episode is not distinct from (e->>'episode')::integer)
       order by (r.announcement_key=k) desc nulls last,r.checked_at desc limit 1 for update;
      if identity_count>1 then
        decision:='conflict';reason:='multiple_existing_events';
      elsif existing.id is not null and existing.starts_at is not null then
        decision:='conflict';reason:='precise_provider_event_exists';
      elsif existing.id is not null and existing.starts_on is not null and e->>'starts_on' is null
          and e->>'status'<>'delayed' then
        decision:='ignored';reason:='retain_known_date';event_id:=existing.id;
      elsif existing.id is not null and existing.starts_on is not null
          and (existing.starts_on is distinct from (e->>'starts_on')::date or (existing.status='delayed' and e->>'status'<>'delayed'))
          and existing.source_url<>p_source_url then
        decision:='conflict';reason:='conflicting_source';
      else
        if existing.id is null then
          insert into public.release_events(mal_id,title,episode,kind,starts_on,provider,region,audio_language,status,source_url,checked_at,published,image_url,release_note,announcement_key)
          values ((e->>'mal_id')::bigint,e->>'title',(e->>'episode')::integer,'dub',(e->>'starts_on')::date,
            e->>'provider',e->>'region',e->>'audio_language',e->>'status',p_source_url,now(),true,e->>'image_url',e->>'release_note',k)
          returning id into event_id;
        else
          update public.release_events set starts_on=(e->>'starts_on')::date,status=e->>'status',
            source_url=p_source_url,checked_at=now(),published=true,announcement_key=k,
            release_note=e->>'release_note',image_url=coalesce(e->>'image_url',image_url)
            where id=existing.id returning id into event_id;
        end if;
        decision:='published';total:=total+1;
      end if;
    else
      reason:=coalesce(reason,'no_safe_proposal');
    end if;
    if decision='review' then review_count:=review_count+1; end if;
    if decision='conflict' then conflict_count:=conflict_count+1; end if;
    insert into public.dub_candidates(source_url,candidate_key,decision,reason,evidence,proposal,event_id)
    values (p_source_url,c->>'key',decision,reason,c->>'evidence',c,event_id)
    on conflict(source_url,candidate_key) do update set decision=excluded.decision,reason=excluded.reason,
      evidence=excluded.evidence,proposal=excluded.proposal,event_id=excluded.event_id,checked_at=now();
  end loop;
  -- A missing sentence/page is never interpreted as a cancellation.
  update public.dub_source_documents set needs_review=(review_count+conflict_count>0) where source_url=p_source_url;
  return jsonb_build_object('published',total,'review',review_count,'conflicts',conflict_count);
end;
$$;
revoke all on function public.apply_dub_candidates(text,jsonb) from public,anon,authenticated;
grant execute on function public.apply_dub_candidates(text,jsonb) to service_role;
