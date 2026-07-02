# AGENTS.md

Next.js 15 + React 19 multi-tenant gym SaaS (MongoDB/Mongoose + NextAuth v4). Node >= 24.

## Commands

```
npm run dev      # localhost:3000
npm run build    # standalone output; type-check runs here
npm run lint     # next lint
npm run seed     # tsx scripts/seed.ts
```

There is **no test runner**. Verify with `npm run build` or `tsc --noEmit`. Single-file scripts run via `npx tsx ...`.

## Setup

Use `node -v` >= 24. Copy `.env.example` to `.env` with `MONGODB_URI`, `NEXTAUTH_SECRET`, `NEXTAUTH_URL`.

## Critical gotchas

- **Schema edits require dev-server restart.** Mongoose model guards (`mongoose.models.X || mongoose.model(...)`) cache schemas across HMR. New fields silently won't persist until you restart `next dev`.
- **Multi-tenancy is non-negotiable.** Every query must include the active gym filter. Use `getGymFilter(user)` from `lib/withAuth.ts` and spread it into queries. `gymIds` are hydrated from the DB on every request (not in JWT).
- **Auth wrapper.** API routes must use `apiHandler` or `apiHandlerWithParams` (not raw handlers). Throw `AuthError` / `ForbiddenError` from `lib/withAuth.ts` for auth issues. The wrapper translates them to 401/403 and validates Zod schemas to 422.
- **ActivityLog is mandatory.** Every mutation must write an `ActivityLog` entry after the DB write.
- **Soft-delete filter.** Filter active members with `{ isActive: { $ne: false } }`, not `{ isActive: true }` (legacy docs lack the field).
- **Member ledger is centralized.** Call `recomputeMemberAggregates(memberId)` (`lib/memberLedger.ts`) after any Payment/Membership create or delete. Do not compute inline.
- **`selectedGymId` is a non-httpOnly cookie.** Read server-side via `getSelectedGymId()`, write client-side via `setGymCookie()`. Effects must depend on it to refetch after gym switch.

## Conventions

- **Path alias:** `@/*` -> repo root.
- **API surface:** `app/api/` routes follow the `apiHandler` pattern. List endpoints accept `search`, `status`, `page`, `limit` from `searchParams` and return `{ items, total, page, limit }`.
- **UI:** shadcn/ui (Radix in `components/ui/`) + Tailwind. Use semantic theme tokens (`bg-primary`, `text-success`, etc.) — never hardcoded Tailwind colors like `text-green-600`.
- **Dialogs:** Create/edit flows are modal dialogs, not separate routes. Forms use plain `useState`; server-side uses Zod validators from `lib/validators/`.
- **DatePicker:** Requires `modal` prop inside dialogs to portal outside and keep pointer events.
- **Toasts:** `sonner` (`toast.success()`, `toast.error()`).

## Docker

`docker-compose up` starts `app`, `mongo:7`, and a one-shot seed service. Env vars: `MONGODB_URI`, `NEXTAUTH_SECRET`, `NEXTAUTH_URL`, plus `SEED_ADMIN_*` for seeding.

## Extras

- Payments are the single source of truth for membership state — read `POST /api/payments` before touching payment logic.
- There is no role-based UI for new features; `SessionUser.role` is effectively always `"admin"`.
- `Counter` model provides atomic invoice sequences (`generateInvoiceNumber()`).
