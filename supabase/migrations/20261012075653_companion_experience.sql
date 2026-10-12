-- Source rights are independent from API reachability. Nothing is approved by default.
create table public.source_rights (
 source_key text primary key,name text not null,terms_url text not null check(terms_url like 'https://%'),
 status text not null check(status in ('review_required','permission_requested','approved','blocked')),
 commercial_allowed boolean not null default false,ingestion_enabled boolean not null default false,
 images_allowed boolean not null default false,evidence text not null default '',reviewed_at timestamptz not null default now()
);
alter table public.source_rights enable row level security;
grant select on public.source_rights to anon,authenticated;
grant all on public.source_rights to service_role;
create policy rights_read on public.source_rights for select to anon,authenticated using(true);
create policy rights_server on public.source_rights for all to service_role using(true) with check(true);
insert into public.source_rights(source_key,name,terms_url,status,evidence) values
('anilist','AniList','https://docs.anilist.co/guide/terms-of-use','blocked','Tracker/competition restriction: project-specific permission required.'),
('animeschedule','AnimeSchedule','https://animeschedule.net/api-terms-of-use','blocked','Commercial and competing use require clarification. Token is not permission.'),
('tmdb','TMDB','https://developer.themoviedb.org/docs/faq','review_required','Non-commercial attribution terms documented; commercial/image scope to clarify.'),
('tenrai','Tenrai','https://api.tenrai.org/documentation','review_required','API access does not grant upstream data or artwork rights.'),
('jikan','Jikan / MyAnimeList','https://myanimelist.net/static/apiagreement.html','review_required','Software license does not license upstream content.'),
('kitsu','Kitsu','https://kitsu.docs.apiary.io/','review_required','Public endpoint is not a content license.'),
('cr_de','Crunchyroll DE','https://www.crunchyroll.com/tos','review_required','Automated use, preview and commercial scope to clarify.'),
('cr_en','Crunchyroll EN','https://www.crunchyroll.com/tos','review_required','Automated use, preview and commercial scope to clarify.'),
('adn','ADN','https://animationdigitalnetwork.com/','review_required','No redistribution grant established.'),
('anime2you','Anime2You','https://www.anime2you.de/','review_required','RSS is not a blanket commercial/image license.'),
('aninews','AniNews','https://www.aninews.de/','review_required','Feed previews and commercial use need clarification.'),
('ann','Anime News Network','https://www.animenewsnetwork.com/newsfeed/terms-of-use.php','review_required','RSS attribution/registered URL conditions; mobile reuse to clarify.'),
('hidive','HIDIVE','https://news.hidive.com/dubs','review_required','Official dub facts; automated reuse not cleared.'),
('netflix','Netflix','https://help.netflix.com/en/node/101798','review_required','Territory and episode-specific audio; no bulk data grant established.'),
('maxx','ProSieben MAXX','https://www.prosiebenmaxx.de/themen/anime','review_required','TV and streaming dates must remain separate; automated reuse not cleared.');
create table public.companion_reviewers(user_id uuid primary key references auth.users(id) on delete cascade,created_at timestamptz not null default now());
create table public.dub_review_audit(
 id bigint generated always as identity primary key,actor uuid references auth.users(id) on delete set null,
 source_url text not null,candidate_key text not null,source_hash text,original_proposal jsonb not null,
 decision text not null check(decision in ('approved','rejected')),reviewed_event jsonb,note text not null check(length(note) between 1 and 1000),created_at timestamptz not null default now()
);
create index dub_review_lookup on public.dub_review_audit(source_url,candidate_key,id desc);
alter table public.companion_reviewers enable row level security;
alter table public.dub_review_audit enable row level security;
revoke all on public.companion_reviewers,public.dub_review_audit from public,anon,authenticated;
grant all on public.companion_reviewers,public.dub_review_audit to service_role;
grant usage,select on sequence public.dub_review_audit_id_seq to service_role;
create policy reviewers_server on public.companion_reviewers for all to service_role using(true) with check(true);
create policy audit_server on public.dub_review_audit for all to service_role using(true) with check(true);
create table public.dub_follows(
 user_id uuid not null references auth.users(id) on delete cascade,mal_id bigint not null check(mal_id>0),
 region text not null check(region in ('DE','AT','CH','US','GB')),audio_language text not null check(audio_language in ('de','en')),
 created_at timestamptz not null default now(),primary key(user_id,mal_id,region,audio_language)
);
create index dub_follows_event on public.dub_follows(mal_id,region,audio_language);
alter table public.dub_follows enable row level security;
grant select,insert,delete on public.dub_follows to authenticated;
grant update(mal_id,region,audio_language,user_id) on public.dub_follows to authenticated;
grant all on public.dub_follows to service_role;
create policy follows_read on public.dub_follows for select to authenticated using((select auth.uid())=user_id);
create policy follows_insert on public.dub_follows for insert to authenticated with check((select auth.uid())=user_id);
create policy follows_delete on public.dub_follows for delete to authenticated using((select auth.uid())=user_id);
create policy follows_update on public.dub_follows for update to authenticated using((select auth.uid())=user_id) with check((select auth.uid())=user_id);
create policy follows_server on public.dub_follows for all to service_role using(true) with check(true);
alter table public.release_events add column revision bigint not null default 1;
create table public.release_inbox(
 id uuid primary key default gen_random_uuid(),user_id uuid not null references auth.users(id) on delete cascade,
 event_id uuid not null references public.release_events(id) on delete cascade,revision bigint not null,
 kind text not null check(kind in ('announcement','changed','scheduled_today','scheduled_now','withdrawn')),
 event jsonb not null,created_at timestamptz not null default now(),read_at timestamptz,superseded boolean not null default false,
 unique(user_id,event_id,revision,kind)
);
create index inbox_user_created on public.release_inbox(user_id,created_at desc);
create index inbox_event on public.release_inbox(event_id);
alter table public.release_inbox enable row level security;
grant select on public.release_inbox to authenticated;
grant update(read_at) on public.release_inbox to authenticated;
grant all on public.release_inbox to service_role;
create policy inbox_read on public.release_inbox for select to authenticated using((select auth.uid())=user_id);
create policy inbox_read_at on public.release_inbox for update to authenticated using((select auth.uid())=user_id) with check((select auth.uid())=user_id);
create policy inbox_server on public.release_inbox for all to service_role using(true) with check(true);
create function public.release_revision() returns trigger language plpgsql security invoker set search_path='' as $$
begin
 if row(new.starts_at,new.starts_on,new.status,new.published,new.episode,new.audio_language,new.region,new.provider,new.mal_id)
 is distinct from row(old.starts_at,old.starts_on,old.status,old.published,old.episode,old.audio_language,old.region,old.provider,old.mal_id)
 then new.revision:=old.revision+1; else new.revision:=old.revision; end if; return new;
