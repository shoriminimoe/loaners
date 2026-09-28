begin;
\ir _helpers.psql
select plan(10);

-- More of bob's items for ranking.
insert into public.items (owner_id, name, note) values
  ('00000000-0000-0000-0000-0000000000b0', 'Ultralight tent', 'Two person, 1.2kg'),
  ('00000000-0000-0000-0000-0000000000b0', 'Camping chairs', 'Pair of folding chairs, good for a tent site');

select tests.login_as('00000000-0000-0000-0000-0000000000a1');

select results_eq(
  $$ select name from public.search_friend_items('') order by name $$,
  array['Camping chairs', 'Dune', 'Ultralight tent', 'Zelda: Breath of the Wild'],
  'empty query returns all visible, non-archived friend items');

select results_eq(
  $$ select name from public.search_friend_items(null) order by name $$,
  array['Camping chairs', 'Dune', 'Ultralight tent', 'Zelda: Breath of the Wild'],
  'null query behaves like empty');

select is_empty(
  $$ select 1 from public.search_friend_items('') where owner_id = auth.uid() $$,
  'own items are excluded');

select is_empty(
  $$ select 1 from public.search_friend_items('kayak') $$,
  'non-friend items are excluded');

select is_empty(
  $$ select 1 from public.search_friend_items('sleeping') $$,
  'private friend items are excluded');

select results_eq(
  $$ select name from public.search_friend_items('tent') $$,
  array['Ultralight tent', 'Camping chairs'],
  'name match ranks above note match');

select results_eq(
  $$ select name from public.search_friend_items('zelda') $$,
  array['Zelda: Breath of the Wild'],
  'case-insensitive name search');

select results_eq(
  $$ select owner_name, available, requested_by_me from public.search_friend_items('dune') $$,
  $$ values ('Bob'::text, true, false) $$,
  'result includes owner name and availability');

select public.request_item('00000000-0000-0000-0001-0000000000b2', null);
select results_eq(
  $$ select available, requested_by_me from public.search_friend_items('dune') $$,
  $$ values (true, true) $$,
  'open request does not affect availability but is flagged for the requester');

select tests.login_as('00000000-0000-0000-0000-0000000000b0');
select public.respond_to_request((select id from public.loans where item_id = '00000000-0000-0000-0001-0000000000b2'), true);
select tests.login_as('00000000-0000-0000-0000-0000000000a1');
select results_eq(
  $$ select available from public.search_friend_items('dune') $$,
  array[false],
  'active loan marks the item unavailable');

select * from finish();
rollback;
