-- State changes are security definer functions called via RPC (ADR 0003).
-- Each resolves auth.uid() first and raises P0001 with a stable message on
-- any rule violation. Lock order is always item, then loan (ADR 0002).

-- Invites -------------------------------------------------------------------

create function public.create_invite()
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_code text;
begin
  if v_uid is null then
    raise exception 'not authenticated';
  end if;

  -- 9 random bytes -> 12 URL-safe base64 characters.
  v_code := translate(encode(extensions.gen_random_bytes(9), 'base64'), '+/', '-_');

  insert into public.invites (code, inviter_id, expires_at)
  values (v_code, v_uid, now() + interval '7 days');

  return v_code;
end;
$$;

-- Lets the invite page show who sent an invite before the two users are
-- friends. Returns no row for an unknown code.
create function public.get_invite(code text)
returns table (inviter_name text, valid boolean, reason text)
language sql
stable
security definer
set search_path = ''
as $$
  select
    p.display_name,
    r.reason is null,
    r.reason
  from public.invites i
  join public.profiles p on p.id = i.inviter_id
  cross join lateral (
    select case
      when auth.uid() is null then 'not authenticated'
      when i.inviter_id = auth.uid() then 'this is your own invite'
      when i.used_at is not null then 'invite already used'
      when i.expires_at <= now() then 'invite expired'
    end as reason
  ) r
  where i.code = get_invite.code;
$$;

