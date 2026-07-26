# AGENTS.md

Next.js 15 + React 19 multi-tenant gym SaaS (MongoDB/Mongoose + NextAuth v4). Node 24.x.

## Commands

```
npm run dev      # localhost:3000
npm run build    # production build; type-check runs here
npm run lint     # next lint
```

There is **no test runner**. Verify with `npm run build` or `tsc --noEmit`.

## Setup

Use Node 24.x. Copy `.env.example` to `.env` with `MONGODB_URI`, `NEXTAUTH_SECRET`, and `NEXTAUTH_URL`. Database credentials may be embedded in the URI or supplied as the `MONGODB_USERNAME` / `MONGODB_PASSWORD` pair.

## Critical gotchas

- **Schema edits require dev-server restart.** Mongoose model guards (`mongoose.models.X || mongoose.model(...)`) cache schemas across HMR. New fields silently won't persist until you restart `next dev`.
- **Multi-tenancy is non-negotiable.** Every query must include the active gym filter. Use `getGymFilter(user)` from `lib/withAuth.ts` and spread it into queries. `gymIds` are hydrated from the DB on every request (not in JWT).
- **Auth wrapper.** API routes must use `apiHandler` or `apiHandlerWithParams` (not raw handlers). Throw `AuthError` / `ForbiddenError` from `lib/withAuth.ts` for auth issues. The wrapper translates them to 401/403 and validates Zod schemas to 422.
- **ActivityLog is mandatory.** Every mutation must write an `ActivityLog` entry after the DB write.
- **Soft-delete filter.** Filter active members with `{ isActive: { $ne: false } }`, not `{ isActive: true }` (legacy docs lack the field).
- **Membership lifecycle is centralized.** All Payment/Membership writes go through `lib/membershipLifecycle.ts`; it calls `recomputeMemberAggregates(gymId, memberId, session)` inside the transaction. Do not write or compute inline.
- **`selectedGymId` is a non-httpOnly cookie.** Read server-side via `getSelectedGymId()`, write client-side via `setGymCookie()`. Effects must depend on it to refetch after gym switch.

## Conventions

- **Path alias:** `@/*` -> repo root.
- **API surface:** `app/api/` routes follow the `apiHandler` pattern. List endpoints accept `search`, `status`, `page`, `limit` from `searchParams` and return `{ items, total, page, limit }`.
- **UI:** shadcn/ui (Radix in `components/ui/`) + Tailwind. Use semantic theme tokens (`bg-primary`, `text-success`, etc.) — never hardcoded Tailwind colors like `text-green-600`.
- **Dialogs:** Create/edit flows are modal dialogs, not separate routes. Forms use plain `useState`; server-side uses Zod validators from `lib/validators/`.
- **DatePicker:** Use the themed `MobileDatePicker`; Membership values stay as `YYYY-MM-DD` date-only strings.
- **Toasts:** `sonner` (`toast.success()`, `toast.error()`).

## Deployment

The repository targets Vercel's Next.js runtime and does not use Docker. Configure `MONGODB_URI`, optional `MONGODB_USERNAME` / `MONGODB_PASSWORD`, `NEXTAUTH_SECRET`, and the production `NEXTAUTH_URL` in Vercel. MongoDB must be an external transaction-capable deployment. Create the initial admin through the public signup flow.

## Extras

- `lib/membershipLifecycle.ts` is the single write interface for Membership and Payment state.
- There is no role-based UI for new features; `SessionUser.role` is effectively always `"admin"`.
- `Counter` model provides atomic invoice sequences (`generateInvoiceNumber()`).
