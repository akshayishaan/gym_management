# Migration Plan: Next.js + Mongoose → NestJS + Flutter (MongoDB unchanged)

> **Historical / superseded — 2026-10-04.** The proposal below is retained for its original rationale, not as the current implementation contract. The working tree now contains the standalone NestJS backend in `backend/` and a fresh Android/iOS Flutter starter in `mobile/`. Next.js and the prior Flutter implementation are retained in Git history, not as working-tree rollback sources. The new starter has no authentication, API client, gym screens, or backend integration; the Riverpod/Dio/generated-client stack and UI-parity work below are historical proposals, not present features. Docker/cloud deployment and CI plans are aspirational, not supplied infrastructure, and backend behavioral parity/production readiness have not been established. Actual Nest routes have **no `/api` prefix**; Gym settings use `/gyms/:id`, not `/settings`. For current setup and conventions, read the root `README.md` and `CLAUDE.md`, then the controllers under `backend/src/`. The original body follows unchanged.

## Architecture at a glance

```
┌─────────────────────────┐        ┌──────────────────────────────┐
│  Flutter app (mobile)    │  HTTPS │  NestJS API (TS)              │
│  Riverpod + dio + cache  │ ─────► │  @nestjs/jwt + passport       │
│  (mirrors TanStack)      │  JSON  │  Controllers/Services/Guards  │
└─────────────────────────┘        │  Mongoose (unchanged models)   │
                                   │  Redis (cache/rate-limit)      │
                                   └───────────────┬───────────────┘
                                                   ▼
                                        MongoDB (SAME Atlas cluster)
```

## Why this is the low-risk path

NestJS is the same language (TS), same ODM (Mongoose), same runtime as the current backend. The three hardest modules port almost verbatim: `lib/membershipLifecycle.ts` (transactions + `runIdempotent`), `lib/memberLedger.ts` (`recomputeMemberAggregates`), and `lib/gymInsights.ts` (`$facet`/`$setWindowFields` aggregations). No data migration, no aggregation rewrite, no ORM translation — so "no business logic change" is directly auditable line-by-line.

## Decisions locked

- **Database:** Keep MongoDB (same Atlas cluster). PostgreSQL was considered but rejected to honor the "same DB, no logic change" constraints.
- **Backend:** NestJS + Mongoose (TypeScript), not Django (see ADR-0003).
- **Auth:** `@nestjs/jwt` + passport. Access token (`{sub, role}` only) + rotating refresh token. `gymIds` are hydrated server-side per request, never stored in the token.
- **Flutter data layer:** Riverpod + dio, with a cached-query pattern mirroring TanStack Query.
- **Deployment:** Cloud VM (ARM, up to 4 OCPU / 24GB RAM), Docker Compose, MongoDB stays on Atlas.
- Additive schema changes are allowed; existing data and business logic stay untouched.
- Refresh token: a `refreshTokenHash` + `refreshTokenExpiresAt` field on the existing `Staff` doc (not a separate collection). Single active refresh token per staff — fine for a mobile, single-device admin app.
- BullMQ scope: cache invalidation only (see ADR-0004). ActivityLog stays synchronous in-transaction. Expiry reminders deferred to a future feature.
- Member `photo` stays a dormant URL field; gym `logo` stays a base64 data URI in Mongo (≤500 KB). No new image pipeline for the migration (add object storage as a separate feature later if member photos become real).
- Invoices: PDF generated client-side in Flutter via the `pdf` + `printing` packages, keeping the hardcoded gray/green / white-background styling. No server-side PDF.
- Fonts: Inter (body) + Manrope (display/rounded), both OFL-licensed, bundled. SF Pro Rounded / Avenir Next are not legally distributable and don't exist on Android.
- Repo layout: monorepo in this repo — `backend/` (NestJS), `mobile/` (Flutter), existing Next.js source kept as rollback + port reference.
- DTO validation: keep Zod (copy `lib/validators/*` verbatim, map ZodError→422).
- API contract: NestJS emits OpenAPI; Flutter client generated via openapi_generator from the spec (single source of truth for types).
- Date math: server-owned only (see ADR-0005). Flutter renders date strings, never computes gym-local dates.
- Token storage on device: `flutter_secure_storage` for refresh token, access token in memory only, auto-refresh on 401.

## Phase 1 — Backend: NestJS scaffold + config

Goals: reproduce today's server exactly, endpoint-for-endpoint.

1. Project scaffold (`/backend`, npm, TS, ESLint/Prettier).
2. Config modules mirroring `lib/mongodb.ts`, `lib/mongoConfig.ts`, `lib/mongoTransaction.ts`:
   - `MongooseModule` with connection caching (reuse the existing global-cache pattern).
   - `withMongoTransaction` → a NestJS `@Transactional` decorator / service wrapper calling Mongoose `session.withTransaction`.
   - Env: `MONGODB_URI` (or `MONGODB_USERNAME`/`PASSWORD` pair), `JWT_SECRET`, `JWT_REFRESH_SECRET`, `REDIS_URL`.
