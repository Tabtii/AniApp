-- pg_cron/pg_net are hosted Supabase extensions; embedded SQL test engines lack them.
do $setup$
begin
 if exists(select 1 from pg_available_extensions where name='pg_cron') then
  create extension if not exists pg_cron;
  create extension if not exists pg_net;
  if not exists(select 1 from vault.secrets where name='aniapp_content_sync') then
   perform vault.create_secret(gen_random_uuid()::text,'aniapp_content_sync','AniApp internal content refresh');
  end if;
  perform cron.schedule('aniapp-content-hourly','15 * * * *',$job$
   select net.http_post(
    url:='https://pisonrhjrqpqazimiiln.supabase.co/functions/v1/content-sync',
    headers:=jsonb_build_object('Content-Type','application/json','x-sync-token',(select decrypted_secret from vault.decrypted_secrets where name='aniapp_content_sync')),
    body:='{}'::jsonb,timeout_milliseconds:=120000);
  $job$);
 end if;
end;
$setup$;
