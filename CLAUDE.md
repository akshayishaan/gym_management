# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Multi-tenant gym management SaaS built with **Next.js 15 (App Router) + React 19 + MongoDB/Mongoose + NextAuth v4**. One deployment serves many gyms; staff accounts can belong to multiple gyms and switch between them. Requires **Node >= 24**.

## Commands

```bash
npm run dev      # next dev (localhost:3000)
npm run build    # next build (output: standalone)
npm run lint     # next lint (eslint-config-next)
npm run seed     # tsx scripts/seed.ts — creates superadmin + admin accounts
```

There is **no test runner configured**. Type-checking happens via `npm run build` (or `tsc --noEmit`).

**Docker:** `docker-compose up` brings up `app`, `mongo:7`, and a one-shot `seed` service. Env vars: `MONGODB_URI`, `NEXTAUTH_SECRET`, `NEXTAUTH_URL`, plus `SEED_*` for the seed script (see `.env.example`).

**One-off scripts** run via `tsx`, e.g. `npx tsx scripts/migrate-multi-tenant.ts` (needs `MONGODB_URI` in env).

Path alias: `@/*` maps to the repo root.

## Multi-Tenancy — the central concept

Every data model (`Member`, `Payment`, `Plan`, `ActivityLog`) carries a `gymId` and **every query must be gym-scoped**. Getting this wrong leaks data across tenants. The mechanism:

- **Roles** (`lib/session.ts`): `superadmin | admin | receptionist | trainer`. A `superadmin` has no fixed gym and is **read-only on gym data**; the other roles are scoped to the gyms in their `Staff.gymIds[]` array.
- **Active gym** is stored in the `selectedGymId` cookie. The cookie is **not httpOnly** — intentionally JS-readable. It is written client-side via `lib/gymCookie.ts` (`setGymCookie()`) and read server-side via `lib/selectedGym.ts` (`getSelectedGymId()`). On first visit, `GymSettingsProvider` initializes the cookie from `/api/settings` if none exists; `getSelectedGymId()` falls back to `user.gymIds[0]` when the cookie is absent or invalid. The middleware does **not** set the cookie.
- `apiHandler` injects the validated `selectedGymId` onto the `SessionUser` before your handler runs.
- **`getGymFilter(user, gymIdParam?)`** in `lib/withAuth.ts` is the canonical way to build the Mongo filter. It returns `{ gymId }` for scoped users (validating the gym is in their `gymIds`) and `{}` (or `{ gymId: param }`) for superadmins. **Always spread it into list queries**: `const query = { ...getGymFilter(user, gymIdParam) }`.
- **`gymIds` are NOT stored in the JWT.** They are hydrated fresh from the DB on every request inside `requireAuth()`. This ensures that adding/removing a staff member from a gym takes effect immediately without requiring a new login.

## API route pattern

All routes under `app/api/` follow one shape. Wrap handlers in **`apiHandler`** (or **`apiHandlerWithParams`** for dynamic `[id]` routes) from `lib/apiHandler.ts`:

```ts
export const GET = apiHandler(async (req, user) => { ... });
export const PUT = apiHandlerWithParams(async (req, user, { id }) => { ... });
```

The wrapper handles auth (`requireAuth` → 401), injects `selectedGymId`, and centralizes error translation: `AuthError`→401, `ForbiddenError`→403, `ZodError`→422, Mongoose duplicate-key→409, ValidationError→422, CastError→400. **Throw these errors rather than building error responses by hand.**

