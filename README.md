# RepiX — Gym Management

Multi-tenant gym management platform: a NestJS + MongoDB backend and a Flutter
Android app (RepiX) for staff to manage members, plans, payments, and
memberships.

| Directory | What it is |
| --- | --- |
| `backend/` | NestJS + TypeScript + MongoDB/Mongoose API (Node 24.x) |
| `mobile/` | Flutter Android app (`gym_manager`, applicationId `com.repix.gym`) |

## Features

- **Members** — profiles, soft delete, per-member ledger balance
- **Plans** — configurable duration (days) and price per gym
- **Plan purchase** — creates a Membership period; supports full, partial, or
  zero payment at purchase time
- **Dues payment** — payments applied to an outstanding balance only
- **Void / refund** — audit-preserving cancellation of payments and plan
  purchases (reversal restores the member's previous membership state)
- **Gym insights** — dashboard, reports, and activity log
- **Multi-tenancy** — staff switch between gyms; all data is gym-scoped

## Backend

### Local development

```bash
cd backend
npm ci
test -f .env || cp .env.example .env
npm run start:dev
```

`npm run start:dev` starts the local Docker infrastructure (MongoDB
single-node replica set + Redis) and then the API with hot reload — see
`backend/DEVELOPMENT.md`. The API listens on `http://localhost:3001` (no
`/api` prefix).

Environment variables (see `backend/.env.example`):

| Variable | Purpose |
| --- | --- |
| `MONGODB_URI` | Transaction-capable MongoDB connection string (replica set required for transactions) |
| `JWT_SECRET`, `JWT_REFRESH_SECRET` | Access- and refresh-token signing secrets |
| `REDIS_URL` | Optional Redis for read caching and BullMQ cache invalidation |
| `PORT` | Defaults to `3001` |

### API conventions

- Auth: `/auth/signup`, `/auth/login`, `/auth/refresh`; protected requests use
  `Authorization: Bearer <accessToken>`
- Gym scoping: `X-Selected-Gym: <gymId>` header selects the Active Gym
- Gym settings are read and updated through `/gyms/:id` (there is no
  `/settings` endpoint)
- Consult the controllers under `backend/src/` for the current route surface

### Type-checking

```bash
node backend/node_modules/typescript/bin/tsc \
  --project backend/tsconfig.json --noEmit --incremental false
```

## Mobile app (RepiX)

```bash
cd mobile
flutter pub get
flutter run
```

The backend URL is injected at build time:

```bash
flutter run --dart-define=API_BASE=http://localhost:3001
```

On the Android emulator `10.0.2.2` maps to the host machine; on a real device
with `adb reverse tcp:3001 tcp:3001`, `localhost` works directly.

## Deployment

Deployment is **release-driven**:

1. A PR is merged to `main` → a **draft GitHub release** is created
   automatically with an auto-bumped version tag (from
   `mobile/pubspec.yaml`).
2. Publishing the release triggers the CI pipeline, which builds the Android
   APK (attached to the release as `repix_<tag>.apk`), builds the backend
   Docker image for `linux/arm64`, pushes it to GHCR, and deploys it to the
   production VM with a health check.

See `docs/releases.md` for the full flow, versioning, APK signing, and
rollback. Infrastructure setup is documented in `docs/deployment.md`.

## Architecture decisions

`docs/adr/` records the decisions behind the transactional membership
lifecycle, gym-local date handling, the NestJS/Mongoose backend, the
cache-invalidation strategy, and server-owned date math.
