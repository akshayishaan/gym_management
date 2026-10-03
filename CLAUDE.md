# CLAUDE.md

## Current workspace

This repository contains a standalone NestJS API in `backend/` and a fresh Android/iOS Flutter starter in `mobile/`. The Next.js app and previous Flutter implementation are retained only in Git history. The starter has no gym features, authentication, API client, or backend integration; choose client architecture when that work is explicitly scoped rather than assuming Riverpod, Dio, or the old screens exist.

For setup and commands, use `README.md`. Backend environment loading depends on the process working directory: run its scripts from `backend/` so they load `backend/.env`. Node **24.x** is required. There is no configured backend test runner, lint script, Docker deployment, or CI workflow; report verification limits rather than treating type-checking as behavioral parity.

## Before changing behavior

1. Read `CONTEXT.md` and the relevant `docs/adr/` decision so domain terminology and invariants stay consistent.
2. Read the controller, service, and schema for the affected operation under `backend/src/`; treat source as the current transport contract. Historical migration documents are not evidence of implemented features.
3. Verify within the authorized scope. When preserving the backend byte-for-byte, run only the no-write type-check below from the repository root; installs, builds, formatting, server startup, and OpenAPI export can write inside `backend/`.

```bash
node backend/node_modules/typescript/bin/tsc \
  --project backend/tsconfig.json --noEmit --incremental false
```

For Flutter-only changes, run `flutter analyze` and `flutter test` from `mobile/`. Check actual tool output before claiming either component works.

## Authentication and tenant scope

`backend/src/auth/guards/jwt-auth.guard.ts` verifies `Authorization: Bearer <accessToken>` and reloads the active Staff document on each protected request. `gymIds` are hydrated from the database, not stored in JWTs, so membership changes take effect without a new login. `backend/src/auth/auth.service.ts` issues access/refresh tokens and creates new staff with `role: "admin"`; confirm intent before introducing additional role workflows.

`backend/src/auth/guards/require-gym.guard.ts` reads `X-Selected-Gym`, falls back to the user's first Gym when absent, validates membership, and attaches `req.gymId`. Use `@UseGuards(JwtAuthGuard, RequireGymGuard)` for gym-scoped controllers and include that validated `gymId` in every query, aggregation, and mutation; missing scope leaks tenant data. An entity ID alone is not authorization.

Gym CRUD uses `JwtAuthGuard` without `RequireGymGuard` so a staff account with no gyms can create its first Gym. Those services authorize the explicit Gym ID against `req.user.gymIds`.

## Backend transport conventions

Controllers delegate to services; services establish the Mongo connection through `MongoConnectionService` and parse request bodies using their local Zod schemas (`*.schemas.ts`). Use `backend/src/members/member.controller.ts` and `member.service.ts` as the scoped CRUD reference. List reads use `.lean()` and return items with `total`, `page`, and `limit`.

Routes have **no `/api` prefix** (`backend/src/main.ts`); the default port is **3001**. Authentication uses `/auth/signup`, `/auth/login`, and `/auth/refresh`. Resource controllers cover `/gyms`, `/members`, `/payments`, `/memberships`, `/plans`, `/dashboard`, `/reports`, and `/activity`. Gym settings use `GET`/`PUT /gyms/:id`, not `/settings`.

Use error classes from `backend/src/common/errors.ts` and the centralized `http-exception.filter.ts`. Existing Mongoose error mapping, response-status, and OpenAPI coverage gaps remain; verify the affected behavior instead of assuming the old Next.js status mapping or generated spec is exact. Do not treat static health output or a successful type-check as MongoDB/auth readiness.

## Membership lifecycle and accounting

`backend/src/lib/membershipLifecycle.ts` is the write interface for onboarding, Plan purchase/renewal, dues payment, Payment void/refund, and Plan purchase reversal. Delegate those operations to it instead of independently editing Payment, Membership, or cached Member state: `runIdempotent` uses the client-generated `requestId`, tenant-scoped `LifecycleMutation` receipts, and `withMongoTransaction` so the domain writes, ledger recomputation, and ActivityLog commit together. Use an external MongoDB deployment that supports transactions (ADR-0001).

