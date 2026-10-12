-- The dashboard's automatic-RLS event trigger is an internal database helper.
-- Keep the trigger enabled without exposing its SECURITY DEFINER function to API roles.
do $$
begin
  if to_regprocedure('public.rls_auto_enable()') is not null then
    revoke execute on function public.rls_auto_enable() from public, anon, authenticated;
  end if;
end;
$$;
