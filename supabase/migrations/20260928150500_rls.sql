-- Row-level security and table privileges (ADR 0003).
-- Supabase grants all table privileges to anon and authenticated by default;
-- replace that with the minimum each table needs.

revoke all on public.profiles, public.friendships, public.invites, public.items, public.loans
  from anon, authenticated;

-- profiles: readable by self and friends; users may change only their own display name.
grant select on public.profiles to authenticated;
grant update (display_name) on public.profiles to authenticated;

create policy profiles_select_self_or_friend on public.profiles
  for select to authenticated
  using (id = (select auth.uid()) or private.is_friend(id));

create policy profiles_update_self on public.profiles
  for update to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));

-- friendships: readable by either member; written only by accept_invite.
grant select on public.friendships to authenticated;

create policy friendships_select_member on public.friendships
  for select to authenticated
  using ((select auth.uid()) in (user_a, user_b));

-- invites: readable by the inviter and the user who used it; written only by RPC.
grant select on public.invites to authenticated;

create policy invites_select_involved on public.invites
  for select to authenticated
  using ((select auth.uid()) in (inviter_id, used_by));

-- items: owner has full access; friends read visible, non-archived items.
grant select, insert, update, delete on public.items to authenticated;

create policy items_select_owner on public.items
  for select to authenticated
  using (owner_id = (select auth.uid()));

create policy items_select_friends on public.items
  for select to authenticated
  using (visibility = 'friends' and archived_at is null and private.is_friend(owner_id));

create policy items_insert_owner on public.items
  for insert to authenticated
  with check (owner_id = (select auth.uid()));

create policy items_update_owner on public.items
  for update to authenticated
  using (owner_id = (select auth.uid()))
  with check (owner_id = (select auth.uid()));

create policy items_delete_owner on public.items
  for delete to authenticated
  using (owner_id = (select auth.uid()));

-- loans: readable by owner and borrower; written only by RPC.
grant select on public.loans to authenticated;

create policy loans_select_involved on public.loans
  for select to authenticated
  using ((select auth.uid()) in (owner_id, borrower_id));
