begin;
\ir _helpers.psql
select plan(8);

select tests.login_as('00000000-0000-0000-0000-0000000000a1');

select results_eq(
  $$ select display_name from public.profiles order by display_name $$,
  array['Alice', 'Bob'],
  'alice reads her own and her friend''s profile, not a non-friend''s');

select is_empty(
  $$ select 1 from public.profiles where id = '00000000-0000-0000-0000-0000000000c0' $$,
  'alice cannot read non-friend carol''s profile');

select lives_ok(
  $$ update public.profiles set display_name = 'Alice A.' where id = '00000000-0000-0000-0000-0000000000a1' $$,
  'alice can update her own display name');

select lives_ok(
  $$ update public.profiles set display_name = 'Hacked' where id = '00000000-0000-0000-0000-0000000000b0' $$,
  'updating another profile is silently filtered by RLS');

select throws_ok(
  $$ update public.profiles set id = gen_random_uuid() where id = '00000000-0000-0000-0000-0000000000a1' $$,
  '42501', null, 'profile id cannot be changed');

select throws_ok(
  $$ insert into public.profiles (id, display_name) values (gen_random_uuid(), 'Mallory') $$,
  '42501', null, 'clients cannot insert profiles');

select tests.login_as('00000000-0000-0000-0000-0000000000c0');
select results_eq(
  $$ select display_name from public.profiles $$,
  array['Carol'],
  'a user with no friends sees only their own profile');

reset role;
select results_eq(
  $$ select display_name from public.profiles order by id $$,
  array['Alice A.', 'Bob', 'Carol'],
  'only alice''s own update took effect');

select * from finish();
rollback;
