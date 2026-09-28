begin;
\ir _helpers.psql
select plan(13);

-- Bob requests from alice. Alice's items: a1 tent (friends), a2 diary (private), a3 stove (archived).
select tests.login_as('00000000-0000-0000-0000-0000000000b0');

select isnt(
  public.request_item('00000000-0000-0000-0001-0000000000a1', '  Weekend trip?  '),
  null, 'friend can request a visible item');

select results_eq(
  $$ select status::text, owner_id, message from public.loans $$,
  $$ values ('requested'::text, '00000000-0000-0000-0000-0000000000a1'::uuid, 'Weekend trip?'::text) $$,
  'loan created as requested with owner copied and message trimmed');

select throws_ok(
  $$ select public.request_item('00000000-0000-0000-0001-0000000000a1', null) $$,
  'P0001', 'you already have an open request for this item', 'duplicate open request rejected');

select throws_ok(
  $$ select public.request_item('00000000-0000-0000-0001-0000000000b1', null) $$,
  'P0001', 'cannot request your own item', 'requesting own item rejected');

select throws_ok(
  $$ select public.request_item('00000000-0000-0000-0001-0000000000a2', null) $$,
  'P0001', 'item is private', 'private item rejected');

select throws_ok(
  $$ select public.request_item('00000000-0000-0000-0001-0000000000a3', null) $$,
  'P0001', 'item is archived', 'archived item rejected');

select throws_ok(
  $$ select public.request_item('00000000-0000-0000-0001-0000000000c1', null) $$,
  'P0001', 'you can only request items from friends', 'non-friend''s item rejected');

select throws_ok(
  $$ select public.request_item(gen_random_uuid(), null) $$,
  'P0001', 'item not found', 'unknown item rejected');

-- Empty message stored as null.
select tests.login_as('00000000-0000-0000-0000-0000000000a1');
select lives_ok(
  $$ select public.request_item('00000000-0000-0000-0001-0000000000b2', '   ') $$,
  'alice requests bob''s book');
reset role;
select is(
  (select message from public.loans where item_id = '00000000-0000-0000-0001-0000000000b2'),
  null, 'blank message stored as null');

-- Item on loan cannot be requested.
update public.loans set status = 'active', started_at = now()
where item_id = '00000000-0000-0000-0001-0000000000b2';
select tests.create_user('00000000-0000-0000-0000-0000000000d0', 'dave@test.local', 'Dave');
insert into public.friendships (user_a, user_b)
values ('00000000-0000-0000-0000-0000000000b0', '00000000-0000-0000-0000-0000000000d0');
select tests.login_as('00000000-0000-0000-0000-0000000000d0');
select throws_ok(
  $$ select public.request_item('00000000-0000-0000-0001-0000000000b2', null) $$,
  'P0001', 'item is currently on loan', 'item with an active loan rejected');

-- Re-request after cancel is allowed.
select tests.login_as('00000000-0000-0000-0000-0000000000b0');
select public.cancel_request((select id from public.loans where item_id = '00000000-0000-0000-0001-0000000000a1'));
select lives_ok(
  $$ select public.request_item('00000000-0000-0000-0001-0000000000a1', null) $$,
  're-request after cancel allowed');

select tests.login_as_anon();
select throws_ok(
  $$ select public.request_item('00000000-0000-0000-0001-0000000000a1', null) $$,
  '42501', null, 'anon cannot request items');

select * from finish();
rollback;
