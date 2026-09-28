create table public.items (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null default auth.uid() references public.profiles (id) on delete cascade,
  name text not null check (char_length(btrim(name)) between 1 and 100),
  note text check (char_length(note) <= 1000),
  visibility text not null default 'friends' check (visibility in ('friends', 'private')),
  archived_at timestamptz,
  created_at timestamptz not null default now()
);

create index items_owner_id_idx on public.items (owner_id);
create index items_name_trgm_idx on public.items using gin (name extensions.gin_trgm_ops);
create index items_note_trgm_idx on public.items using gin (note extensions.gin_trgm_ops);

alter table public.items enable row level security;
