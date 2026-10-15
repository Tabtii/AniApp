-- AniNews has not answered the permission enquiry sent 2026-10-12. Until it
-- grants permission, the importer makes no AniNews request (feed, robots.txt or
-- article) and its previously imported previews are removed from the app.
update public.source_rights set status='permission_requested',ingestion_enabled=false,images_allowed=false,commercial_allowed=false,
 evidence='Permission enquiry sent 2026-10-12; no answer. Ingestion switched off 2026-10-15 until written permission; stored previews removed.',
 reviewed_at=now()
 where source_key='aninews';

delete from public.news where source_name='AniNews';
