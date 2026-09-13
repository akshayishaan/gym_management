# 11 — Perf: Redis cache + BullMQ invalidation + OpenAPI emission

**What to build:** Redis read-caching on heavy list endpoints (/dashboard, /plans stats, /reports) keyed by gymId; invalidated via BullMQ after lifecycle mutations commit (async, cache-invalidation only per ADR-0004). NestJS emits an OpenAPI spec from controllers + Zod schemas for client generation.

**Blocked by:** 05, 06, 07, 08, 09, 10

**Status:** ready-for-agent

- [ ] Heavy read endpoints served from cache keyed by gymId
- [ ] Cache invalidated (BullMQ) on lifecycle mutations; ActivityLog NOT queued (stays sync in-txn)
- [ ] OpenAPI spec emitted and versioned (source of truth for Flutter client)
