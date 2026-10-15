-- Security advisor 0014: pg_net was registered in the public schema. Its
-- functions live in schema net either way, so the cron jobs calling
-- net.http_post keep working; only the extension registration moves. The
-- request queue is transient, so recreating the extension loses no data.
do $setup$
begin
 if exists(select 1 from pg_extension e join pg_namespace n on n.oid=e.extnamespace where e.extname='pg_net' and n.nspname='public') then
  drop extension pg_net;
  create schema if not exists extensions;
  create extension pg_net with schema extensions;
 end if;
end;
$setup$;

-- Performance advisor 0001: cover the reviewer foreign key used when an
-- account is deleted (on delete set null).
create index if not exists dub_review_audit_actor on public.dub_review_audit(actor);
