-- GNAP ADMIN — jalankan sekali di Supabase SQL Editor
create table if not exists public.gnap_members (
  id uuid primary key default gen_random_uuid(),
  roblox_name text not null,
  display_name text,
  discord_id text,
  position text,
  rank text,
  nip text unique,
  status text not null default 'AKTIF',
  photo_url text,
  notes text,
  issued boolean not null default false,
  issued_at timestamptz,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.gnap_members enable row level security;

drop policy if exists "GNAP admins manage members" on public.gnap_members;
create policy "GNAP admins manage members" on public.gnap_members
for all to authenticated
using ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin')
with check ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');

revoke all on public.gnap_members from anon, authenticated;
grant select, insert, update, delete on public.gnap_members to authenticated;

-- Portal publik hanya membaca kolom yang memang boleh ditampilkan.
create or replace view public.gnap_public_members
with (security_invoker = false) as
select id, roblox_name, display_name, position, rank, nip, status, photo_url, issued_at
from public.gnap_members
where issued = true;

grant select on public.gnap_public_members to anon, authenticated;

-- Catatan:
-- Beri role admin melalui Supabase Dashboard > Authentication > Users
-- > pilih akun admin > Edit app_metadata, isi {"role":"admin"}.
-- Jangan taruh service_role key di frontend.