end $$;
create trigger bump_release_revision before update on public.release_events for each row execute function public.release_revision();
create function public.release_alert() returns trigger language plpgsql security definer set search_path='' as $$
declare k text;
begin
 if tg_op='UPDATE' and new.revision=old.revision then return new; end if;
 if tg_op='UPDATE' then update public.release_inbox set superseded=true where event_id=new.id and revision<new.revision; end if;
 if new.kind<>'dub' or new.status='estimated' then return new; end if;
 if tg_op='UPDATE' and old.published and not new.published then k:='withdrawn';
 elsif not new.published then return new;
 elsif tg_op='INSERT' then k:='announcement'; else k:='changed'; end if;
 insert into public.release_inbox(user_id,event_id,revision,kind,event)
 select f.user_id,new.id,new.revision,k,to_jsonb(new)-'announcement_key' from public.dub_follows f
 where f.mal_id=new.mal_id and f.region=new.region and f.audio_language=new.audio_language on conflict do nothing;
 return new;
end $$;
create trigger notify_release_change after insert or update on public.release_events for each row execute function public.release_alert();
revoke all on function public.release_revision(),public.release_alert() from public,anon,authenticated;
create function public.deliver_due_dub_alerts() returns integer language plpgsql security invoker set search_path='' as $$
declare n integer;
begin
 insert into public.release_inbox(user_id,event_id,revision,kind,event)
 select f.user_id,r.id,r.revision,case when r.starts_at is not null then 'scheduled_now' else 'scheduled_today' end,to_jsonb(r)-'announcement_key'
 from public.release_events r join public.dub_follows f using(mal_id,region,audio_language)
 where r.published and r.kind='dub' and r.status='confirmed' and
 ((r.starts_at<=now() and r.starts_at>now()-interval '2 hours') or
 (r.starts_on=(now() at time zone case r.region when 'US' then 'America/New_York' when 'GB' then 'Europe/London' else 'Europe/Berlin' end)::date))
 on conflict do nothing; get diagnostics n=row_count; return n;