Authorization helpers (also `lib/withAuth.ts`), called inside handlers:
- `requireRole(user, ...roles)` / `requireSuperAdmin` / `requireNotSuperAdmin` — enforce who can act. Mutations on gym data typically call `requireNotSuperAdmin(user)` since superadmins are read-only.
- `requireSuperAdminOrRole(user, ...roles)` — the correct "superadmin OR role X" check (replaces a known buggy `isSuperAdmin || role !== "admin"` pattern; don't reintroduce it).

**Request bodies are validated with Zod** schemas in `lib/validators/*` (`.parse(body)` — the thrown `ZodError` becomes a 422 automatically). `lib/validators/index.ts` re-exports all types.

**List endpoints** share a convention: read `search`, `status`, `page`, `limit` (and `gymId` for superadmins) off `searchParams`, build `query` by spreading `getGymFilter(user, gymIdParam)`, run reads with `.lean()`, and return `{ <items>, total, page, limit }`. See `app/api/members/route.ts` as the reference.

**Mutations must write an `ActivityLog`** entry (gymId, staffId, staffName, action, entity, entityId, details) — this is the audit trail and is done inline in each route after the DB write.

### API surface

| Route | Methods | Purpose |
|-------|---------|---------|
| `/api/gyms` | GET, POST | List user's gyms; create gym (admin or superadmin) |
| `/api/gyms/[id]` | GET, PUT, DELETE | View/edit/delete gym (DELETE cascades) |
| `/api/members` | GET, POST | List members (search/status/page); create member |
| `/api/members/[id]` | GET, PUT, DELETE | Member CRUD |
| `/api/payments` | GET, POST | List payments (month filter); record payment (generates invoice) |
| `/api/payments/[id]` | GET, DELETE | Get/delete payment |
| `/api/plans` | GET, POST | List plans; create plan |
| `/api/plans/[id]` | GET, PUT, DELETE | Plan CRUD |
| `/api/staff` | GET, POST | List staff; create staff |
| `/api/staff/[id]` | GET, PUT, DELETE | Staff CRUD |
| `/api/dashboard` | GET | Stats: total members, revenue, expiring list |
| `/api/reports` | GET | Yearly analytics: monthly revenue, members, plan distribution |
| `/api/settings` | GET, PUT | Fetch/update gym settings (name, color, currency) |
| `/api/activity` | GET | Activity log for gym |

## Models & data conventions (`models/`)

- Models use the `mongoose.models.X || mongoose.model("X", schema)` guard to survive hot-reload. Compound indexes are defined `{ gymId: 1, ... }` to match scoped queries.
- **`connectDB()`** (`lib/mongodb.ts`) caches the connection on `global.mongoose`; `requireAuth` calls it for you.
- **`Staff`** is the auth/user model. Password is bcrypt-hashed in a `pre("save")` hook; use `staff.comparePassword()`. Auth lookups filter `isActive: true`.
- **`Counter`** provides atomic sequences (e.g. `generateInvoiceNumber()` in `lib/utils.ts` for unique `Payment.invoiceNumber` in format `INV-YYMM-NNNN`). Use it instead of counting documents.
- **Denormalization is intentional** — see `docs/denormalization-strategy.md`. `Payment.memberName`/`planName` and `ActivityLog.staffName` are **immutable snapshots** captured at write time (audit integrity); `Member.planName` is a **cache** updated only when the member's plan changes. Do not add hooks that retroactively rewrite the snapshot fields.

## Client-side data layer

- **TanStack React Query v5** is the data-fetching library. `lib/hooks/useGyms.ts` is the reference pattern: fetch with `useQuery`, invalidate cache with `useInvalidateGyms()` after mutations.
- **`useGymSettings()` / `useCurrencySymbol()`** (`lib/useGymSettings.tsx`) — current gym's name, color, and currency. **Use `useCurrencySymbol()` instead of hardcoding `₹`** in UI. Also exposes `switchGym(gymId)` which writes the cookie and re-fetches gym settings; call `router.refresh()` in the component afterward if server components need to re-render with the new gym's data.
- Provider tree (`components/Providers.tsx`): `SessionProvider → QueryClientProvider → ThemeProvider → GymSettingsProvider`.
- UI is **shadcn/ui** (Radix primitives in `components/ui/`, config in `components.json`) + Tailwind. Pages live in `app/dashboard/*`; reusable layout/dashboard pieces in `components/layout` and `components/dashboard`. `GymGuard`/`NoGymState` handle the "user has no gym selected" case.
- **Toasts** use `sonner` — call `toast.success()` / `toast.error()` directly (the `<Toaster>` is mounted in `Providers.tsx` via `components/ui/sonner.tsx`).
- Charts (reports/dashboard) use **Recharts**. Animations use **framer-motion**.
- **Superadmin pages** live at `app/dashboard/superadmin/` (aggregate overview + all-gyms management). These are separate from the gym-scoped `app/dashboard/` pages and are accessible only to the `superadmin` role.

## Forms pattern

Client-side forms use **React Hook Form** with the Zod resolver:

```ts
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { MemberSchema, type MemberInput } from "@/lib/validators";

const form = useForm<MemberInput>({ resolver: zodResolver(MemberSchema) });
```

See `components/dashboard/MemberFormDialog.tsx` as the reference implementation. The same Zod schemas used by the API validators (`lib/validators/*`) should be reused on the client where possible, which keeps server and client validation in sync.

## Key utilities (`lib/utils.ts`, `lib/session.ts`)

- `formatCurrency(amount, currency)` — Intl.NumberFormat for INR/USD/EUR/GBP; always use this, never hardcode symbols.
- `formatDate(date)` — en-IN locale, DD MMM YYYY.
- `getMemberStatus(expiryDate)` → `"active" | "expiring" | "expired"`. "expiring" = ≤7 days remaining.
- `daysUntilExpiry(expiryDate)` — negative means already expired.
- `buildWhatsAppLink(phone, message)` / `buildSmsLink(phone, message)` — contact action helpers.
- `SessionUser` interface (`lib/session.ts`) carries `id, name, email, role, gymIds[], selectedGymId?`. `isSuperAdmin(user)` and `requireGymId(user)` are defined here.

## Planning docs

Design rationale and in-progress work live in `plans/` (`architecture-review.md`, `multi-tenant-migration.md`, `ui-redesign.md`) and `docs/`. Consult them before large refactors.
