begin;
\ir _helpers.psql
select plan(13);

select tests.login_as('00000000-0000-0000-0000-0000000000b0');
select set_config('tests.loan', public.request_item('00000000-0000-0000-0001-0000000000a1', null)::text, true);

-- cancel_request
select tests.login_as('00000000-0000-0000-0000-0000000000a1');
select throws_ok(
  $$ select public.cancel_request(current_setting('tests.loan')::uuid) $$,
  'P0001', 'only the borrower can cancel a request', 'owner cannot cancel a request');

select tests.login_as('00000000-0000-0000-0000-0000000000c0');
select throws_ok(
  $$ select public.cancel_request(current_setting('tests.loan')::uuid) $$,
  'P0001', 'loan not found', 'uninvolved user cannot cancel');

select tests.login_as('00000000-0000-0000-0000-0000000000b0');
select lives_ok(
  $$ select public.cancel_request(current_setting('tests.loan')::uuid) $$,
  'borrower cancels an open request');
select results_eq(
  $$ select status::text, closed_at is not null from public.loans where id = current_setting('tests.loan')::uuid $$,
  $$ values ('cancelled'::text, true) $$,
  'cancelled loan has closed_at');
select throws_ok(
  $$ select public.cancel_request(current_setting('tests.loan')::uuid) $$,
  'P0001', 'loan is not an open request', 'cannot cancel twice');

-- Cancel after accept is rejected.
select set_config('tests.loan', public.request_item('00000000-0000-0000-0001-0000000000a1', null)::text, true);
select tests.login_as('00000000-0000-0000-0000-0000000000a1');
select public.respond_to_request(current_setting('tests.loan')::uuid, true);
select tests.login_as('00000000-0000-0000-0000-0000000000b0');
select throws_ok(
  $$ select public.cancel_request(current_setting('tests.loan')::uuid) $$,
  'P0001', 'loan is not an open request', 'borrower cannot cancel an active loan');

-- mark_returned
select throws_ok(
  $$ select public.mark_returned(current_setting('tests.loan')::uuid) $$,
  'P0001', 'only the owner can mark a loan returned', 'borrower cannot mark returned');

select tests.login_as('00000000-0000-0000-0000-0000000000c0');
select throws_ok(
  $$ select public.mark_returned(current_setting('tests.loan')::uuid) $$,
  'P0001', 'loan not found', 'uninvolved user cannot mark returned');

select tests.login_as('00000000-0000-0000-0000-0000000000a1');
select lives_ok(
  $$ select public.mark_returned(current_setting('tests.loan')::uuid) $$,
  'owner marks an active loan returned');
select results_eq(
  $$ select status::text, returned_at is not null, closed_at is not null
     from public.loans where id = current_setting('tests.loan')::uuid $$,
  $$ values ('returned'::text, true, true) $$,
  'returned loan has returned_at and closed_at');
select throws_ok(
  $$ select public.mark_returned(current_setting('tests.loan')::uuid) $$,
  'P0001', 'loan is not active', 'cannot mark returned twice');

-- Requested (not active) loans cannot be marked returned.
select tests.login_as('00000000-0000-0000-0000-0000000000b0');
select set_config('tests.loan2', public.request_item('00000000-0000-0000-0001-0000000000a1', null)::text, true);
select tests.login_as('00000000-0000-0000-0000-0000000000a1');
select throws_ok(
  $$ select public.mark_returned(current_setting('tests.loan2')::uuid) $$,
  'P0001', 'loan is not active', 'cannot mark a requested loan returned');

select lives_ok(
  $$ select public.respond_to_request(current_setting('tests.loan2')::uuid, true) $$,
  'item can be lent again after return');

select * from finish();
rollback;
