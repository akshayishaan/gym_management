# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Multi-tenant gym management SaaS built with **Next.js 15 (App Router) + React 19 + MongoDB/Mongoose + NextAuth v4**. One deployment serves many gyms; a staff account can belong to multiple gyms and switch between them. Requires **Node >= 24**.

## Commands

```bash
npm run dev      # next dev (localhost:3000)
npm run build    # next build (output: standalone)
npm run lint     # next lint (eslint-config-next)
npm run seed     # tsx scripts/seed.ts — creates the seed admin account + gym
npm run migrate:lifecycle -- --apply # migrate legacy dates/payment states
```

There is **no test runner configured**. Type-checking happens via `npm run build` (or `tsc --noEmit`).

**Schema changes need a dev-server restart.** Models use the `mongoose.models.X || mongoose.model(...)` guard, so an already-running `next dev` process keeps the *old* compiled schema after you edit a model file. New fields silently won't persist until the process is restarted.

**Docker:** `docker-compose up` brings up `app`, a single-node MongoDB replica set, its one-shot initializer, and the seed service. Transactions require the replica set. Env vars: `MONGODB_URI`, `NEXTAUTH_SECRET`, `NEXTAUTH_URL`, plus `SEED_*` for the seed script (see `.env.example`).

**One-off scripts** run via `tsx`, e.g. `npx tsx scripts/migrate-multi-tenant.ts` (needs `MONGODB_URI` in env).

Path alias: `@/*` maps to the repo root.

## Multi-Tenancy — the central concept

Every gym-scoped model (`Member`, `Payment`, `Plan`, `Membership`, `ActivityLog`) carries a `gymId`, and **every query must be gym-scoped**. Getting this wrong leaks data across tenants. The mechanism:

- **Roles** (`lib/session.ts`): `SessionUser.role` is currently a plain string that is effectively always `"admin"` ("kept for future extensibility"). The old `superadmin | receptionist | trainer` roles and the superadmin/staff UIs have been **removed** — a few vestigial `role === "superadmin"` client checks remain (`app/dashboard/page.tsx`, `lib/hooks/useGyms.ts`) but are dead paths. Don't build new role logic without confirming intent.
- **Active gym** is stored in the `selectedGymId` cookie. The cookie is **not httpOnly** — intentionally JS-readable. It is written client-side via `lib/gymCookie.ts` (`setGymCookie()`) and read server-side via `lib/selectedGym.ts` (`getSelectedGymId()`). `GymSettingsProvider` derives settings from the authorized `useGyms()` cache and falls back to the first authorized Gym when the cookie is absent or invalid. The middleware does **not** set the cookie.
- `apiHandler` injects the validated `selectedGymId` onto the `SessionUser` before your handler runs.
- **`getGymFilter(user)`** (`lib/withAuth.ts`) is the canonical way to build the Mongo filter — it returns `{ gymId }` for the user's active gym (validating it is in their `gymIds`). **Always spread it into queries**: `const query = { ...getGymFilter(user) }`.
- **`gymIds` are NOT stored in the JWT.** They are hydrated fresh from the DB on every request inside `requireAuth()`, so adding/removing a staff member from a gym takes effect immediately without a new login.

## API route pattern

All routes under `app/api/` follow one shape. Wrap handlers in **`apiHandler`** (or **`apiHandlerWithParams`** for dynamic `[id]` routes) from `lib/apiHandler.ts`:

```ts
export const GET = apiHandler(async (req, user) => { ... });
export const PUT = apiHandlerWithParams(async (req, user, { id }) => { ... });
```

The wrapper handles auth (`requireAuth` → 401), injects `selectedGymId`, and centralizes error translation: `AuthError`→401, `ForbiddenError`→403, `DomainError`→its domain status, `ZodError`→422, Mongoose duplicate-key→409, ValidationError→422, CastError→400. Throw the matching error type instead of duplicating error response logic.

`lib/withAuth.ts` exports only `requireAuth`, `getGymFilter`, and the two error classes. The old `requireRole` / `requireSuperAdmin` / `requireNotSuperAdmin` helpers have been removed.

**Request bodies are validated with Zod** schemas in `lib/validators/*` (`.parse(body)` — the thrown `ZodError` becomes a 422 automatically).

**List endpoints** share a convention: read `search`, `status`, `page`, `limit` off `searchParams`, build `query` by spreading `getGymFilter(user)`, run reads with `.lean()`, and return `{ <items>, total, page, limit }`. See `app/api/members/route.ts` as the reference.

**Mutations must write an `ActivityLog`** entry (gymId, staffId, staffName, action, entity, entityId, details) — the audit trail, done inline in each route after the DB write.

### API surface

