-- GNAP SITE CONTENT: jalankan sekali di Supabase SQL Editor
create table if not exists public.gnap_site_content (
  id uuid primary key default gen_random_uuid(),
  module text not null check (module in ('blacklist','sop','arsip','cloud','struktur','awards','agenda','notifications')),
  title text not null,
  category text,
  body text,
  link_url text,
  sort_order integer not null default 0,
  is_published boolean not null default false,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table public.gnap_site_content enable row level security;
drop policy if exists "GNAP admins manage site content" on public.gnap_site_content;
create policy "GNAP admins manage site content" on public.gnap_site_content
for all to authenticated
using ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin')
with check ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');
revoke all on public.gnap_site_content from anon, authenticated;
grant select, insert, update, delete on public.gnap_site_content to authenticated;
create or replace view public.gnap_public_content
with (security_invoker = false) as
select id, module, title, category, body, link_url, sort_order, created_at, updated_at
from public.gnap_site_content
where is_published = true;
grant select on public.gnap_public_content to anon, authenticated;
