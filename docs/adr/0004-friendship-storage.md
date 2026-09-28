# ADR 0004 — Friendship storage as a canonical ordered pair

Status: Accepted (2026-09-28)

## Context

Friendship is symmetric. Storing it as two directed rows risks the rows drifting apart; storing one row in arbitrary order makes duplicates and lookups awkward.

## Decision

`friendships (user_a uuid, user_b uuid, created_at)` with:

- `check (user_a < user_b)`
- `primary key (user_a, user_b)`
- an index on `user_b` for lookups from the other side.

Writers insert `(least(x, y), greatest(x, y))`. `accept_invite` uses `on conflict do nothing`, so accepting a second invite from an existing friend is a no-op.

Readers use `public.is_friend(a, b)` for membership tests and a `union all` over both columns to list a user's friends.

## Consequences

- One row per friendship; duplicates and self-friendship are impossible by construction.
- Every "friends of X" query checks both columns. The helper function keeps that in one place.
- Unfriending, when added, is a single-row delete.
