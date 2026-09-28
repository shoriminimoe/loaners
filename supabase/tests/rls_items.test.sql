begin;
\ir _helpers.psql
select plan(13);

-- Owner
select tests.login_as('00000000-0000-0000-0000-0000000000a1');

select results_eq(
  $$ select name from public.items where owner_id = auth.uid() order by name $$,
  array['Coleman 4-person tent', 'Diary', 'Old camp stove'],
  'owner sees all own items including private and archived');

select lives_ok(
  $$ insert into public.items (name, note) values ('Headlamp', 'Black Diamond') $$,
  'owner can insert an item (owner_id defaults to caller)');

select throws_ok(
  $$ insert into public.items (owner_id, name) values ('00000000-0000-0000-0000-0000000000b0', 'Forged') $$,
  '42501', null, 'cannot insert an item owned by someone else');

select lives_ok(
  $$ update public.items set visibility = 'private' where id = '00000000-0000-0000-0001-0000000000a1' $$,
  'owner can toggle visibility');

select throws_ok(
  $$ update public.items set owner_id = '00000000-0000-0000-0000-0000000000b0' where id = '00000000-0000-0000-0001-0000000000a1' $$,
  '42501', null, 'owner cannot give an item away');

select lives_ok(
  $$ delete from public.items where name = 'Headlamp' $$,
  'owner can delete an item without loans');

-- Friend (restore the tent's visibility first)
reset role;
update public.items set visibility = 'friends' where id = '00000000-0000-0000-0001-0000000000a1';
select tests.login_as('00000000-0000-0000-0000-0000000000b0');

select results_eq(
  $$ select name from public.items where owner_id = '00000000-0000-0000-0000-0000000000a1' order by name $$,
  $$ values ('Coleman 4-person tent'::text) $$,
  'friend sees only friends-visible, non-archived items');
select is_empty(
  $$ select 1 from public.items where id = '00000000-0000-0000-0001-0000000000a2' $$,
  'friend cannot read a private item');

select is_empty(
  $$ select 1 from public.items where id = '00000000-0000-0000-0001-0000000000a3' $$,
  'friend cannot read an archived item');

select lives_ok(
  $$ update public.items set name = 'Mine now' where id = '00000000-0000-0000-0001-0000000000a1';
     delete from public.items where id = '00000000-0000-0000-0001-0000000000a1' $$,
  'friend update/delete of someone else''s item is filtered by RLS');

-- Non-friend
select tests.login_as('00000000-0000-0000-0000-0000000000c0');

select is_empty(
  $$ select 1 from public.items where owner_id <> auth.uid() $$,
  'non-friend sees no one else''s items');

-- Anonymous
select tests.login_as_anon();
select throws_ok(
  $$ select * from public.items $$,
  '42501', null, 'anon cannot read items');

reset role;
select is(
  (select name from public.items where id = '00000000-0000-0000-0001-0000000000a1'),
  'Coleman 4-person tent', 'friend''s write attempts had no effect');

select * from finish();
rollback;
