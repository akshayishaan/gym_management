# 20 — Cutover + retire Next.js

**What to build:** Freeze date → point traffic to NestJS → release Flutter apps (Play Store/TestFlight) → retire Next.js + Vercel. Next.js kept in a tagged git state as rollback reference.

**Blocked by:** 12, 19

**Status:** ready-for-agent

- [ ] Parity harness shows no unacceptable divergence before freeze
- [ ] DNS/proxy cutover to NestJS completes with zero data loss
- [ ] Flutter apps released; Next.js/Vercel retired and tagged for rollback
