# 01 — Monorepo + NestJS scaffold + Mongo config + txn wrapper

**What to build:** `/backend` becomes a runnable NestJS (TypeScript) project that boots, connects to MongoDB Atlas with connection caching, and exposes a `withMongoTransaction` wrapper replicating `lib/mongoTransaction.ts` (startSession + withTransaction). Env reads `MONGODB_URI` or `MONGODB_USERNAME`/`MONGODB_PASSWORD` pair, plus `JWT_SECRET`, `JWT_REFRESH_SECRET`, `REDIS_URL`.

**Blocked by:** None — can start immediately

**Status:** ready-for-agent

- [ ] `/backend` scaffold exists (npm + TS), `npm run build` succeeds
- [ ] Mongo connection module with global-cache pattern (single connection across HMR/dev restarts)
- [ ] `withMongoTransaction` wrapper works against Atlas
- [ ] env config module resolves URI from URI string OR username/password pair (both-or-neither rule preserved)
