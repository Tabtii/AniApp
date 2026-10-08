alter table public.news add column image_url text check (image_url is null or image_url like 'https://%');
alter table public.release_events add column image_url text check (image_url is null or image_url like 'https://%');
create or replace function public.replace_broadcast_events(p_rows jsonb) returns void
language plpgsql security invoker set search_path='' as $$
begin
  if jsonb_typeof(p_rows)<>'array' or jsonb_array_length(p_rows)=0 or jsonb_array_length(p_rows)>500 then raise exception 'Invalid broadcast batch'; end if;
  if exists(select 1 from jsonb_array_elements(p_rows) r where r->>'kind' is distinct from 'japan' or r->>'provider' is distinct from 'Tenrai / MyAnimeList' or r->>'status' is distinct from 'estimated' or r->>'region' is distinct from 'JP') then raise exception 'Invalid broadcast identity'; end if;
  delete from public.release_events where provider='Tenrai / MyAnimeList' and kind='japan';
  insert into public.release_events(mal_id,title,episode,kind,starts_at,provider,region,audio_language,status,source_url,checked_at,published,image_url)
  select mal_id,title,null,'japan',starts_at,'Tenrai / MyAnimeList','JP','ja','estimated',source_url,checked_at,true,image_url
  from jsonb_to_recordset(p_rows) as x(mal_id bigint,title text,starts_at timestamptz,source_url text,checked_at timestamptz,image_url text);
end;
$$;
revoke all on function public.replace_broadcast_events(jsonb) from public, anon, authenticated;
grant execute on function public.replace_broadcast_events(jsonb) to service_role;