| Route | Methods | Purpose |
|-------|---------|---------|
| `/api/gyms` | GET, POST | List user's gyms; create gym |
| `/api/gyms/[id]` | GET, PUT, DELETE | View/edit/delete gym (DELETE cascades) |
| `/api/members` | GET, POST | List members (search/status/page); create member (may seed a plan + initial payment) |
| `/api/members/[id]` | GET, PUT, DELETE | Member CRUD (DELETE is a **soft-delete** — sets `isActive:false`; detail GET still works) |
| `/api/payments` | GET, POST | List payments (month filter); **record payment — see business logic below** |
| `/api/payments/[id]` | GET, DELETE | Get Payment; DELETE returns 405 because Payments are audit records |
| `/api/payments/[id]/void` | POST | Void a paid Payment without changing Membership access |
| `/api/payments/[id]/refund` | POST | Record a full refund without changing Membership access |
| `/api/memberships` | GET | Membership history for a member (`?memberId=`), newest period first |
| `/api/memberships/[id]/reverse` | POST | Reverse the latest eligible Plan purchase and its associated Payment |
| `/api/plans` | GET, POST | List plans; create plan |
| `/api/plans/[id]` | GET, PUT | Plan CRUD — **no DELETE**; deactivate via `PUT { isActive: false }` instead |
| `/api/dashboard` | GET | Stats: total members, revenue, expiring list |
| `/api/reports` | GET | Yearly analytics: monthly revenue, members, plan distribution |
| `/api/settings` | GET, PUT | Fetch/update gym settings (`name`, `primaryColor`, `currency`, `address`, `phone`, `email`, `logo`, `expiryReminderDays`) — thin wrapper around the active gym doc |
| `/api/activity` | GET | Activity log for gym |
| `/api/auth/signup` | POST | **Public** (no `apiHandler`). Self-registers a new `Staff` with `role:"admin"` and empty `gymIds`. The new user must then create or be added to a gym before the dashboard is useful. |

## Payments, dues & membership renewal — core business logic

`lib/membershipLifecycle.ts` is the deep module and single write interface for onboarding, Plan purchase/renewal, dues payment, Payment void/refund, and Plan purchase reversal. Routes validate transport input and delegate to it. Every lifecycle mutation is transactional, idempotent via a client-generated `requestId`, tenant-scoped, server-owned, ledger-recomputed, and Activity-logged.

Payments are **single-purpose** — a payment is *either* a dues-clearing payment (no plan) *or* a membership purchase (plan), never both.

- **Plan selected → buy / renew a membership.**
  - Start = supplied `membershipStart`, else the calendar day after the latest non-reversed period when still active, else the Gym-local current day. Expiry is inclusive: `start + durationDays - 1`.
  - Creates an immutable **Membership** history record (`planPrice` snapshot, `planName`, `startDate`, `expiryDate`, `amount` paid, `paymentId`).
  - Amount cap = **`plan.price` only** (old dues are cleared in a separate no-plan payment). Partial payment is allowed.
  - After writing the Membership + Payment, calls **`recomputeMemberAggregates(gymId, memberId, session)`** (`lib/memberLedger.ts`) which re-derives `dueAmount`, `membershipExpiry`, and current Plan fields from surviving records.
- **No plan → clear outstanding dues only.** Validated: the member **must** have `dueAmount > 0` and `amount ≤ dueAmount`. No Membership record is created; recompute runs after.

Payments have `paid`, `voided`, or `refunded` states and are never hard-deleted. Void and refund remove the Payment's accounting effect but preserve Membership access. Plan purchase reversal reverses the latest eligible Membership and voids its still-paid associated Payment. Full refunds are negative cash movement on the refund timestamp in Gym Insights.

**`Member.dueAmount`** is a cached ledger balance recomputed as `max(0, Σ Membership.planPrice − Σ Payment.amount)`. **`Payment.paidAt`** is set server-side to `now()`. Member creation (`POST /api/members`) can also assign a plan and seed the first Payment + Membership, then recomputes.

## Models & data conventions (`models/`)

- Models use the `mongoose.models.X || mongoose.model("X", schema)` hot-reload guard. Compound indexes are `{ gymId: 1, ... }` to match scoped queries.
- **`connectDB()`** (`lib/mongodb.ts`) caches the connection on `global.mongoose`; `requireAuth` calls it for you.
- **`Staff`** is the auth/user model. Password is bcrypt-hashed in a `pre("save")` hook; use `staff.comparePassword()`. Auth lookups filter `isActive: true`. (There is no staff-management UI/API anymore.)
- **`Membership`** is the audit history of Plan purchase periods. Periods use inclusive Gym-local `YYYY-MM-DD` strings and may be marked `reversed`; they are not hard-deleted. `Member` holds only the cached current period.
- **`Member.isActive`** (boolean, default `true`) is a soft-delete flag. Filter active members with `{ isActive: { $ne: false } }` — **not** `{ isActive: true }` — so legacy documents without the field remain visible. The detail GET is unfiltered (soft-deleted members still have a detail page showing a Deleted badge + Restore button). All list/count/report/picker queries must include the `$ne: false` filter.
- **`lib/memberLedger.ts` → `recomputeMemberAggregates(gymId, memberId, session?)`** is the single writer of `Member.dueAmount` plus the current membership window. Only the lifecycle module should call it for Payment/Membership mutations.
- **`Counter`** provides atomic sequences (`generateInvoiceNumber()` in `lib/utils.ts` → `INV-YYMM-NNNN`). Use it instead of counting documents.
- **Denormalization is intentional.** `Payment.memberName`/`planName`, `Membership.planName`/`planPrice`/`amount`, and `ActivityLog.staffName` are **immutable snapshots** captured at write time (audit integrity); `Member.planName` is a **cache** updated only when the member's plan changes. Do not add hooks that retroactively rewrite snapshot fields. (Older `Membership` records predate the `planPrice` field — the UI falls back to `amount` when it's absent.)
- **Gym delete cascades everything** (Members, Payments, Plans, Memberships, LifecycleMutation receipts, and ActivityLog). It is the one true hard-delete in the system.

