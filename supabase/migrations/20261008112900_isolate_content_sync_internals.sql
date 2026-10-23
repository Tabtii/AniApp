-- Internal refresh state is only accessible to the server.
create policy server_content_sync on public.content_sync_state for all to service_role using (true) with check (true);