end $$;
revoke all on function public.deliver_due_dub_alerts() from public,anon,authenticated;
grant execute on function public.deliver_due_dub_alerts() to service_role;
-- A human decision survives an unchanged article; changes return to review.
alter function public.apply_dub_candidates(text,jsonb) rename to apply_dub_candidates_unreviewed;
create function public.apply_dub_candidates(p_source_url text,p_candidates jsonb) returns jsonb language plpgsql security invoker set search_path='' as $$
declare c jsonb; latest public.dub_review_audit%rowtype; h text; filtered jsonb:='[]'; result jsonb;
begin
 if jsonb_typeof(p_candidates) is distinct from 'array' or jsonb_array_length(p_candidates)>100 then raise exception 'Invalid dub batch'; end if;
 select content_hash into h from public.dub_source_documents where source_url=p_source_url for update;
 if not found then raise exception 'Unknown source document'; end if;
 perform pg_advisory_xact_lock(741013);
 for c in select value from jsonb_array_elements(p_candidates) loop
  select * into latest from public.dub_review_audit where source_url=p_source_url and candidate_key=c->>'key' order by id desc limit 1;
  if latest.id is not null and (latest.original_proposal-'reason')=(c-'reason') and latest.source_hash is not distinct from h then continue; end if;
  if latest.id is not null then c:=jsonb_set(c,'{reason}','"source_changed_after_review"'); end if;
  filtered:=filtered||jsonb_build_array(c);
 end loop;
 result:=public.apply_dub_candidates_unreviewed(p_source_url,filtered);
 update public.dub_source_documents set needs_review=exists(select 1 from public.dub_candidates where source_url=p_source_url and decision in ('review','conflict')) where source_url=p_source_url;
 return result;
end $$;
revoke all on function public.apply_dub_candidates(text,jsonb) from public,anon,authenticated;
grant execute on function public.apply_dub_candidates(text,jsonb) to service_role;
create function public.review_dub_candidate(p_actor uuid,p_source_url text,p_key text,p_checked_at timestamptz,p_approve boolean,p_event jsonb,p_note text)
returns jsonb language plpgsql security invoker set search_path='' as $$
declare c public.dub_candidates%rowtype; h text; e jsonb; k text; target uuid; total integer;
begin
 if not exists(select 1 from public.companion_reviewers where user_id=p_actor) then raise exception 'Reviewer required'; end if;
 if length(trim(p_note)) not between 1 and 1000 then raise exception 'Review note required'; end if;
 select content_hash into h from public.dub_source_documents where source_url=p_source_url for update;
 perform pg_advisory_xact_lock(741013);
 select * into c from public.dub_candidates where source_url=p_source_url and candidate_key=p_key for update;
 if not found or c.checked_at is distinct from p_checked_at or c.decision not in ('review','conflict') then raise exception 'Candidate changed; reload'; end if;
 if p_approve then
  e:=p_event;
  if e is null or e->>'source_url' is distinct from p_source_url or e->>'kind' is distinct from 'dub'
   or coalesce(e->>'audio_language','') not in ('de','en') or coalesce(e->>'region','') not in ('DE','AT','CH','US','GB')
   or coalesce(e->>'provider','') not in ('Crunchyroll','Netflix','ADN','aniverse / Prime Video','HIDIVE','ProSieben MAXX','Disney+','Paramount+')
   or coalesce(e->>'status','') not in ('announced','confirmed','delayed') or (e->>'mal_id')::bigint is null
   or length(coalesce(e->>'title',''))=0 then raise exception 'Incomplete verified event'; end if;
  k:=concat_ws('|','dub',e->>'mal_id',e->>'provider',e->>'region',e->>'audio_language',coalesce(e->>'episode','premiere'));
  select count(*),min(id::text)::uuid into total,target from public.release_events r where r.announcement_key=k or
   (r.published and r.kind='dub' and r.mal_id=(e->>'mal_id')::bigint and r.provider=e->>'provider' and r.region=e->>'region' and r.audio_language=e->>'audio_language' and r.episode is not distinct from (e->>'episode')::integer);
  if total>1 then raise exception 'Duplicate identities must be reconciled first'; end if;
  if target is null then
   insert into public.release_events(mal_id,title,episode,kind,starts_on,starts_at,provider,region,audio_language,status,source_url,published,image_url,release_note,announcement_key)
   values((e->>'mal_id')::bigint,e->>'title',(e->>'episode')::integer,'dub',(e->>'starts_on')::date,(e->>'starts_at')::timestamptz,e->>'provider',e->>'region',e->>'audio_language',e->>'status',p_source_url,true,e->>'image_url',e->>'release_note',k) returning id into target;
  else
   update public.release_events set starts_on=(e->>'starts_on')::date,starts_at=(e->>'starts_at')::timestamptz,status=e->>'status',source_url=p_source_url,checked_at=now(),published=true,announcement_key=k,release_note=e->>'release_note' where id=target;
  end if;
 end if;
 insert into public.dub_review_audit(actor,source_url,candidate_key,source_hash,original_proposal,decision,reviewed_event,note)
 values(p_actor,p_source_url,p_key,h,c.proposal,case when p_approve then 'approved' else 'rejected' end,p_event,p_note);
 update public.dub_candidates set decision=case when p_approve then 'published' else 'ignored' end,reason='human_review',event_id=target,checked_at=now() where source_url=p_source_url and candidate_key=p_key;
 update public.dub_source_documents set needs_review=exists(select 1 from public.dub_candidates where source_url=p_source_url and decision in ('review','conflict')) where source_url=p_source_url;
 return jsonb_build_object('ok',true,'event_id',target);
