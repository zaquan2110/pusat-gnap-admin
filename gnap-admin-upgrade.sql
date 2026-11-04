-- GNAP: nomor registrasi berurutan 12 digit + penyimpanan dokumen surat
create sequence if not exists public.gnap_nrp_sequence start 1;
do $$
declare v_max bigint;
begin
  select coalesce(max(nullif(nip,'')::bigint),0) into v_max
  from public.gnap_members where nip ~ '^[0-9]{12}$';
  if v_max > 0 then
    perform setval('public.gnap_nrp_sequence', v_max, true);
  end if;
end $$;
create or replace function public.gnap_next_nrp()
returns text
language plpgsql
security definer
set search_path = public
as $$
declare v_next bigint;
begin
  if coalesce(auth.jwt() -> 'app_metadata' ->> 'role','') <> 'admin' then
    raise exception 'Akses admin diperlukan';
  end if;
  v_next := nextval('public.gnap_nrp_sequence');
  if v_next > 999999999999 then raise exception 'Nomor NRP 12 digit sudah habis'; end if;
  return lpad(v_next::text,12,'0');
end;
$$;
revoke all on function public.gnap_next_nrp() from public, anon;
grant execute on function public.gnap_next_nrp() to authenticated;

insert into storage.buckets (id,name,public,file_size_limit,allowed_mime_types)
values ('gnap-documents','gnap-documents',true,15728640,
 array['application/pdf','image/png','image/jpeg','application/msword','application/vnd.openxmlformats-officedocument.wordprocessingml.document'])
on conflict (id) do update set public=true, file_size_limit=15728640;
drop policy if exists "GNAP admins upload documents" on storage.objects;
create policy "GNAP admins upload documents" on storage.objects
for insert to authenticated with check (bucket_id='gnap-documents' and (auth.jwt()->'app_metadata'->>'role')='admin');
drop policy if exists "GNAP admins update documents" on storage.objects;
create policy "GNAP admins update documents" on storage.objects
for update to authenticated using (bucket_id='gnap-documents' and (auth.jwt()->'app_metadata'->>'role')='admin')
with check (bucket_id='gnap-documents' and (auth.jwt()->'app_metadata'->>'role')='admin');
drop policy if exists "GNAP admins delete documents" on storage.objects;
create policy "GNAP admins delete documents" on storage.objects
for delete to authenticated using (bucket_id='gnap-documents' and (auth.jwt()->'app_metadata'->>'role')='admin');
drop policy if exists "GNAP public read documents" on storage.objects;
create policy "GNAP public read documents" on storage.objects
for select to anon, authenticated using (bucket_id='gnap-documents');
