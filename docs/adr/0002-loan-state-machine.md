# ADR 0002 — Loan state machine

Status: Accepted (2026-09-28)

## Context

A loan starts as a borrower's request and ends when it is declined, cancelled or the item comes back. Concurrent requests for the same item must not produce two active loans.

## Decision

`loans.status` is a Postgres enum `loan_status`:

```
             respond(accept)          mark_returned
requested ───────────────────▶ active ─────────────▶ returned
    │  │
    │  └── respond(decline) / auto-decline on another accept ──▶ declined
    └───── cancel_request ──────────────────────────────────────▶ cancelled
```

| Transition            | Function                                                     | Caller   | Timestamps set             |
| --------------------- | ------------------------------------------------------------ | -------- | -------------------------- |
| → requested           | `request_item`                                               | borrower | `requested_at`             |
| requested → active    | `respond_to_request(id, true)`                               | owner    | `started_at`               |
| requested → declined  | `respond_to_request(id, false)`, or another request accepted | owner    | `closed_at`                |
| requested → cancelled | `cancel_request`                                             | borrower | `closed_at`                |
| active → returned     | `mark_returned`                                              | owner    | `returned_at`, `closed_at` |

`declined`, `cancelled` and `returned` are terminal. `closed_at` is set on entry to any terminal state.

Invariants, enforced by the database:

- At most one `active` loan per item: partial unique index on `loans(item_id) where status = 'active'`.
- At most one open request per borrower per item: partial unique index on `loans(item_id, borrower_id) where status = 'requested'`.
- Each transition function locks the loan row (`select … for update`) and checks the current status, so concurrent calls serialize and the loser fails with a clear error. Accepting also locks the item row, so two accepts for one item cannot interleave.
- Accepting declines all other `requested` loans for the same item in the same transaction.

## Consequences

- Loans are an append-only history per item; re-requesting after a decline or cancel creates a new row.
- An item is "available" exactly when it has no `active` loan. Open requests do not block other requests.
- Adding states later (e.g. overdue, lost) means an enum change and new functions, not client changes.
