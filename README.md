# Gym Management

Mobile workspace for a multi-tenant gym management service:

- `backend/`: standalone NestJS + TypeScript + MongoDB/Mongoose API.
- `mobile/`: fresh Flutter starter app for **Android only**, named `gym_manager`.

The Next.js application has been retired from the working tree. Its source and the previous Flutter implementation remain available in Git history. The new Flutter app is only a scaffold: it has no gym screens, authentication, API client, or backend integration. UI parity and production deployment readiness have not been established.

## Prerequisites

Use Node.js **24.x** for the backend and an installed Flutter SDK for the mobile app. Android builds require the Android toolchain (Android SDK + a JDK).

## Backend development

Run these commands from the repository root, entering `backend/` before installing or starting the server:

```bash
cd backend
npm ci
# Create your local environment file only if it does not already exist.
test -f .env || cp .env.example .env
```

Edit `backend/.env` before starting:

| Variable | Purpose |
| --- | --- |
| `MONGODB_URI` | External, transaction-capable MongoDB deployment; the app does not provision a local database. |
| `MONGODB_USERNAME`, `MONGODB_PASSWORD` | Supply both together if credentials are not embedded in the URI. |
| `JWT_SECRET`, `JWT_REFRESH_SECRET` | Configure secrets for access and refresh tokens. |
| `REDIS_URL` | Optional Redis connection for read caching and BullMQ cache invalidation. |
| `PORT` | Defaults to `3001`. |

From `backend/`, start the development server:

```bash
npm run start:dev
```

Nest loads `.env` from the process working directory, so use `backend/.env`, not the private environment files at the repository root.

The default API base URL is `http://localhost:3001`, **without an `/api` prefix**. Authentication endpoints are `/auth/signup`, `/auth/login`, and `/auth/refresh`. Protected requests use `Authorization: Bearer <accessToken>`; gym-scoped requests select the Active Gym with `X-Selected-Gym: <gymId>`. Gym settings are read and updated through `/gyms/:id`; there is no `/settings` endpoint. Consult controllers under `backend/src/` for the current route surface.

## Flutter development

In a separate terminal, run from the repository root:

```bash
cd mobile
flutter pub get
flutter run
```

Select an Android emulator or device. The starter currently runs independently of the backend. The generated `com.example` organization is a development placeholder, not a release identifier. iOS scaffolding is not generated.

## Verification

With backend dependencies already installed, this command runs from the repository root without emitting build output or incremental metadata:

```bash
node backend/node_modules/typescript/bin/tsc \
  --project backend/tsconfig.json --noEmit --incremental false
```

Run Flutter checks from `mobile/`:

```bash
flutter analyze
flutter test
flutter doctor -v
```

There is no configured backend test runner or lint script, and no Docker deployment or CI workflow is supplied. Type-checking and Flutter starter tests do not establish backend behavioral parity or a completed mobile product.

## Domain and historical references

`CONTEXT.md` defines domain terminology; `docs/adr/` records decisions about transactions, tenant integrity, and server-owned Gym-local dates. `docs/migration-plan.md` preserves the superseded migration proposal, not current implementation guarantees. `DESIGN.md` is an unrelated historical Linear design reference, not the Flutter application's design specification.

Start local development with the backend setup above or `cd mobile && flutter run` for the independent starter.
