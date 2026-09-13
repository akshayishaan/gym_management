# AGENTS.md

Next.js 15 (App Router) + React 19 multi-tenant gym SaaS (MongoDB/Mongoose + NextAuth v4). **Mobile-only** web app. Node 24.x.

## Commands

```
npm run dev      # localhost:3000
npm run build    # production build; type-check runs here
npm run lint     # next lint
```

There is **no test runner**. Verify with `npm run build` or `tsc --noEmit`.

## Setup

Use Node 24.x (`nvm use` reads `.nvmrc`). Copy `.env.example` to `.env` with `MONGODB_URI`, `NEXTAUTH_SECRET`, and `NEXTAUTH_URL`. MongoDB is always an external, transaction-capable deployment (e.g. Atlas) — nothing is provisioned locally. Credentials may be embedded in the URI or supplied as `MONGODB_USERNAME` / `MONGODB_PASSWORD`, which must be provided **together** (or both omitted).

## Critical gotchas

- **Mobile-only device gate.** `middleware.ts` redirects any non-mobile User-Agent (desktop and tablet) to `/unsupported-device` before auth. When developing in a desktop browser, use DevTools device emulation (or a phone UA) or every page redirects away.
- **Schema edits require dev-server restart.** Mongoose model guards (`mongoose.models.X || mongoose.model(...)`) cache schemas across HMR. New fields silently won't persist until you restart `next dev`.
- **Multi-tenancy is non-negotiable.** Every query must include the active gym filter. Use `getGymFilter(user)` from `lib/withAuth.ts` and spread it into queries (`const query = { ...getGymFilter(user) }`). `gymIds` are hydrated from the DB on every request (not in JWT).
- **Auth wrapper.** API routes must use `apiHandler` or `apiHandlerWithParams` (not raw handlers). Throw `AuthError` / `ForbiddenError` (`lib/withAuth.ts`) or `DomainError(message, status)` (`lib/domainError.ts`) for domain cases. The wrapper maps AuthError→401, ForbiddenError→403, DomainError→its status, ZodError→422, duplicate-key→409, CastError→400.
- **ActivityLog is mandatory.** Every mutation must write an `ActivityLog` entry after the DB write.
- **Soft-delete filter.** Filter active members with `{ isActive: { $ne: false } }`, not `{ isActive: true }` (legacy docs lack the field). The member detail GET is unfiltered (soft-deleted members are still viewable/restorable).
- **Membership lifecycle is centralized.** All Payment/Membership writes go through `lib/membershipLifecycle.ts`; it calls `recomputeMemberAggregates(gymId, memberId, session)` inside the transaction. Do not write or compute inline. Mutations are **idempotent** via a client-generated `requestId` (`createRequestId()` in `lib/clientRequestId.ts`). Payments are audit records (`paid`/`voided`/`refunded`); void/refund remove accounting effect but preserve Membership access. They are never hard-deleted by lifecycle operations — only a full gym deletion (`DELETE /api/gyms/[id]`) removes them.
- **`selectedGymId` is a non-httpOnly cookie.** Read server-side via `getSelectedGymId()`, write client-side via `setGymCookie()`. Effects must depend on it to refetch after gym switch.
- **Gym-local dates.** Membership start/expiry are `YYYY-MM-DD` date-only strings in the gym's timezone (`Gym.timezone`, default `Asia/Kolkata`) — never round-trip through browser-local timestamps.

## Conventions

- **Path alias:** `@/*` → repo root.
- **API surface:** `app/api/` routes follow the `apiHandler` pattern. List endpoints accept `page`/`limit` (plus resource-specific filters like `search`, `status`, `memberId`, `month`) from `searchParams` and return a resource-named array with `total`, `page`, `limit` (e.g. `{ members, total, page, limit }`, `{ payments, ... }`, `{ plans, ... }`).
- **UI:** shadcn/ui (Radix in `components/ui/`) + Tailwind. Use semantic theme tokens (`bg-primary`, `text-success`, `text-warning`, `text-destructive`, etc.) — never hardcoded Tailwind colors like `text-green-600`. (The print invoice page is the one intentional exception.)
- **Dialogs:** Create/edit flows are modal dialogs, not separate routes. Forms use plain `useState`; server-side uses Zod validators from `lib/validators/`.
- **DatePicker:** Use the themed `MobileDatePicker`; Membership values stay as `YYYY-MM-DD` date-only strings.
- **Toasts:** `sonner` (`toast.success()`, `toast.error()`).
- **Client data:** TanStack React Query v5 for gym-scoped reads; query keys include `selectedGymId` (`lib/queryKeys.ts`, hooks in `lib/hooks/`).

## Deployment

Targets Vercel's Next.js runtime; no Docker. Configure `MONGODB_URI`, optional `MONGODB_USERNAME` / `MONGODB_PASSWORD`, and `NEXTAUTH_SECRET`. NextAuth detects Vercel's `VERCEL_URL`; set `NEXTAUTH_URL` only for a stable/custom domain. Create the initial admin via `/login` → Sign Up (public `/api/auth/signup`, self-registers `role: "admin"` with empty `gymIds`).

## See also

- `CONTEXT.md` — ubiquitous-language glossary for the membership/payment domain.
- `docs/adr/` — architectural decisions (transactional lifecycle, gym-local dates).
- `CLAUDE.md` — longer-form guide (same facts, more prose).
