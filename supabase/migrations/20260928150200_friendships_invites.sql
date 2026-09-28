-- One row per friendship, stored as an ordered pair (ADR 0004).
create table public.friendships (
  user_a uuid not null references public.profiles (id) on delete cascade,
  user_b uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_a, user_b),
  check (user_a < user_b)
);

create index friendships_user_b_idx on public.friendships (user_b);

alter table public.friendships enable row level security;

create table public.invites (
  code text primary key,
  inviter_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default now() + interval '7 days',
  used_by uuid references public.profiles (id) on delete cascade,
  used_at timestamptz
);

create index invites_inviter_id_idx on public.invites (inviter_id);
create index invites_used_by_idx on public.invites (used_by);

alter table public.invites enable row level security;

-- True when the current user and `other` are friends. Security definer so
-- policies can call it without recursing into friendships RLS.
create function private.is_friend(other uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.friendships f
    where f.user_a = least((select auth.uid()), other)
      and f.user_b = greatest((select auth.uid()), other)
  );
$$;

revoke execute on function private.is_friend(uuid) from public, anon;
grant execute on function private.is_friend(uuid) to authenticated;
