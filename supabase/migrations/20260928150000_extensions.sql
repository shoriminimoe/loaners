-- Trigram search on item names and notes; pgcrypto for invite codes.
create extension if not exists pg_trgm with schema extensions;
create extension if not exists pgcrypto with schema extensions;

-- Helpers used by RLS policies live here. PostgREST does not expose this
-- schema, so these functions cannot be called directly as RPC.
create schema if not exists private;
revoke all on schema private from public;
grant usage on schema private to authenticated;