end $$;
revoke all on function public.review_dub_candidate(uuid,text,text,timestamptz,boolean,jsonb,text) from public,anon,authenticated;
grant execute on function public.review_dub_candidate(uuid,text,text,timestamptz,boolean,jsonb,text) to service_role;
alter table public.news add column regions text[] not null default '{}';
alter table public.news add column providers text[] not null default '{}';
-- Public health contains no article text, secrets or internal error messages.
create table public.source_status(source_key text primary key,checked_at timestamptz,state text not null check(state in ('ok','degraded','pending')),review_count integer not null default 0 check(review_count>=0));
alter table public.source_status enable row level security;
grant select on public.source_status to anon,authenticated;
grant all on public.source_status to service_role;
create policy status_read on public.source_status for select to anon,authenticated using(true);
create policy status_server on public.source_status for all to service_role using(true) with check(true);
create function public.refresh_source_status() returns void language sql security invoker set search_path='' as $$
 update public.news n set mal_id=f.mal_id,regions=f.regions,providers=f.providers from (
  select source_url,min(mal_id) as mal_id,array_agg(distinct region) filter(where region<>'JP') as regions,array_agg(distinct provider) as providers
  from public.release_events where published and kind='dub' group by source_url having count(distinct mal_id)=1
 ) f where n.source_url=f.source_url;
 insert into public.source_status(source_key,checked_at,state,review_count)
 select d.source_key,max(d.checked_at),case when bool_or(d.error is not null) then 'degraded' when max(d.checked_at) is null then 'pending' else 'ok' end,
 (select count(*)::integer from public.dub_candidates c join public.dub_source_documents ds using(source_url) where ds.source_key=d.source_key and c.decision in ('review','conflict'))
 from public.dub_source_documents d group by d.source_key
 on conflict(source_key) do update set checked_at=excluded.checked_at,state=excluded.state,review_count=excluded.review_count;
$$;
revoke all on function public.refresh_source_status() from public,anon,authenticated;
grant execute on function public.refresh_source_status() to service_role;
-- Owner-provisioned invitations are private. Verification is enforced by Auth
-- before the edge function can exchange an invitation for a reviewer role.
create table public.companion_reviewer_invitations(email text primary key check(email=lower(email)),created_at timestamptz not null default now());
alter table public.companion_reviewer_invitations enable row level security;
revoke all on public.companion_reviewer_invitations from public,anon,authenticated;
grant all on public.companion_reviewer_invitations to service_role;
create policy reviewer_invites_server on public.companion_reviewer_invitations for all to service_role using(true) with check(true);
insert into public.source_rights(source_key,name,terms_url,status,commercial_allowed,ingestion_enabled,images_allowed,evidence)
values('mydublist','MyDubList','https://github.com/Joelis57/MyDubList/blob/main/LICENSE','approved',true,true,false,'Published CC BY 4.0 grant for repository JSON datasets. Attribution, source/license links and modification notice required; not an artwork or upstream API licence.');
