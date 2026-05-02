alter table public.profiles add column if not exists auth_user_id uuid;
alter table public.profiles add column if not exists approval_status text default 'pending';
alter table public.profiles add column if not exists is_admin boolean default false;
alter table public.profiles add column if not exists avatar_url text;
alter table public.tasks add column if not exists deadline_date date;
alter table public.tasks add column if not exists priority text not null default 'medium';
alter table public.tasks add column if not exists progress_status text not null default 'ongoing';
alter table public.voice_notes add column if not exists file_name text;
alter table public.task_files add column if not exists created_by uuid references auth.users(id);

notify pgrst, 'reload schema';

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'profiles_auth_user_id_fkey'
  ) then
    alter table public.profiles
      add constraint profiles_auth_user_id_fkey
      foreign key (auth_user_id)
      references auth.users(id)
      on delete cascade;
  end if;
end $$;

do $$
begin
  if not exists (
    select 1
    from pg_indexes
    where schemaname = 'public'
      and indexname = 'profiles_auth_user_id_unique'
  ) then
    create unique index profiles_auth_user_id_unique
      on public.profiles(auth_user_id)
      where auth_user_id is not null;
  end if;
end $$;

-- If an older version used profiles.id directly as the auth user id, repair the link.
update public.profiles p
set auth_user_id = p.id
where p.auth_user_id is null
  and exists (select 1 from auth.users u where u.id = p.id);

alter table public.profiles
  drop constraint if exists profiles_approval_status_check;

alter table public.profiles
  add constraint profiles_approval_status_check
  check (approval_status in ('pending', 'approved', 'rejected'));

alter table public.tasks
  drop constraint if exists tasks_priority_check;

alter table public.tasks
  add constraint tasks_priority_check
  check (priority in ('low', 'medium', 'high', 'urgent'));

alter table public.tasks
  drop constraint if exists tasks_progress_status_check;

alter table public.tasks
  add constraint tasks_progress_status_check
  check (progress_status in ('ongoing', 'completed'));

create table if not exists public.task_notes (
  id uuid primary key default gen_random_uuid(),
  task_id uuid references public.tasks(id) on delete cascade,
  note_text text not null,
  created_by uuid references auth.users(id),
  created_at timestamptz default now()
);

alter table public.task_notes enable row level security;

create or replace function public.is_admin()
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.profiles
    where auth_user_id = auth.uid()
      and is_admin = true
      and approval_status = 'approved'
  );
$$;

create or replace function public.is_approved()
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.profiles
    where auth_user_id = auth.uid()
      and approval_status = 'approved'
  );
$$;

create or replace function public.protect_profile_admin_fields()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_admin() then
    new.id = old.id;
    new.auth_user_id = old.auth_user_id;
    new.approval_status = old.approval_status;
    new.is_admin = old.is_admin;
  end if;
  return new;
end;
$$;

drop trigger if exists protect_profile_admin_fields_trigger on public.profiles;
create trigger protect_profile_admin_fields_trigger
before update on public.profiles
for each row execute function public.protect_profile_admin_fields();

create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (
    id,
    auth_user_id,
    full_name,
    role,
    approval_status,
    is_admin
  )
  values (
    new.id,
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', new.email, 'New user'),
    coalesce(new.raw_user_meta_data->>'role', 'Team'),
    'pending',
    false
  )
  on conflict (id) do update set
    auth_user_id = coalesce(public.profiles.auth_user_id, excluded.auth_user_id),
    full_name = coalesce(nullif(public.profiles.full_name, ''), excluded.full_name),
    role = coalesce(nullif(public.profiles.role, ''), excluded.role),
    approval_status = coalesce(public.profiles.approval_status, 'pending'),
    is_admin = coalesce(public.profiles.is_admin, false);

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_auth_user();

insert into public.profiles (
  id,
  auth_user_id,
  full_name,
  role,
  approval_status,
  is_admin
)
select
  u.id,
  u.id,
  coalesce(u.raw_user_meta_data->>'full_name', u.email, 'New user'),
  coalesce(u.raw_user_meta_data->>'role', 'Team'),
  case
    when u.email = 'erhan.avci@thf.org.tr' then 'approved'
    else 'pending'
  end,
  u.email = 'erhan.avci@thf.org.tr'
