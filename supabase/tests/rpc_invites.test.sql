begin;
\ir _helpers.psql
select plan(16);

-- create_invite
select tests.login_as('00000000-0000-0000-0000-0000000000a1');
select set_config('tests.code', public.create_invite(), true);

select matches(current_setting('tests.code'), '^[A-Za-z0-9_-]{12}$', 'create_invite returns a 12-char URL-safe code');

reset role;
select ok(
  (select expires_at between now() + interval '7 days' - interval '1 minute' and now() + interval '7 days'
   from public.invites where code = current_setting('tests.code')),
  'invite expires in 7 days');
select is(
  (select inviter_id from public.invites where code = current_setting('tests.code')),
  '00000000-0000-0000-0000-0000000000a1'::uuid, 'invite belongs to the caller');

-- get_invite
select tests.login_as('00000000-0000-0000-0000-0000000000c0');
select results_eq(
  $$ select inviter_name, valid, reason from public.get_invite(current_setting('tests.code')) $$,
  $$ values ('Alice'::text, true, null::text) $$,
  'get_invite shows inviter name to a non-friend');
select is_empty($$ select * from public.get_invite('nope') $$, 'get_invite returns nothing for unknown code');

select tests.login_as('00000000-0000-0000-0000-0000000000a1');
select results_eq(
  $$ select valid, reason from public.get_invite(current_setting('tests.code')) $$,
  $$ values (false, 'this is your own invite'::text) $$,
  'get_invite flags own invite');

-- accept_invite: rejections
select throws_ok(
  $$ select public.accept_invite(current_setting('tests.code')) $$,
  'P0001', 'cannot accept your own invite', 'self-invite rejected');

select tests.login_as('00000000-0000-0000-0000-0000000000c0');
select throws_ok(
  $$ select public.accept_invite('does-not-exist') $$,
  'P0001', 'invite not found', 'unknown code rejected');

reset role;
insert into public.invites (code, inviter_id, created_at, expires_at)
values ('expired-code', '00000000-0000-0000-0000-0000000000a1', now() - interval '8 days', now() - interval '1 day');
select tests.login_as('00000000-0000-0000-0000-0000000000c0');
select throws_ok(
  $$ select public.accept_invite('expired-code') $$,
  'P0001', 'invite expired', 'expired code rejected');

-- accept_invite: success
select lives_ok(
  $$ select public.accept_invite(current_setting('tests.code')) $$,
  'carol accepts alice''s invite');

select results_eq(
  $$ select user_a, user_b from public.friendships where '00000000-0000-0000-0000-0000000000c0' in (user_a, user_b) $$,
  $$ values ('00000000-0000-0000-0000-0000000000a1'::uuid, '00000000-0000-0000-0000-0000000000c0'::uuid) $$,
  'friendship stored as ordered pair');

select results_eq(
  $$ select valid, reason from public.get_invite(current_setting('tests.code')) $$,
  $$ values (false, 'invite already used'::text) $$,
  'get_invite flags used invite');

select tests.login_as('00000000-0000-0000-0000-0000000000b0');
select throws_ok(
  $$ select public.accept_invite(current_setting('tests.code')) $$,
  'P0001', 'invite already used', 'used code rejected');

select isnt_empty(
  $$ select 1 from public.profiles where id = '00000000-0000-0000-0000-0000000000a1' $$,
  'new friends can read each other''s profiles');

-- Accepting an invite from an existing friend is a no-op on friendships.
select tests.login_as('00000000-0000-0000-0000-0000000000a1');
select set_config('tests.code2', public.create_invite(), true);
select tests.login_as('00000000-0000-0000-0000-0000000000b0');
select lives_ok(
  $$ select public.accept_invite(current_setting('tests.code2')) $$,
  'accepting an invite from an existing friend succeeds');

-- Anonymous
select tests.login_as_anon();
select throws_ok($$ select public.create_invite() $$, '42501', null, 'anon cannot create invites');

select * from finish();
rollback;
