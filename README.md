# Loaners

A small installable web app for lending things to friends. Sign in with an email link, invite friends, list what you own, search what your friends own, and track requests, loans and returns.

Stack: SvelteKit + TypeScript, Tailwind CSS, Supabase (Postgres, Auth), deployed on Vercel. See [`docs/adr/`](docs/adr) for the reasoning and [`docs/plans/0001-poc.md`](docs/plans/0001-poc.md) for the POC plan.

## Prerequisites

- Node.js 22+
- Docker (for local Supabase)
- The Supabase CLI is a dev dependency; run it with `npx supabase`. The Vercel CLI is used through `npx vercel`.

## Local setup

```sh
npm install
npm run db:start                 # starts local Supabase, applies migrations and seed
cp .env.example .env.local       # then paste PUBLISHABLE_KEY from `npx supabase status`
npm run dev                      # http://localhost:5173
```

Sign in as a seeded user: enter `alice@example.com` or `bob@example.com` on `/login`, then open the link from Mailpit at <http://127.0.0.1:54324>. Alice and Bob are friends, each has 7–8 items and one item lent to the other.

Any other address creates a new account the same way.

## Environment variables

| Name                              | Where                | Value                                                                                         |
| --------------------------------- | -------------------- | --------------------------------------------------------------------------------------------- |
| `PUBLIC_SUPABASE_URL`             | `.env.local`, Vercel | Local: `http://127.0.0.1:54321`. Production: `https://<project-ref>.supabase.co`              |
| `PUBLIC_SUPABASE_PUBLISHABLE_KEY` | `.env.local`, Vercel | Publishable key (`sb_publishable_…`), or the legacy anon key. Dashboard → Settings → API Keys |

The app never needs the secret or service role key. `.env.local` is gitignored.

## Common commands

| Command                             | What it does                                                   |
| ----------------------------------- | -------------------------------------------------------------- |
| `npm run dev`                       | Dev server on port 5173                                        |
| `npm run check`                     | `svelte-check` (strict TypeScript)                             |
| `npm run lint` / `npm run format`   | Prettier + ESLint                                              |
| `npm run build`                     | Production build (Vercel adapter)                              |
| `npm run db:start` / `db:stop`      | Start or stop local Supabase                                   |
| `npm run db:reset`                  | Recreate the local database from migrations and `seed.sql`     |
| `npm run db:test`                   | Run pgTAP tests (`supabase test db`)                           |
| `npm run db:types`                  | Regenerate `src/lib/database.types.ts` from the local database |
| `npx supabase migration new <name>` | Create a new migration file                                    |

## Tests

Database rules are enforced in Postgres and tested with pgTAP:

```sh
npm run db:start
npm run db:test
```

Tests live in `supabase/tests/`. Each file includes `_helpers.psql`, which creates test users (alice, bob, carol) and switches roles with `tests.login_as(uuid)`. Every file runs in a transaction and rolls back.

Also run `npm run check`, `npm run lint` and `npm run build` before pushing.

## Deploying

### 1. Supabase

```sh
export SUPABASE_ACCESS_TOKEN=...          # supabase.com/dashboard/account/tokens
npx supabase link --project-ref <project-ref>   # prompts for the database password
npx supabase db push                       # applies supabase/migrations to the remote project
```

`seed.sql` is for local development only; `db push` does not run it.

Then configure Auth in the dashboard:

**Authentication → URL Configuration**

- Site URL: `https://<your-production-domain>`
- Redirect URLs:
  - `http://localhost:5173/**`
  - `https://<your-production-domain>/**`
  - `https://*-<vercel-team-slug>.vercel.app/**` (preview deployments)

**Authentication → Emails → Templates.** In both **Confirm signup** and **Magic Link**, replace the link with:

```html
<a href="{{ .RedirectTo }}?token_hash={{ .TokenHash }}&type=email">Sign in to Loaners</a>
```

The copies in `supabase/templates/` are what local Supabase uses. The app sets `RedirectTo` to `<origin>/auth/confirm`, so links work on production and preview domains, and in a different browser than the one that asked for the link. If a domain is missing from the redirect list, Supabase falls back to the Site URL; the app forwards that to `/auth/confirm` too.

**Authentication → Sign In / Providers → Email**: enabled, "Confirm email" on.

**Email delivery.** Supabase's built-in email service only sends to members of your Supabase organization and allows a few emails per hour. To sign in with other addresses, set up custom SMTP (e.g. Resend) under **Authentication → Emails → SMTP Settings**.

### 2. Vercel

```sh
npx vercel login                     # or export VERCEL_TOKEN=...
npx vercel link                      # create or pick the project
npx vercel git connect               # connect github.com/shoriminimoe/loaners
for env in production preview; do
  npx vercel env add PUBLIC_SUPABASE_URL $env
  npx vercel env add PUBLIC_SUPABASE_PUBLISHABLE_KEY $env
done
npx vercel --prod                    # first production deploy
```

After `git connect`, pushes to the production branch deploy to production and other branches get preview deployments. Preview deployments use the same Supabase project as production.

### 3. Schema changes

1. `npx supabase migration new <name>` and write SQL.
2. `npm run db:reset && npm run db:test && npm run db:types`.
3. Commit, then `npx supabase db push` to apply to production.

Never edit a migration that has already been pushed to the remote project; add a new one.

## Troubleshooting

- **"That sign-in link is invalid or expired"**: links are single-use and expire after an hour. Some email security scanners open links before you do; request a new one.
- **Magic link email never arrives in production**: see the email delivery note above, and check **Authentication → Logs**.