## Client-side data layer

- **TanStack React Query v5** owns Gym-scoped reads. Query keys in `lib/queryKeys.ts` always include `selectedGymId`; hooks live in `lib/hooks/`. Invalidate the active Gym root after lifecycle mutations.
- **`useGymSettings()` / `useCurrencySymbol()`** (`lib/useGymSettings.tsx`) provide the Active Gym and theme settings. `switchGym(gymId)` writes the cookie and changes the query scope. `useGymScopedFormGuard()` closes clean scoped forms and asks before discarding dirty ones during a switch.
- Provider tree (`components/Providers.tsx`): `QueryClientProvider → SessionProvider → ThemeProvider → GymSettingsProvider`.
- UI is **shadcn/ui** (Radix primitives in `components/ui/`) + Tailwind. Pages live in `app/dashboard/*`; reusable pieces in `components/layout` and `components/dashboard`. `GymGuard`/`NoGymState` handle the "no gym selected" case. **Theme:** use semantic tokens (`bg-primary/10 text-primary`, `text-success`, `text-warning`, `text-destructive`, `shadow-card`) — never hardcoded Tailwind colors like `text-green-600` — so gym theming and dark mode work.
- **Toasts** use `sonner` — call `toast.success()` / `toast.error()` directly.
- Charts use **Recharts**.

## Forms & dialogs pattern

Create/edit flows are **modal dialogs**, not separate pages. The old `/dashboard/members/new` and `/dashboard/payments/new` routes now just `redirect()` to their list pages; create from a dialog instead.

**Invoice page** (`app/dashboard/payments/[id]/invoice/page.tsx`) is a print-friendly, standalone page. It fetches payment + settings and calls `window.print()`. It intentionally uses hardcoded `gray-*` / `green-*` Tailwind colors (not semantic tokens) because the invoice always renders on a white background.

- Dialogs use **plain `useState` form state** (not React Hook Form), with client-side checks before submit and the shared Zod schema enforced server-side. Reference: `components/dashboard/PaymentFormDialog.tsx`, `MemberFormDialog.tsx`, `GymFormDialog.tsx`.
- **Scrollable dialog structure** (reuse this): `<DialogContent className="...max-h-[90vh] flex flex-col gap-0 p-0">`, a `shrink-0` header, a `flex-1 overflow-y-auto` body (inside a `flex-1 flex flex-col min-h-0` form), and a `shrink-0 border-t` footer with the submit button wired via `form="..."`.
- **`MobileDatePicker`** (`components/ui/mobile-date-picker.tsx`) is the themed date-only picker used by forms. Keep Membership dates as `YYYY-MM-DD`; never round-trip them through browser-local timestamps.
- **`PaymentBreakdown`** (`components/dashboard/PaymentBreakdown.tsx`) is the shared "owed vs paid → balance badge" card used by both the add-member and record-payment dialogs (plan path and dues-clearing path) — pass it an `items` array.

## Key utilities (`lib/utils.ts`, `lib/session.ts`)

- `formatCurrency(amount, currency)` — Intl.NumberFormat for INR/USD/EUR/GBP; always use this.
- `formatDate(date)` — en-IN locale, DD MMM YYYY.
- `getMemberStatus(expiryDate)` → `"active" | "expiring" | "expired"` ("expiring" = ≤7 days). `daysUntilExpiry(expiryDate)` — negative means expired.
- `buildWhatsAppLink(phone, message)` / `buildSmsLink(phone, message)` — contact helpers.
- `SessionUser` (`lib/session.ts`) carries `id, name, email, role, gymIds[], selectedGymId?`; `requireGymId(user)` resolves the active gym.

## Agent skills

### Issue tracker

Issues and PRDs are tracked in GitHub Issues for this repository. See `docs/agents/issue-tracker.md`.

### Triage labels

Use the five canonical triage labels without overrides. See `docs/agents/triage-labels.md`.

### Domain docs

This is a single-context repository with `CONTEXT.md` at the root and ADRs under `docs/adr/`. See `docs/agents/domain.md`.
