create extension if not exists "pgcrypto";

create table if not exists public.profiles (
  id uuid primary key default gen_random_uuid(),
  auth_user_id uuid unique references auth.users(id) on delete cascade,
  full_name text not null,
  role text,
  created_at timestamptz default now()
);

create table if not exists public.tasks (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text,
  status text not null default 'plan',
  task_date date,
  import_key text unique,
  created_by uuid references auth.users(id),
  created_at timestamptz default now()
);

create table if not exists public.task_assignees (
  task_id uuid references public.tasks(id) on delete cascade,
  user_id uuid references public.profiles(id) on delete cascade,
  primary key (task_id, user_id)
);

create table if not exists public.task_files (
  id uuid primary key default gen_random_uuid(),
  task_id uuid references public.tasks(id) on delete cascade,
  file_url text not null,
  file_name text,
  file_type text,
  created_at timestamptz default now()
);

create table if not exists public.voice_notes (
  id uuid primary key default gen_random_uuid(),
  task_id uuid references public.tasks(id) on delete cascade,
  audio_url text not null,
  file_name text,
  created_by uuid references auth.users(id),
  created_at timestamptz default now()
);

alter table public.profiles enable row level security;
alter table public.tasks enable row level security;
alter table public.task_assignees enable row level security;
alter table public.task_files enable row level security;
alter table public.voice_notes enable row level security;

drop policy if exists "profiles read authenticated" on public.profiles;
create policy "profiles read authenticated" on public.profiles
  for select to authenticated using (true);

drop policy if exists "profiles insert authenticated" on public.profiles;
create policy "profiles insert authenticated" on public.profiles
  for insert to authenticated with check (true);

drop policy if exists "profiles update authenticated" on public.profiles;
create policy "profiles update authenticated" on public.profiles
  for update to authenticated using (true) with check (true);

drop policy if exists "tasks read authenticated" on public.tasks;
create policy "tasks read authenticated" on public.tasks
  for select to authenticated using (true);

drop policy if exists "tasks insert authenticated" on public.tasks;
create policy "tasks insert authenticated" on public.tasks
  for insert to authenticated with check (auth.uid() = created_by);

drop policy if exists "tasks update authenticated" on public.tasks;
create policy "tasks update authenticated" on public.tasks
  for update to authenticated using (true) with check (true);

drop policy if exists "task assignees read authenticated" on public.task_assignees;
create policy "task assignees read authenticated" on public.task_assignees
  for select to authenticated using (true);

drop policy if exists "task assignees write authenticated" on public.task_assignees;
create policy "task assignees write authenticated" on public.task_assignees
  for all to authenticated using (true) with check (true);

drop policy if exists "task files read authenticated" on public.task_files;
create policy "task files read authenticated" on public.task_files
  for select to authenticated using (true);

drop policy if exists "task files write authenticated" on public.task_files;
create policy "task files write authenticated" on public.task_files
  for all to authenticated using (true) with check (true);

drop policy if exists "voice notes read authenticated" on public.voice_notes;
create policy "voice notes read authenticated" on public.voice_notes
  for select to authenticated using (true);

drop policy if exists "voice notes write authenticated" on public.voice_notes;
create policy "voice notes write authenticated" on public.voice_notes
  for all to authenticated using (true) with check (true);

insert into storage.buckets (id, name, public)
values ('task-assets', 'task-assets', true)
on conflict (id) do update set public = true;

drop policy if exists "task assets public read" on storage.objects;
create policy "task assets public read" on storage.objects
  for select using (bucket_id = 'task-assets');

drop policy if exists "task assets authenticated upload" on storage.objects;
create policy "task assets authenticated upload" on storage.objects
  for insert to authenticated with check (bucket_id = 'task-assets');

drop policy if exists "task assets authenticated update" on storage.objects;
create policy "task assets authenticated update" on storage.objects
  for update to authenticated using (bucket_id = 'task-assets') with check (bucket_id = 'task-assets');
