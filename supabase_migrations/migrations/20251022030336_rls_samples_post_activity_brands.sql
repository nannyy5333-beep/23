alter table if exists public.post_activity enable row level security;
do $$ begin
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='post_activity' and policyname='post_activity_read_auth') then
    create policy post_activity_read_auth on public.post_activity for select to authenticated using (true);
  end if;
end $$;

alter table if exists public.brands enable row level security;
do $$ begin
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='brands' and policyname='brands_read_auth') then
    create policy brands_read_auth on public.brands for select to authenticated using (true);
  end if;
end $$;
