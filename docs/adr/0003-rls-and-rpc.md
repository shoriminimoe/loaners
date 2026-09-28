# ADR 0003 — Row-level security for reads, RPC for state changes

Status: Accepted (2026-09-28)

## Context

Supabase exposes tables through PostgREST, so any rule not in the database can be bypassed by calling the API directly. Loans, invites and friendships have multi-step rules (friendship checks, status transitions, cross-row side effects) that plain RLS `with check` clauses express poorly.

## Decision

- **RLS is enabled on every table in `public`.** `anon` has no table privileges.
- **Reads go through RLS policies:**
  - `profiles`: self or friend.
  - `items`: owner sees all own items; friends see `visibility = 'friends' and archived_at is null`.
  - `loans`: owner or borrower.
  - `invites`: inviter or the user who used it.
  - `friendships`: either member.
- **Direct writes are allowed only where there are no cross-row rules:**
  - `items`: owner insert/update/delete, `with check (owner_id = auth.uid())`.
  - `profiles`: owner update, and only the `display_name` column is granted.
- **Everything else changes through `security definer` functions** called via RPC: `create_invite`, `get_invite`, `accept_invite`, `request_item`, `respond_to_request`, `cancel_request`, `mark_returned`, `search_friend_items`. Clients get no insert/update/delete privilege on `loans`, `invites` or `friendships`.
- Function conventions:
  - `set search_path = ''` and fully qualified names.
  - First statement resolves `auth.uid()` and raises if null.
  - Rule violations raise with SQLSTATE `P0001` and a stable, human-readable message; tests assert on the message.
  - `execute` revoked from `public` and `anon`, granted to `authenticated`.
- **`public.is_friend(a, b)`** is a `security definer`, `stable` SQL helper used inside policies, so a policy on one table does not trigger RLS on `friendships` recursively.
- `search_friend_items` is `security definer` because availability depends on `loans`, which friends cannot read. It filters to the caller's friends explicitly and returns only item fields, owner display name and an `available` boolean.

## Consequences

- The client surface is small and auditable: a few policies and eight functions, all covered by pgTAP tests.
- `security definer` functions bypass RLS, so each must check authorization itself. Tests cover the negative cases for each rule.
- Changing a rule means a migration, never an app deploy.