create function public.accept_invite(code text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_invite public.invites;
begin
  if v_uid is null then
    raise exception 'not authenticated';
  end if;

  select i.* into v_invite
  from public.invites i
  where i.code = accept_invite.code
  for update;

  if not found then
    raise exception 'invite not found';
  end if;
  if v_invite.inviter_id = v_uid then
    raise exception 'cannot accept your own invite';
  end if;
  if v_invite.used_at is not null then
    raise exception 'invite already used';
  end if;
  if v_invite.expires_at <= now() then
    raise exception 'invite expired';
  end if;

  insert into public.friendships (user_a, user_b)
  values (least(v_uid, v_invite.inviter_id), greatest(v_uid, v_invite.inviter_id))
  on conflict do nothing;

  update public.invites i
  set used_by = v_uid, used_at = now()
  where i.code = v_invite.code;
end;
$$;

-- Loans ---------------------------------------------------------------------

create function public.request_item(item_id uuid, message text default null)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_item public.items;
  v_loan_id uuid;
begin
  if v_uid is null then
    raise exception 'not authenticated';
  end if;

  -- Share lock: concurrent requests proceed, an accept on this item waits.
  select i.* into v_item
  from public.items i
  where i.id = request_item.item_id
  for share;

  if not found then
    raise exception 'item not found';
  end if;
  if v_item.owner_id = v_uid then
    raise exception 'cannot request your own item';
  end if;
  if not exists (
    select 1 from public.friendships f
    where f.user_a = least(v_uid, v_item.owner_id)
      and f.user_b = greatest(v_uid, v_item.owner_id)
  ) then
    raise exception 'you can only request items from friends';
  end if;
  if v_item.visibility <> 'friends' then
    raise exception 'item is private';
  end if;
  if v_item.archived_at is not null then
    raise exception 'item is archived';
  end if;
  if exists (
    select 1 from public.loans l
    where l.item_id = v_item.id and l.status = 'active'
  ) then
    raise exception 'item is currently on loan';
  end if;
  if exists (
    select 1 from public.loans l
    where l.item_id = v_item.id and l.borrower_id = v_uid and l.status = 'requested'
  ) then
    raise exception 'you already have an open request for this item';
  end if;

  begin
    insert into public.loans (item_id, owner_id, borrower_id, message)
    values (v_item.id, v_item.owner_id, v_uid, nullif(btrim(request_item.message), ''))
    returning id into v_loan_id;
  exception when unique_violation then
    raise exception 'you already have an open request for this item';
  end;

  return v_loan_id;
end;
$$;

create function public.respond_to_request(loan_id uuid, accept boolean)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_item_id uuid;
  v_loan public.loans;
begin
  if v_uid is null then
    raise exception 'not authenticated';
  end if;

  select l.item_id into v_item_id
  from public.loans l
  where l.id = respond_to_request.loan_id
    and v_uid in (l.owner_id, l.borrower_id);

  if not found then
    raise exception 'loan not found';
  end if;

  perform 1 from public.items i where i.id = v_item_id for update;

  select l.* into v_loan
  from public.loans l
  where l.id = respond_to_request.loan_id
  for update;

  if v_loan.owner_id <> v_uid then
    raise exception 'only the owner can respond to a request';
  end if;
  if v_loan.status <> 'requested' then
    raise exception 'loan is not an open request';
  end if;

  if accept then
    if exists (
      select 1 from public.loans l
      where l.item_id = v_item_id and l.status = 'active'
    ) then
      raise exception 'item is already on loan';
    end if;

    update public.loans l
    set status = 'active', started_at = now()
    where l.id = v_loan.id;

    update public.loans l
    set status = 'declined', closed_at = now()
    where l.item_id = v_item_id and l.status = 'requested' and l.id <> v_loan.id;
  else
    update public.loans l
    set status = 'declined', closed_at = now()
    where l.id = v_loan.id;
  end if;
end;
$$;

create function public.cancel_request(loan_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_loan public.loans;
begin
  if v_uid is null then
    raise exception 'not authenticated';
  end if;

  select l.* into v_loan
  from public.loans l
  where l.id = cancel_request.loan_id
    and v_uid in (l.owner_id, l.borrower_id)
  for update;

  if not found then
    raise exception 'loan not found';
  end if;
  if v_loan.borrower_id <> v_uid then
    raise exception 'only the borrower can cancel a request';
  end if;
  if v_loan.status <> 'requested' then
    raise exception 'loan is not an open request';
  end if;

  update public.loans l
  set status = 'cancelled', closed_at = now()
  where l.id = v_loan.id;
end;
$$;

create function public.mark_returned(loan_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_loan public.loans;
begin
  if v_uid is null then
    raise exception 'not authenticated';
  end if;

  select l.* into v_loan
  from public.loans l
  where l.id = mark_returned.loan_id
    and v_uid in (l.owner_id, l.borrower_id)
  for update;

  if not found then
    raise exception 'loan not found';
  end if;
  if v_loan.owner_id <> v_uid then
    raise exception 'only the owner can mark a loan returned';
  end if;
  if v_loan.status <> 'active' then
    raise exception 'loan is not active';
  end if;

  update public.loans l
  set status = 'returned', returned_at = now(), closed_at = now()
  where l.id = v_loan.id;
end;
$$;

-- Search --------------------------------------------------------------------

-- Visible, non-archived items owned by the caller's friends. Security definer
-- because availability depends on loans, which friends cannot read.
-- Ranked by trigram word similarity of the query against name and note;
-- an empty query returns everything ordered by name.
create function public.search_friend_items(query text default '')
returns table (
  id uuid,
  name text,
  note text,
  owner_id uuid,
  owner_name text,
  available boolean,
  requested_by_me boolean,
  rank real
)
language sql
stable
security definer
set search_path = ''
as $$
  with q as (
    select btrim(coalesce(search_friend_items.query, '')) as term
  ),
  friend as (
    select case when f.user_a = auth.uid() then f.user_b else f.user_a end as id
    from public.friendships f
    where auth.uid() in (f.user_a, f.user_b)
  ),
  hit as (
    select
      i.*,
      case
        when q.term = '' then 0::real
        else greatest(
          extensions.word_similarity(q.term, i.name),
          coalesce(extensions.word_similarity(q.term, i.note), 0)
        )
      end as rank,
      q.term
    from public.items i
    join friend on friend.id = i.owner_id
    cross join q
    where i.visibility = 'friends'
      and i.archived_at is null
  )
  select
    h.id,
    h.name,
    h.note,
    h.owner_id,
    p.display_name,
    not exists (
      select 1 from public.loans l where l.item_id = h.id and l.status = 'active'
    ),
    exists (
      select 1 from public.loans l
      where l.item_id = h.id and l.borrower_id = auth.uid() and l.status = 'requested'
    ),
    h.rank
  from hit h
  join public.profiles p on p.id = h.owner_id
  where h.term = ''
     or h.term operator(extensions.<%) h.name
     or h.term operator(extensions.<%) h.note
     or strpos(lower(h.name), lower(h.term)) > 0
     or strpos(lower(coalesce(h.note, '')), lower(h.term)) > 0
  order by h.rank desc, h.name, h.id
  limit 200;
$$;

-- Privileges ----------------------------------------------------------------

revoke execute on function
  public.create_invite(),
  public.get_invite(text),
  public.accept_invite(text),
  public.request_item(uuid, text),
  public.respond_to_request(uuid, boolean),
  public.cancel_request(uuid),
  public.mark_returned(uuid),
  public.search_friend_items(text)
from public, anon;

grant execute on function
  public.create_invite(),
  public.get_invite(text),
  public.accept_invite(text),
  public.request_item(uuid, text),
  public.respond_to_request(uuid, boolean),
  public.cancel_request(uuid),
  public.mark_returned(uuid),
  public.search_friend_items(text)
to authenticated;
