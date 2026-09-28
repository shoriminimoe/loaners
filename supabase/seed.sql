-- Local development seed. Never run against the remote project.
--
-- Two friends, alice@example.com and bob@example.com. Sign in with a magic
-- link; emails arrive in Mailpit at http://127.0.0.1:54324.

-- Users --------------------------------------------------------------------
-- GoTrue expects the token/email_change columns to be '' rather than null.

insert into auth.users (
  id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
  confirmation_token, recovery_token, email_change_token_new, email_change
) values
  ('a11ce000-0000-4000-8000-000000000001', '00000000-0000-0000-0000-000000000000',
   'authenticated', 'authenticated', 'alice@example.com', '', now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', ''),
  ('b0b00000-0000-4000-8000-000000000002', '00000000-0000-0000-0000-000000000000',
   'authenticated', 'authenticated', 'bob@example.com', '', now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', '');

insert into auth.identities (
  id, user_id, provider_id, provider, identity_data, last_sign_in_at, created_at, updated_at
) values
  (gen_random_uuid(), 'a11ce000-0000-4000-8000-000000000001', 'a11ce000-0000-4000-8000-000000000001', 'email',
   '{"sub":"a11ce000-0000-4000-8000-000000000001","email":"alice@example.com","email_verified":true}',
   now(), now(), now()),
  (gen_random_uuid(), 'b0b00000-0000-4000-8000-000000000002', 'b0b00000-0000-4000-8000-000000000002', 'email',
   '{"sub":"b0b00000-0000-4000-8000-000000000002","email":"bob@example.com","email_verified":true}',
   now(), now(), now());

-- Profiles are created by the signup trigger; set display names.
update public.profiles set display_name = 'Alice' where id = 'a11ce000-0000-4000-8000-000000000001';
update public.profiles set display_name = 'Bob' where id = 'b0b00000-0000-4000-8000-000000000002';

-- Friendship (ordered pair) -------------------------------------------------

insert into public.friendships (user_a, user_b)
values ('a11ce000-0000-4000-8000-000000000001', 'b0b00000-0000-4000-8000-000000000002');

-- Items ----------------------------------------------------------------------

insert into public.items (id, owner_id, name, note, visibility) values
  -- Alice
  ('a1000000-0000-4000-8000-000000000001', 'a11ce000-0000-4000-8000-000000000001', 'The Legend of Zelda: Tears of the Kingdom', 'Nintendo Switch cartridge', 'friends'),
  ('a1000000-0000-4000-8000-000000000002', 'a11ce000-0000-4000-8000-000000000001', 'Hades', 'PS5 disc', 'friends'),
  ('a1000000-0000-4000-8000-000000000003', 'a11ce000-0000-4000-8000-000000000001', 'Project Hail Mary', 'Andy Weir, hardcover', 'friends'),
  ('a1000000-0000-4000-8000-000000000004', 'a11ce000-0000-4000-8000-000000000001', 'The Left Hand of Darkness', 'Ursula K. Le Guin, paperback', 'friends'),
  ('a1000000-0000-4000-8000-000000000005', 'a11ce000-0000-4000-8000-000000000001', 'REI Half Dome 2 tent', 'Two-person backpacking tent with footprint', 'friends'),
  ('a1000000-0000-4000-8000-000000000006', 'a11ce000-0000-4000-8000-000000000001', 'Camp stove', 'Coleman two-burner, propane not included', 'friends'),
  ('a1000000-0000-4000-8000-000000000007', 'a11ce000-0000-4000-8000-000000000001', 'Headlamp', 'Black Diamond Spot, AAA batteries', 'friends'),
  ('a1000000-0000-4000-8000-000000000008', 'a11ce000-0000-4000-8000-000000000001', 'Signed first edition', 'Not for lending', 'private'),
  -- Bob
  ('b1000000-0000-4000-8000-000000000001', 'b0b00000-0000-4000-8000-000000000002', 'Mario Kart 8 Deluxe', 'Nintendo Switch cartridge', 'friends'),
  ('b1000000-0000-4000-8000-000000000002', 'b0b00000-0000-4000-8000-000000000002', 'Elden Ring', 'PS5 disc', 'friends'),
  ('b1000000-0000-4000-8000-000000000003', 'b0b00000-0000-4000-8000-000000000002', 'Stardew Valley', 'Nintendo Switch cartridge', 'friends'),
  ('b1000000-0000-4000-8000-000000000004', 'b0b00000-0000-4000-8000-000000000002', 'Dune', 'Frank Herbert, paperback', 'friends'),
  ('b1000000-0000-4000-8000-000000000005', 'b0b00000-0000-4000-8000-000000000002', 'The Hobbit', 'Illustrated edition', 'friends'),
  ('b1000000-0000-4000-8000-000000000006', 'b0b00000-0000-4000-8000-000000000002', 'Sleeping bag', 'Rated to -7C, mummy style', 'friends'),
  ('b1000000-0000-4000-8000-000000000007', 'b0b00000-0000-4000-8000-000000000002', 'Water filter', 'Sawyer Squeeze', 'friends');

-- Loans: one active loan in each direction ----------------------------------

insert into public.loans (item_id, owner_id, borrower_id, status, message, requested_at, started_at) values
  ('a1000000-0000-4000-8000-000000000003', 'a11ce000-0000-4000-8000-000000000001', 'b0b00000-0000-4000-8000-000000000002',
   'active', 'Heard this one is great', now() - interval '10 days', now() - interval '9 days'),
  ('b1000000-0000-4000-8000-000000000001', 'b0b00000-0000-4000-8000-000000000002', 'a11ce000-0000-4000-8000-000000000001',
   'active', 'For game night', now() - interval '3 days', now() - interval '2 days');
