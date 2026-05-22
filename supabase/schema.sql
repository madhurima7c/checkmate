-- ============================================================
-- Checkmate — Supabase Schema
-- Run this in the Supabase SQL editor (supabase.com → SQL Editor)
-- ============================================================

-- Profiles (mirrors auth.users)
create table public.profiles (
  id uuid references auth.users on delete cascade primary key,
  name text not null,
  email text,
  apns_token text,
  updated_at timestamptz default now()
);

create unique index if not exists profiles_email_idx on public.profiles(email) where email is not null;

-- Auto-create profile on sign up
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, name, email)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', new.email, 'User'),
    lower(new.email)
  );
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- Tasks
create table public.tasks (
  id uuid primary key default gen_random_uuid(),
  text text not null,
  sender_id uuid references public.profiles(id) on delete cascade not null,
  receiver_id uuid references public.profiles(id) on delete cascade,
  due_date date not null default current_date,
  status text not null default 'pending' check (status in ('pending', 'done')),
  is_seen boolean not null default false,
  color text not null default 'yellow' check (color in ('yellow', 'pink', 'blue', 'orange')),
  all_day boolean not null default true,
  due_at timestamptz,
  completed_at timestamptz,
  assignee_name text,
  invite_contact text,
  created_at timestamptz default now()
);

-- Pending invites — keyed by phone/email so a sender can fan tasks out
-- to someone before that person creates a Checkmate account.
create table public.invites (
  id uuid primary key default gen_random_uuid(),
  inviter_id uuid references public.profiles(id) on delete cascade not null,
  contact text not null,
  name text,
  redeemed_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz default now(),
  unique (inviter_id, contact)
);
create index invites_contact_idx on public.invites(contact);

-- Indexes for common queries
create index tasks_receiver_idx on public.tasks(receiver_id);
create index tasks_sender_idx on public.tasks(sender_id);
create index tasks_status_idx on public.tasks(status);
create index tasks_invite_contact_idx on public.tasks(invite_contact) where invite_contact is not null;

-- ============================================================
-- Row Level Security
-- ============================================================

alter table public.profiles enable row level security;
alter table public.tasks enable row level security;
alter table public.invites enable row level security;

create policy "invites_select_own" on public.invites
  for select using (auth.uid() = inviter_id);
create policy "invites_insert_own" on public.invites
  for insert with check (auth.uid() = inviter_id);

create policy "profiles_select" on public.profiles
  for select using (true);

create policy "profiles_update" on public.profiles
  for update using (auth.uid() = id);

create policy "tasks_select" on public.tasks
  for select using (
    auth.uid() = receiver_id
    or (receiver_id is null and auth.uid() = sender_id)
    or auth.uid() = sender_id
    or invite_contact = (select email from public.profiles where id = auth.uid())
  );

create policy "tasks_insert" on public.tasks
  for insert with check (auth.uid() = sender_id);

create policy "tasks_update" on public.tasks
  for update using (
    auth.uid() = receiver_id
    or (receiver_id is null and auth.uid() = sender_id)
    or auth.uid() = sender_id
  );

-- ============================================================
-- Enable Realtime for tasks table
-- ============================================================

alter publication supabase_realtime add table public.tasks;

-- ============================================================
-- Migration helpers (run if you already applied an older schema)
-- ============================================================
-- alter table public.profiles add column if not exists email text;
-- alter table public.tasks add column if not exists assignee_name text;
-- alter table public.tasks add column if not exists invite_contact text;
-- create unique index if not exists invites_unique_contact on public.invites(inviter_id, contact);
