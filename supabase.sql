-- ETHAN CLOUD — install in the NEW ETHAN ID Supabase project.
-- Safe to re-run: policies are dropped/recreated.
create extension if not exists pgcrypto;

create table if not exists public.cloud_folders (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  name text not null check (char_length(name) between 1 and 120),
  parent_id uuid references public.cloud_folders(id) on delete cascade,
  is_starred boolean not null default false,
  is_trashed boolean not null default false,
  created_at timestamptz not null default now()
);
create table if not exists public.cloud_files (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  folder_id uuid references public.cloud_folders(id) on delete set null,
  name text not null,
  storage_path text not null unique,
  mime_type text,
  size_bytes bigint not null default 0,
  is_starred boolean not null default false,
  is_trashed boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table public.cloud_folders enable row level security;
alter table public.cloud_files enable row level security;

drop policy if exists "folders owner select" on public.cloud_folders;
drop policy if exists "folders owner insert" on public.cloud_folders;
drop policy if exists "folders owner update" on public.cloud_folders;
drop policy if exists "folders owner delete" on public.cloud_folders;
drop policy if exists "files owner select" on public.cloud_files;
drop policy if exists "files owner insert" on public.cloud_files;
drop policy if exists "files owner update" on public.cloud_files;
drop policy if exists "files owner delete" on public.cloud_files;
create policy "folders owner select" on public.cloud_folders for select to authenticated using (auth.uid() = owner_id);
create policy "folders owner insert" on public.cloud_folders for insert to authenticated with check (auth.uid() = owner_id);
create policy "folders owner update" on public.cloud_folders for update to authenticated using (auth.uid() = owner_id) with check (auth.uid() = owner_id);
create policy "folders owner delete" on public.cloud_folders for delete to authenticated using (auth.uid() = owner_id);
create policy "files owner select" on public.cloud_files for select to authenticated using (auth.uid() = owner_id);
create policy "files owner insert" on public.cloud_files for insert to authenticated with check (auth.uid() = owner_id);
create policy "files owner update" on public.cloud_files for update to authenticated using (auth.uid() = owner_id) with check (auth.uid() = owner_id);
create policy "files owner delete" on public.cloud_files for delete to authenticated using (auth.uid() = owner_id);

insert into storage.buckets (id,name,public) values ('ethan-cloud','ethan-cloud',false)
on conflict (id) do update set public=false;

drop policy if exists "cloud objects read own" on storage.objects;
drop policy if exists "cloud objects upload own" on storage.objects;
drop policy if exists "cloud objects update own" on storage.objects;
drop policy if exists "cloud objects delete own" on storage.objects;
create policy "cloud objects read own" on storage.objects for select to authenticated using (bucket_id='ethan-cloud' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "cloud objects upload own" on storage.objects for insert to authenticated with check (bucket_id='ethan-cloud' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "cloud objects update own" on storage.objects for update to authenticated using (bucket_id='ethan-cloud' and (storage.foldername(name))[1] = auth.uid()::text) with check (bucket_id='ethan-cloud' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "cloud objects delete own" on storage.objects for delete to authenticated using (bucket_id='ethan-cloud' and (storage.foldername(name))[1] = auth.uid()::text);
