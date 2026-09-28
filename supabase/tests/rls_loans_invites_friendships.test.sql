begin;
\ir _helpers.psql
select plan(15);

-- Fixtures written as postgres: bob requested alice's tent; alice invited carol.
insert into public.loans (id, item_id, owner_id, borrower_id)
values ('00000000-0000-0000-0002-000000000001', '00000000-0000-0000-0001-0000000000a1',
        '00000000-0000-0000-0000-0000000000a1', '00000000-0000-0000-0000-0000000000b0');
insert into public.invites (code, inviter_id) values ('alice-code', '00000000-0000-0000-0000-0000000000a1');

-- Loans
select tests.login_as('00000000-0000-0000-0000-0000000000a1');
select isnt_empty($$ select 1 from public.loans $$, 'owner reads the loan');
select tests.login_as('00000000-0000-0000-0000-0000000000b0');
select isnt_empty($$ select 1 from public.loans $$, 'borrower reads the loan');
select tests.login_as('00000000-0000-0000-0000-0000000000c0');
select is_empty($$ select 1 from public.loans $$, 'uninvolved user cannot read the loan');

select tests.login_as('00000000-0000-0000-0000-0000000000b0');
select throws_ok(
  $$ insert into public.loans (item_id, owner_id, borrower_id)
     values ('00000000-0000-0000-0001-0000000000a1', '00000000-0000-0000-0000-0000000000a1',
             '00000000-0000-0000-0000-0000000000b0') $$,
  '42501', null, 'clients cannot insert loans');
select throws_ok(
  $$ update public.loans set status = 'active', started_at = now() $$,
  '42501', null, 'clients cannot update loans');
select throws_ok(
  $$ delete from public.loans $$,
  '42501', null, 'clients cannot delete loans');

-- Friendships
select tests.login_as('00000000-0000-0000-0000-0000000000a1');
select isnt_empty($$ select 1 from public.friendships $$, 'member reads the friendship');
select tests.login_as('00000000-0000-0000-0000-0000000000c0');
select is_empty($$ select 1 from public.friendships $$, 'non-member cannot read the friendship');
select throws_ok(
  $$ insert into public.friendships (user_a, user_b)
     values ('00000000-0000-0000-0000-0000000000a1', '00000000-0000-0000-0000-0000000000c0') $$,
  '42501', null, 'clients cannot insert friendships');
select throws_ok(
  $$ delete from public.friendships $$,
  '42501', null, 'clients cannot delete friendships');

-- Invites
select tests.login_as('00000000-0000-0000-0000-0000000000a1');
select isnt_empty($$ select 1 from public.invites $$, 'inviter reads the invite');
select tests.login_as('00000000-0000-0000-0000-0000000000b0');
select is_empty($$ select 1 from public.invites $$, 'other users cannot read the invite');
select throws_ok(
  $$ insert into public.invites (code, inviter_id) values ('forged', '00000000-0000-0000-0000-0000000000b0') $$,
  '42501', null, 'clients cannot insert invites');
select throws_ok(
  $$ update public.invites set used_by = auth.uid(), used_at = now() $$,
  '42501', null, 'clients cannot update invites');

-- Anonymous
select tests.login_as_anon();
select throws_ok($$ select * from public.loans $$, '42501', null, 'anon cannot read loans');

select * from finish();
rollback;
