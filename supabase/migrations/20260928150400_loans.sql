-- Loan lifecycle (ADR 0002).
create type public.loan_status as enum ('requested', 'declined', 'cancelled', 'active', 'returned');

create table public.loans (
  id uuid primary key default gen_random_uuid(),
  item_id uuid not null references public.items (id) on delete restrict,
  -- Copied from items.owner_id by request_item.
  owner_id uuid not null references public.profiles (id) on delete cascade,
  borrower_id uuid not null references public.profiles (id) on delete cascade,
  status public.loan_status not null default 'requested',
  message text check (char_length(message) <= 500),
  requested_at timestamptz not null default now(),
  started_at timestamptz,
  returned_at timestamptz,
  closed_at timestamptz,
  check (owner_id <> borrower_id),
  check ((status in ('active', 'returned')) = (started_at is not null)),
  check ((status = 'returned') = (returned_at is not null)),
  check ((status in ('declined', 'cancelled', 'returned')) = (closed_at is not null))
);

-- At most one active loan per item.
create unique index loans_one_active_per_item_idx on public.loans (item_id) where status = 'active';
-- At most one open request per borrower per item.
create unique index loans_one_open_request_idx on public.loans (item_id, borrower_id) where status = 'requested';
create index loans_owner_id_idx on public.loans (owner_id);
create index loans_borrower_id_idx on public.loans (borrower_id);

alter table public.loans enable row level security;
