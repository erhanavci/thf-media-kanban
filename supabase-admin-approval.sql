alter table public.profiles add column if not exists approval_status text default 'pending';
alter table public.profiles add column if not exists is_admin boolean default false;

alter table public.profiles
  drop constraint if exists profiles_approval_status_check;

alter table public.profiles
  add constraint profiles_approval_status_check
  check (approval_status in ('pending', 'approved', 'rejected'));

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

drop policy if exists "profiles read authenticated" on public.profiles;
drop policy if exists "profiles insert authenticated" on public.profiles;
drop policy if exists "profiles update authenticated" on public.profiles;
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
  using (public.is_admin())
  with check (public.is_admin());

drop policy if exists "tasks read authenticated" on public.tasks;
drop policy if exists "tasks insert authenticated" on public.tasks;
drop policy if exists "tasks update authenticated" on public.tasks;

create policy "tasks read approved" on public.tasks
  for select to authenticated using (public.is_approved());

create policy "tasks insert approved" on public.tasks
  for insert to authenticated with check (public.is_approved());

create policy "tasks update approved" on public.tasks
  for update to authenticated using (public.is_approved()) with check (public.is_approved());

drop policy if exists "task assignees read authenticated" on public.task_assignees;
drop policy if exists "task assignees write authenticated" on public.task_assignees;

create policy "task assignees read approved" on public.task_assignees
  for select to authenticated using (public.is_approved());

create policy "task assignees write approved" on public.task_assignees
  for all to authenticated using (public.is_approved()) with check (public.is_approved());

drop policy if exists "task files read authenticated" on public.task_files;
drop policy if exists "task files write authenticated" on public.task_files;

create policy "task files read approved" on public.task_files
  for select to authenticated using (public.is_approved());

create policy "task files write approved" on public.task_files
  for all to authenticated using (public.is_approved()) with check (public.is_approved());

drop policy if exists "voice notes read authenticated" on public.voice_notes;
drop policy if exists "voice notes write authenticated" on public.voice_notes;

create policy "voice notes read approved" on public.voice_notes
  for select to authenticated using (public.is_approved());

create policy "voice notes write approved" on public.voice_notes
  for all to authenticated using (public.is_approved()) with check (public.is_approved());

-- Run this once after replacing the email with your own login email.
-- update public.profiles
-- set approval_status = 'approved', is_admin = true
-- where auth_user_id = (
--   select id from auth.users where email = 'YOUR_EMAIL_HERE'
-- );
