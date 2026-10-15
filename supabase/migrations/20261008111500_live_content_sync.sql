alter table public.news add column language text not null default 'de' check (language ~ '^[a-z]{2}$');
create table public.content_sync_state (
  id boolean primary key default true check(id),
  last_attempt_at timestamptz,
  completed_at timestamptz,
  report jsonb not null default '{}'::jsonb
);
alter table public.content_sync_state enable row level security;
revoke all on public.content_sync_state from anon, authenticated;
grant all on public.content_sync_state to service_role;
insert into public.content_sync_state(id) values(true);
-- Only the server can call this gate. The token remains in Vault and never enters the app.
create function public.begin_content_sync(p_token text) returns text
language plpgsql security definer set search_path='' as $$
begin
  if not exists (select 1 from vault.decrypted_secrets where name='aniapp_content_sync' and decrypted_secret=p_token) then return 'denied'; end if;
  update public.content_sync_state set last_attempt_at=now() where id and (last_attempt_at is null or last_attempt_at < now()-interval '20 minutes');
  if not found then return 'recent'; end if;
  return 'ready';
end;
$$;
revoke all on function public.begin_content_sync(text) from public, anon, authenticated;
grant execute on function public.begin_content_sync(text) to service_role;
create function public.finish_content_sync(p_report jsonb) returns void
language sql security invoker set search_path='' as $$
  update public.content_sync_state set completed_at=now(),report=p_report where id;
$$;
revoke all on function public.finish_content_sync(jsonb) from public, anon, authenticated;
grant execute on function public.finish_content_sync(jsonb) to service_role;
create function public.replace_broadcast_events(p_rows jsonb) returns void
language plpgsql security invoker set search_path='' as $$
begin
  if jsonb_typeof(p_rows)<>'array' or jsonb_array_length(p_rows)=0 or jsonb_array_length(p_rows)>500 then raise exception 'Invalid broadcast batch'; end if;
  if exists(select 1 from jsonb_array_elements(p_rows) r where r->>'kind' is distinct from 'japan' or r->>'provider' is distinct from 'Tenrai / MyAnimeList' or r->>'status' is distinct from 'estimated' or r->>'region' is distinct from 'JP') then raise exception 'Invalid broadcast identity'; end if;
  delete from public.release_events where provider='Tenrai / MyAnimeList' and kind='japan';
  insert into public.release_events(mal_id,title,episode,kind,starts_at,provider,region,audio_language,status,source_url,checked_at,published)
  select mal_id,title,null,'japan',starts_at,'Tenrai / MyAnimeList','JP','ja','estimated',source_url,checked_at,true
  from jsonb_to_recordset(p_rows) as x(mal_id bigint,title text,starts_at timestamptz,source_url text,checked_at timestamptz);
end;
$$;
revoke all on function public.replace_broadcast_events(jsonb) from public, anon, authenticated;
grant execute on function public.replace_broadcast_events(jsonb) to service_role;