3. Schemas (`/backend/src/schemas/*`) — 1:1 copies of `models/*.ts` with the same field names, indexes, and cascades: `gym`, `staff`, `member`, `payment`, `membership`, `activity-log`, `lifecycle-mutation`, `counter`. Keep the `mongoose.models.X || model()` guard pattern equivalent (module-level singletons).

## Phase 2 — Backend: Auth (replaces NextAuth)

Goals: same session semantics; `gymIds` never in the token.

1. JWT module (`@nestjs/jwt` + `passport-jwt`):
   - `POST /auth/login` → validate email + bcrypt compare (cost 12, reuse bcryptjs). Issue access token (~15m) + refresh token stored hashed as `refreshTokenHash`/`refreshTokenExpiresAt` on the `Staff` doc (rotated on use), NOT a separate `RefreshToken` collection.
   - Access token payload = `{ sub: staffId, role }` only. No gymIds.
   - `POST /auth/refresh` → rotate refresh, issue new pair.
   - `POST /auth/signup` → public, mirror signupSchema (name/email/password≥6, 409 dup).
2. `JwtAuthGuard` + `RequireGym` guard replicating `requireAuth()` + `getGymFilter()` + `requireGymId()`:
   - Per request: decode token → hydrate `gymIds` from `Staff` by id → resolve `selectedGymId` from header (`X-Selected-Gym`) or first gym → validate membership → attach `{ user, gymId }` to request.
3. Exceptions replicating the `apiHandler` mapping: `DomainException(status)`, `AuthException`(401), `ForbiddenException`(403), `Validation`(422), Mongo dup-key(11000)→409, CastError→400, fallback 500. Error shape `{ error, details? }`. Keep Zod for DTO validation → 422.

## Phase 3 — Backend: Domains (the core port)

Goals: fidelity to `lib/` logic, zero drift. Port in dependency order.

| NestJS module | Ports from | Notes |
| --- | --- | --- |
| `Calendar/Utils` | `lib/membershipCalendar.ts`, `lib/utils.ts` | Pure functions; copy verbatim. `todayInTimeZone`, `addCalendarDays`, `calculateMembershipExpiry`, `generateInvoiceNumber` (Counter atomic incr), `formatCurrency`/`formatDate`. |
| `Lifecycle` | `lib/membershipLifecycle.ts`, `lib/memberLedger.ts`, `lib/clientRequestId.ts` | The critical module. Service methods `onboardMember`, `recordPayment`, `createPlanPurchase`, `voidPayment`, `refundPayment`, `reversePlanPurchase`, with `runIdempotent` + `LifecycleMutation`. `recomputeMemberAggregates` as sole writer of Member cached fields. |
| `Gyms` | `/api/gyms` | list/create/edit/delete (cascade hard-delete). |
| `Members` | `/api/members` (+ `/[id]`) | search/status/page/limit; create→`onboardMember`; update; soft-delete. |
| `Payments` | `/api/payments` (+ `/[id]/void`, `/refund`) | list with month/memberId filters + `summary.netAmount`; `paymentActionSchema`. |
| `Memberships` | `/api/memberships` (+ `/[id]/reverse`) | history; `reversePlanPurchase`. |
| `Plans` | `/api/plans` (+ `/[id]`) | `getPlanPortfolioInsights`; `normalizePlanFeatures`; `exactPlanNamePattern` (409). |
| `Dashboard` | `/api/dashboard` | aggregates + recentPayments/expiringList. |
| `Reports` | `/api/reports`, `lib/gymInsights.ts` | Copy the `$facet`/`$setWindowFields` pipelines verbatim as Mongoose aggregation code. |
| `Activity` | `/api/activity` | paginated list. |

- Keep the same REST path surface (`/api/gyms`, `/api/members`, …) so the Flutter client maps 1:1.
- ActivityLog written after every mutation, exactly as today.
- Soft-delete filter `{ isActive: { $ne: false } }` (not `$eq: true`) — preserve the legacy-doc edge case.

## Phase 4 — Backend: Performance (the "really fast" requirement)

1. Redis read-caching of heavy list endpoints (`/dashboard`, `/plans` stats, `/reports`) keyed by `gymId`, invalidated on lifecycle mutations via BullMQ (async, after txn commits). ActivityLog remains synchronous in-transaction (ADR-0004); ledger recompute stays inside the txn per ADR-0001.
2. Confirm indexes are identical to today (especially `{gymId,status,paidAt:-1}`, `{gymId,memberId}`, `{gymId,expiryDate:-1}`, `Counter` atomic upserts).
3. Connection pooling: tune `maxPoolSize` for Mongo; gzip/compression; keep JSON responses lean (same shapes, no over-fetching).

## Phase 5 — Flutter client (the "snappy" requirement)

Goals: pixel-consistent UI, same interactions, "app-canvas → app-screen" feel, semantic theming + dark mode + per-gym `primaryColor`.

