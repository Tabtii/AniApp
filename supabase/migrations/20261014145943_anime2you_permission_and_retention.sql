-- Anime2You's written project-specific permission, received 2026-10-14 14:51 CEST.
-- No private correspondence or account identifiers are stored in this public register.
alter table public.news
 add column preview_kind text not null default 'feed_excerpt' check(preview_kind in ('feed_excerpt','publisher_meta','link_only')),
 add column metadata_checked_at timestamptz,
 add column metadata_attempt_at timestamptz,
 add column metadata_etag text,
 add column metadata_last_modified text;

update public.source_rights set status='approved',ingestion_enabled=true,images_allowed=true,commercial_allowed=true,
 evidence='Written Anime2You permission received 2026-10-14: no fees for the described AniApp use including proposed monetisation; feed, title, date, source and linked calendar facts allowed. Direct original link required. Prefer publisher meta-description; no own/AI article summaries. Publisher agrees to preview images but cannot grant third-party artwork rights. Images flag records publisher permission only, not third-party clearance. Recommend 15-minute feed polling; overwrite corrections and do not permanently archive source content. AniApp chooses a rolling 30-day content cache; this duration was not specified by the publisher.',
 reviewed_at='2026-10-14T12:51:34Z'
 where source_key='anime2you';

-- Remove legacy feed excerpts immediately; metadata is refilled by the next jobs.
update public.news set summary='Originalmeldung auf Anime2You lesen.',preview_kind='link_only'
 where source_name='Anime2You';

create function public.prune_anime2you_content() returns jsonb
language plpgsql security invoker set search_path='' as $$
declare removed integer; scrubbed integer;
begin
 delete from public.news where source_name='Anime2You'
  and coalesce(published_at,checked_at)<now()-interval '30 days';
 get diagnostics removed=row_count;
 -- Keep structured calendar facts, URLs, hashes and review decisions. Expire
 -- copied headlines and evidence even while a future date is still watched.
 update public.dub_candidates c set evidence='',proposal=c.proposal-'evidence'
 from public.dub_source_documents d where c.source_url=d.source_url and d.source_key='anime2you'
  and coalesce(d.published_at,d.watch_until-interval '180 days')<now()-interval '30 days'
  and (c.evidence<>'' or c.proposal?'evidence');
 get diagnostics scrubbed=row_count;
 update public.dub_review_audit a set original_proposal=a.original_proposal-'evidence'
 where a.source_url like 'https://www.anime2you.de/news/%' and a.original_proposal?'evidence'
 and coalesce((select d.published_at from public.dub_source_documents d where d.source_url=a.source_url),a.created_at)<now()-interval '30 days';
 update public.dub_source_documents set headline=''
 where source_key='anime2you' and headline<>''
 and coalesce(published_at,watch_until-interval '180 days')<now()-interval '30 days';
 return jsonb_build_object('news_removed',removed,'evidence_cleared',scrubbed);
end $$;
revoke all on function public.prune_anime2you_content() from public,anon,authenticated;
grant execute on function public.prune_anime2you_content() to service_role;
select public.prune_anime2you_content();

-- Same server-only token gate and atomic cooldown, shortened for 15-minute jobs.
create or replace function public.begin_content_sync(p_token text) returns text
language plpgsql security definer set search_path='' as $$
begin
 if not exists(select 1 from vault.decrypted_secrets where name='aniapp_content_sync' and decrypted_secret=p_token) then return 'denied'; end if;
 update public.content_sync_state set last_attempt_at=now() where id
 and (last_attempt_at is null or last_attempt_at<now()-interval '10 minutes');
 if not found then return 'recent'; end if;
 return 'ready';
end $$;
revoke all on function public.begin_content_sync(text) from public,anon,authenticated;
grant execute on function public.begin_content_sync(text) to service_role;

-- Partial runs must preserve the most recent hourly report for other sources.
create or replace function public.finish_content_sync(p_report jsonb) returns void
language sql security invoker set search_path='' as $$
 update public.content_sync_state set completed_at=now(),report=report||p_report where id;
$$;
revoke all on function public.finish_content_sync(jsonb) from public,anon,authenticated;
grant execute on function public.finish_content_sync(jsonb) to service_role;

do $setup$
begin
 if exists(select 1 from pg_extension where extname='pg_cron') then
  -- Existing hourly job at :15 includes Anime2You. Fill the other three quarters.
  perform cron.schedule('aniapp-anime2you-quarter-hour','0,30,45 * * * *',$job$
   select net.http_post(
    url:='https://pisonrhjrqpqazimiiln.supabase.co/functions/v1/content-sync',
    headers:=jsonb_build_object('Content-Type','application/json','x-sync-token',(select decrypted_secret from vault.decrypted_secrets where name='aniapp_content_sync')),
    body:='{"scope":"anime2you"}'::jsonb,timeout_milliseconds:=120000);
  $job$);
  -- Retention is enforced even if the Edge Function is unavailable.
  perform cron.schedule('aniapp-anime2you-retention','5,20,35,50 * * * *','select public.prune_anime2you_content()');
 end if;
end;
$setup$;
