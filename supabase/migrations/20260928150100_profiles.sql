create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  -- Null until the user picks a name on first login.
  display_name text check (
    display_name is null
    or char_length(btrim(display_name)) between 1 and 50
  ),
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

create function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id) values (new.id);
  return new;
end;
$$;

revoke execute on function public.handle_new_user() from public, anon, authenticated;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
