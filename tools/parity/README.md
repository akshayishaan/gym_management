# Parity Harness

Compares the Next.js and NestJS backends (which share a MongoDB/Atlas
database) by running an identical, deterministic call sequence against each
and diffing the normalized transcripts.

## Prerequisites

- Both servers running against the **same Atlas database**:
  - Next.js on `http://localhost:3000` (env `NEXT_BASE`)
  - NestJS on `http://localhost:3001` (env `NEST_BASE`)
- Node 24.x (`npm install` in this directory).

## Run order

Each backend run is fully independent: it signs up its **own** admin
(`EMAIL` defaults to a backend-distinct `parity+<RUN_ID>+<next|nest>@example.com`),
seeds its own gym + plans + members under a backend-distinct name, then runs
the probes + reads. The two runs share the Atlas cluster but are isolated by
gym scoping, so they never collide or mutate each other's data. The
normalization layer masks volatile ids/invoices/dates, so the two independent
seeds diff cleanly.

`next` and `nest` can run in **either order** (or in parallel); run both, then
`diff`.

```bash
RUN_ID=run1 BACKEND=next  npm run harness   # seed + probes/reads via Next.js
RUN_ID=run1 BACKEND=nest  npm run harness   # seed + probes/reads via NestJS
RUN_ID=run1               npm run diff      # print pass/fail summary, exit 1 on mismatch
```

## Environment variables

| Variable     | Required | Default                              | Notes                                        |
| ------------ | -------- | ------------------------------------ | -------------------------------------------- |
| `BACKEND`    | yes      | —                                    | `next` or `nest`                             |
| `RUN_ID`     | yes      | —                                    | unique id per parity run (keys file names)   |
| `NEXT_BASE`  | no       | `http://localhost:3000`              | base URL of the Next.js server               |
| `NEST_BASE`  | no       | `http://localhost:3001`              | base URL of the NestJS server                |
| `EMAIL`      | no       | `parity+<RUN_ID>+<next\|nest>@example.com` | admin account (auto-signup/409 tolerated) |
| `PASSWORD`   | no       | `Admin123!`                          | admin password                               |
| `ADMIN_NAME` | no       | `Parity Admin`                       | admin display name                           |

Transcripts land in `out/parity.<RUN_ID>.<BACKEND>.json`. `out/` is
git-ignored.

## Verifying server-computed display status

The NestJS backend computes gym-local **display status** fields server-side
(ADR-0005); the Next.js API does **not** return them (the web derives them
client-side). These fields are therefore NestJS-only:

| Field                          | Location                                        | Meaning                                   |
| ------------------------------ | ----------------------------------------------- | ----------------------------------------- |
| `member.status`                | member list / member detail                     | `active` \| `expiring` \| `expired`       |
| `member.daysUntilExpiry`       | member list / member detail                     | days until `membershipExpiry`             |
| `membership.expiryStatus`      | membership history                              | `active` \| `expiring` \| `expired`       |
| `membership.durationDays`      | membership history                              | inclusive days (`start`→`expiry` + 1)     |
| `expiringList[].daysUntilExpiry` | dashboard                                     | days until `membershipExpiry`             |

They cannot be diffed (the Next side would always show `<missing>`), so the
normalization layer **drops** them, and a dedicated verifier re-derives them
from the seed's known dates and checks the NestJS transcript:

```bash
RUN_ID=run1 npm run verify-display-status   # recompute + assert, exit 1 on failure
```

### Masking of the new fields

Because these keys are absent from the Next response, normalizing must drop
them (a masked value would still surface as `<missing>`). The drop rules are
surgical to avoid weakening existing checks:

- `daysUntilExpiry` and `expiryStatus` are dropped everywhere (nest-only keys).
- `durationDays` is dropped only within `memberships.*` steps — the plan object
  also carries a `durationDays` (checked across both backends), so it must not
  be dropped globally.
- `status` is dropped only within `members.*` steps — on membership objects it
  is the reversal status (`active`/`reversed`) and on payments it is
  `paid`/`voided`/`refunded`, both of which are present on both backends and
  stay checked.

