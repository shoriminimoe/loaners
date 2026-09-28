# ADR 0001 — Stack: SvelteKit, Supabase, Vercel

Status: Accepted (2026-09-28)

## Context

Loaners is a small mobile-first PWA for lending items among friends. The POC must prove one loop end to end with real accounts, with minimal dependencies and no design polish.

## Decision

- **SvelteKit** (Svelte 5 runes, TypeScript strict) with **Tailwind CSS v4** via `@tailwindcss/vite`.
- **Supabase** for Postgres, Auth (email magic link) and the API. `@supabase/ssr` creates a per-request server client in `hooks.server.ts`; sessions live in cookies.
- **Vercel** hosting through `@sveltejs/adapter-vercel`, connected to the GitHub repo.
- All data access runs on the server (`load` functions and form actions) with the user's session. The browser never talks to Supabase directly and the app never holds the service role key.
- No UI component libraries, no state management libraries. Forms are progressively enhanced with `use:enhance`.
- PWA: web app manifest and icons only. No service worker yet.

The task brief used Next.js terms ("App Router", "server components", "middleware"). They map to SvelteKit as: middleware → `hooks.server.ts`; server components → `+page.server.ts` `load` and actions.

## Consequences

- Every page works without client-side JavaScript state; one round trip per action.
- Business rules live in Postgres (see ADR 0003), so the app layer stays thin and replaceable.
- Offline support and push notifications need a service worker later.