1. Scaffold — Flutter 3.x, Dart, `flutter_riverpod` + `dio` + `freezed/json_serializable`. Single codebase, Material 3.
2. Design system port (most important for "looks the same"):
   - `ThemeData` builder reading the exact CSS vars: primary `hsl(15 91% 57%)`, success `hsl(153 58% 39%)`, warning, destructive, accent, muted, background `hsl(34 33% 96%)`, foreground `hsl(222 42% 11%)`, card white, dock dark navy; `--radius 1.125rem`.
    - Fonts: Inter (body) + Manrope (display), both OFL-licensed and bundled (SF Pro Rounded / Avenir Next are not legally distributable and don't exist on Android).
   - Custom widgets: `AppCanvas` (radial gradient bg), `AppScreen` (staggered rise animation), `AppSurface` (card+border+shadow), `AppSectionLabel` (uppercase 11px bold), `HideScrollBar`.
   - Semantic tokens only so gym `primaryColor` + dark mode work. `GymTheme` computed at runtime from Settings.
3. Navigation & screens (mirror route tree):
   - Bottom nav dock (4 tabs: Today/Members/Payments/More) ≡ `BottomTabBar`.
   - `TopAppBar` + `StackHeader` (back).
    - Screens: `Today`, `Members` + `MemberDetail` (Overview/History/Payments tabs), `Payments` + month bottom-sheet, `Plans`, `Reports` (year selector + metric cards + trend chart via `fl_chart`), `Activity`, `Gyms`, `Settings`, and `Invoice` (client-side PDF via `pdf` + `printing`, keeping the hardcoded gray/green / white-background styling — no server-side PDF).
    - All gym-local date/status values (today, expiry, duration, expiring/expired status) come from the server (ADR-0005). Flutter renders `YYYY-MM-DD` strings and server-computed display values, never derives them client-side.
   - Dialogs → `showModalBottomSheet`/`AlertDialog`; `MobileDatePicker` → gym-local date-only picker; `sonner` toasts → SnackBar/Flushbar.
4. Data layer (mirror TanStack Query):
    - `dio` interceptors: attach access token, auto-refresh on 401, `X-Selected-Gym` header, error normalization to `{error, details?}`. Refresh token stored in `flutter_secure_storage`; access token kept in memory only.
    - Dart client generated from the NestJS OpenAPI spec via openapi_generator (single source of truth for types).
    - Riverpod providers per query key (`['gym', gymId, ...]`), staleTime, app-resume refetch, `invalidateGymScope()` on gym switch or mutation. Copy `queryKeys.ts` structure verbatim.
   - `GymSettingsProvider` equivalent: `switchGym()` persists selected gym, invalidates scoped providers, dirty-form guard dialog.
5. Offline/snappiness: cached list + optimistic updates, pull-to-refresh, skeleton loaders, preload adjacent screens.

## Phase 6 — Deployment (Cloud VM)

1. One ARM64 instance (up to 4 OCPU / 24GB RAM, ARM64), Ubuntu 24.04.
2. Docker Compose stack:
   - `nginx` (or Caddy, auto-TLS via Let's Encrypt) as reverse proxy / TLS.
   - `backend` (NestJS, multi-stage Node 24 image, ARM-compatible) behind `pm2` or `node --cluster`.
   - `redis` (BullMQ + cache).
   - MongoDB stays on Atlas (unchanged).
3. Flutter builds: Android APK/AAB + iOS IPA via local build or CI (GitHub Actions). Distribute via Play Store / TestFlight; no web hosting needed.
4. Secrets via `.env` + Docker secrets: `MONGODB_URI`, `JWT_SECRET`, `REDIS_URL`.
5. CI/CD (GitHub Actions): build + test backend on PR; tag + push Docker image; build Flutter artifacts on tag.

## Phase 7 — Migration rollout (big-bang, staged internally)

1. Build backend + Flutter in parallel against the live MongoDB (read-only initially).
2. Parity harness: a script replaying real API calls against both Next.js and NestJS and diffing responses (confidence for "no logic change," especially `gymInsights` aggregations and `membershipLifecycle` edge cases: overlap, reverse-order, idempotency, void/refund).
3. Freeze date → deploy NestJS (Nginx points to new backend) → release Flutter app → retire Next.js + Vercel.
4. Keep Next.js in a tagged git state as rollback reference.

## Suggested milestone order

1. NestJS scaffold + config + schemas (parity of models).
2. Auth module (JWT + guards + exceptions).
3. Calendar/utils + Lifecycle module (highest-risk; do first after auth).
4. CRUD domains (Gyms/Members/Payments/Memberships/Plans).
5. Dashboard/Reports/Activity + Redis cache + BullMQ.
6. Parity harness → freeze → cutover → retire.
7. Flutter scaffold + design system + nav shell.
8. Flutter screens + data layer (parallel with backend milestones 3–5).

## Open items before coding

No open items — installer/analytics SDKs, push notifications (if ever desired), and member-photo storage are all future feature tickets outside migration scope.
