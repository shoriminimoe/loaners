begin;
\ir _helpers.psql
select plan(14);

-- Bob and dave (both alice's friends) request alice's tent.
select tests.create_user('00000000-0000-0000-0000-0000000000d0', 'dave@test.local', 'Dave');
insert into public.friendships (user_a, user_b)
values ('00000000-0000-0000-0000-0000000000a1', '00000000-0000-0000-0000-0000000000d0');

select tests.login_as('00000000-0000-0000-0000-0000000000b0');
select set_config('tests.bob_loan', public.request_item('00000000-0000-0000-0001-0000000000a1', null)::text, true);
select tests.login_as('00000000-0000-0000-0000-0000000000d0');
select set_config('tests.dave_loan', public.request_item('00000000-0000-0000-0001-0000000000a1', null)::text, true);

-- Borrower cannot respond; strangers cannot see the loan.
select tests.login_as('00000000-0000-0000-0000-0000000000b0');
select throws_ok(
  $$ select public.respond_to_request(current_setting('tests.bob_loan')::uuid, true) $$,
  'P0001', 'only the owner can respond to a request', 'borrower cannot accept their own request');

select tests.login_as('00000000-0000-0000-0000-0000000000c0');
select throws_ok(
  $$ select public.respond_to_request(current_setting('tests.bob_loan')::uuid, true) $$,
  'P0001', 'loan not found', 'uninvolved user cannot respond');

-- Owner accepts bob.
select tests.login_as('00000000-0000-0000-0000-0000000000a1');
select lives_ok(
  $$ select public.respond_to_request(current_setting('tests.bob_loan')::uuid, true) $$,
  'owner accepts a request');

select results_eq(
  $$ select status::text, started_at is not null, closed_at is null
     from public.loans where id = current_setting('tests.bob_loan')::uuid $$,
  $$ values ('active'::text, true, true) $$,
  'accepted loan is active with started_at');

select results_eq(
  $$ select status::text, closed_at is not null
     from public.loans where id = current_setting('tests.dave_loan')::uuid $$,
  $$ values ('declined'::text, true) $$,
  'other open requests for the item are declined');

select throws_ok(
  $$ select public.respond_to_request(current_setting('tests.bob_loan')::uuid, false) $$,
  'P0001', 'loan is not an open request', 'cannot respond to an active loan');

select throws_ok(
  $$ select public.respond_to_request(current_setting('tests.dave_loan')::uuid, true) $$,
  'P0001', 'loan is not an open request', 'cannot accept a declined request');

-- Double active loan: force a second open request past request_item's checks.
reset role;
insert into public.loans (id, item_id, owner_id, borrower_id)
values ('00000000-0000-0000-0002-0000000000d0', '00000000-0000-0000-0001-0000000000a1',
        '00000000-0000-0000-0000-0000000000a1', '00000000-0000-0000-0000-0000000000d0');
select tests.login_as('00000000-0000-0000-0000-0000000000a1');
select throws_ok(
  $$ select public.respond_to_request('00000000-0000-0000-0002-0000000000d0', true) $$,
  'P0001', 'item is already on loan', 'accepting a second loan for an active item fails');
select is(
  (select count(*)::int from public.loans where item_id = '00000000-0000-0000-0001-0000000000a1' and status = 'active'),
  1, 'still exactly one active loan');

-- Decline path.
select lives_ok(
  $$ select public.respond_to_request('00000000-0000-0000-0002-0000000000d0', false) $$,
  'owner declines a request');
select results_eq(
  $$ select status::text, closed_at is not null, started_at is null
     from public.loans where id = '00000000-0000-0000-0002-0000000000d0' $$,
  $$ values ('declined'::text, true, true) $$,
  'declined loan has closed_at and no started_at');

-- Re-request after decline is allowed once the item is back.
select public.mark_returned(current_setting('tests.bob_loan')::uuid);
select tests.login_as('00000000-0000-0000-0000-0000000000d0');
select lives_ok(
  $$ select public.request_item('00000000-0000-0000-0001-0000000000a1', 'Second try') $$,
  're-request after decline allowed');

select throws_ok(
  $$ select public.respond_to_request(gen_random_uuid(), true) $$,
  'P0001', 'loan not found', 'unknown loan rejected');

select tests.login_as_anon();
select throws_ok(
  $$ select public.respond_to_request(current_setting('tests.bob_loan')::uuid, true) $$,
  '42501', null, 'anon cannot respond');

select * from finish();
rollback;