from auth.users u
on conflict (id) do update set
  auth_user_id = coalesce(public.profiles.auth_user_id, excluded.auth_user_id),
  full_name = coalesce(nullif(public.profiles.full_name, ''), excluded.full_name),
  role = coalesce(nullif(public.profiles.role, ''), excluded.role);

drop policy if exists "profiles read authenticated" on public.profiles;
drop policy if exists "profiles insert authenticated" on public.profiles;
drop policy if exists "profiles update authenticated" on public.profiles;
drop policy if exists "profiles read approved or self" on public.profiles;
drop policy if exists "profiles insert self or approved team member" on public.profiles;
drop policy if exists "profiles update admin only" on public.profiles;
drop policy if exists "profiles insert own" on public.profiles;
drop policy if exists "profiles update own" on public.profiles;

create policy "profiles read approved or self" on public.profiles
  for select to authenticated
  using (public.is_approved() or auth.uid() = auth_user_id or public.is_admin());

create policy "profiles insert self or approved team member" on public.profiles
  for insert to authenticated
  with check (
    auth.uid() = auth_user_id
    or (public.is_approved() and auth_user_id is null)
    or public.is_admin()
  );

create policy "profiles update admin only" on public.profiles
  for update to authenticated
  using (public.is_admin() or auth.uid() = auth_user_id)
  with check (public.is_admin() or auth.uid() = auth_user_id);

drop policy if exists "tasks read authenticated" on public.tasks;
drop policy if exists "tasks insert authenticated" on public.tasks;
drop policy if exists "tasks update authenticated" on public.tasks;
drop policy if exists "tasks read approved" on public.tasks;
drop policy if exists "tasks insert approved" on public.tasks;
drop policy if exists "tasks update approved" on public.tasks;
drop policy if exists "tasks delete approved" on public.tasks;

create policy "tasks read approved" on public.tasks
  for select to authenticated using (public.is_approved());

create policy "tasks insert approved" on public.tasks
  for insert to authenticated with check (public.is_approved());

create policy "tasks update approved" on public.tasks
  for update to authenticated using (public.is_approved()) with check (public.is_approved());

create policy "tasks delete approved" on public.tasks
  for delete to authenticated using (public.is_approved());

drop policy if exists "task assignees read authenticated" on public.task_assignees;
drop policy if exists "task assignees write authenticated" on public.task_assignees;
drop policy if exists "task assignees read approved" on public.task_assignees;
drop policy if exists "task assignees write approved" on public.task_assignees;

create policy "task assignees read approved" on public.task_assignees
  for select to authenticated using (public.is_approved());

create policy "task assignees write approved" on public.task_assignees
  for all to authenticated using (public.is_approved()) with check (public.is_approved());

drop policy if exists "task files read authenticated" on public.task_files;
drop policy if exists "task files write authenticated" on public.task_files;
drop policy if exists "task files read approved" on public.task_files;
drop policy if exists "task files write approved" on public.task_files;

create policy "task files read approved" on public.task_files
  for select to authenticated using (public.is_approved());

create policy "task files write approved" on public.task_files
  for all to authenticated using (public.is_approved()) with check (public.is_approved());

drop policy if exists "voice notes read authenticated" on public.voice_notes;
drop policy if exists "voice notes write authenticated" on public.voice_notes;
drop policy if exists "voice notes read approved" on public.voice_notes;
drop policy if exists "voice notes write approved" on public.voice_notes;

create policy "voice notes read approved" on public.voice_notes
  for select to authenticated using (public.is_approved());

create policy "voice notes write approved" on public.voice_notes
  for all to authenticated using (public.is_approved()) with check (public.is_approved());

drop policy if exists "task notes read authenticated" on public.task_notes;
drop policy if exists "task notes write authenticated" on public.task_notes;
drop policy if exists "task notes read approved" on public.task_notes;
drop policy if exists "task notes write approved" on public.task_notes;

create policy "task notes read approved" on public.task_notes
  for select to authenticated using (public.is_approved());

create policy "task notes write approved" on public.task_notes
  for all to authenticated using (public.is_approved()) with check (public.is_approved());

-- Run this once after replacing the email with your own login email.
 update public.profiles
 set approval_status = 'approved', is_admin = true
 where auth_user_id = (
   select id from auth.users where email = 'erhan.avci@thf.org.tr'
 );

notify pgrst, 'reload schema';