### Single-purpose payments

- A **Plan purchase** creates a Membership period and captures its Plan price/name. Amount is capped by the Plan price alone; partial or zero payment is allowed, and zero creates no Payment. Earlier dues are settled separately.
- A **dues payment** has no Plan, requires a positive outstanding balance and `0 < amount <= dueAmount`, and creates no Membership period.
- Payments remain audit records with `paid`, `voided`, or `refunded` state. Void/refund remove accounting effect but preserve Membership access; a full refund contributes negative cash movement at the refund timestamp in `backend/src/lib/gymInsights.ts`.
- Plan purchase reversal marks the latest eligible Membership reversed and voids its associated still-paid Payment. Keep its eligibility checks and history instead of deleting records.

### Derived state and snapshots

`backend/src/lib/memberLedger.ts` → `recomputeMemberAggregates(gymId, memberId, session?)` is the single writer of `Member.dueAmount` and the current membership window. Lifecycle mutations invoke it after writes; keep manual patches out of transport services so cached state remains derived from surviving records.

The balance is `max(0, sum(non-reversed Membership prices) - sum(paid Payment amounts))`, with legacy Membership price fallback to `amount`. The current period is the surviving Membership with latest expiry.

`Payment.memberName`/`planName`, `Membership.planName`/`planPrice`/`amount`, and `ActivityLog.staffName` are immutable write-time snapshots for audit integrity. Update the Member's current Plan cache through ledger recomputation, not by retroactively rewriting snapshots. Invoice numbers use the atomic Counter through `backend/src/lib/utils.ts` → `generateInvoiceNumber`, not document counts.

## Dates, deletion, and audit

`backend/src/lib/membershipCalendar.ts` owns Gym-local calendar logic (ADRs 0002 and 0005). Membership dates are inclusive `YYYY-MM-DD` strings in the Gym's authoritative timezone: expiry is `start + durationDays - 1`; default start follows the latest surviving active period or uses the Gym-local current day. Keep overlap checks. Payment/refund times are server-owned timestamps.

When backend integration is implemented, Flutter must render date-only strings and server-derived values, not compute Gym-local today, expiry, duration, or status using the device clock. Existing backend display-status behavior requires verification before adopting it as a client contract.

Member deletion sets `isActive: false`; restoration uses `PUT /members/:id` with `isActive: true`. Active list/count/report/picker queries must use `{ isActive: { $ne: false } }` so legacy documents missing the field remain visible. Detail reads remain tenant-scoped but include deleted members to support restoration and history.

Plans are deactivated through update, not deleted. Payments and Memberships are audit history, not hard-delete targets. Gym deletion is the deliberate hard-delete cascade, including Members, Plans, Payments, Memberships, LifecycleMutation receipts, and ActivityLog; preserve that boundary.

Mutations record ActivityLog entries with Gym, actor, action, entity, and details. Lifecycle logs stay synchronous inside the transaction; BullMQ in `backend/src/cache/cache.service.ts` is for cache invalidation after mutation, not deferred audit writes (ADR-0004). Gym deletion intentionally removes its audit records with the tenant.

Schemas live under `backend/src/schemas/` and use the Mongoose compiled-model guard. Restart an already-running backend after schema changes so it does not retain an old compiled schema.

## Repository guidance

- Issues and PRDs: `docs/agents/issue-tracker.md`.
- Canonical triage labels: `docs/agents/triage-labels.md`.
- Domain documentation: `docs/agents/domain.md`, `CONTEXT.md`, and `docs/adr/`.

`docs/migration-plan.md` is historical and superseded; its source-retention, client-stack, UI-parity, and deployment proposals are not current guarantees. `DESIGN.md` is an unrelated historical Linear reference, not an active Flutter design contract.

Begin the next change by reading the affected backend controller/service or the Flutter starter under `mobile/lib/`, with the relevant ADR alongside it.
