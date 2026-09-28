begin;
\ir _helpers.psql
select plan(14);

select has_extension('pg_trgm', 'pg_trgm is installed');

select ok((select relrowsecurity from pg_class where oid = 'public.profiles'::regclass), 'RLS on profiles');
select ok((select relrowsecurity from pg_class where oid = 'public.invites'::regclass), 'RLS on invites');
select ok((select relrowsecurity from pg_class where oid = 'public.friendships'::regclass), 'RLS on friendships');
select ok((select relrowsecurity from pg_class where oid = 'public.items'::regclass), 'RLS on items');
select ok((select relrowsecurity from pg_class where oid = 'public.loans'::regclass), 'RLS on loans');

select is(
  (select count(*)::int from pg_class c join pg_namespace n on n.oid = c.relnamespace
   where n.nspname = 'public' and c.relkind = 'r' and not c.relrowsecurity),
  0, 'every public table has RLS enabled');

select has_index('public', 'loans', 'loans_one_active_per_item_idx', 'one-active-loan index exists');
select has_index('public', 'loans', 'loans_one_open_request_idx', 'one-open-request index exists');
select has_index('public', 'items', 'items_name_trgm_idx', 'trigram index on items.name');
select has_index('public', 'items', 'items_note_trgm_idx', 'trigram index on items.note');

select is(
  (select display_name from public.profiles where id = '00000000-0000-0000-0000-0000000000a1'),
  'Alice', 'signup trigger creates a profile');

select throws_ok(
  $$ insert into public.friendships (user_a, user_b)
     values ('00000000-0000-0000-0000-0000000000b0', '00000000-0000-0000-0000-0000000000a1') $$,
  '23514', null, 'friendships must be stored as an ordered pair');

select throws_ok(
  $$ insert into public.loans (item_id, owner_id, borrower_id, status, started_at)
     values ('00000000-0000-0000-0001-0000000000b2', '00000000-0000-0000-0000-0000000000b0',
             '00000000-0000-0000-0000-0000000000a1', 'active', now()),
            ('00000000-0000-0000-0001-0000000000b2', '00000000-0000-0000-0000-0000000000b0',
             '00000000-0000-0000-0000-0000000000c0', 'active', now()) $$,
  '23505', null, 'database rejects two active loans for one item');

select * from finish();
rollback;
