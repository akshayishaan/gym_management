# 12 — Parity harness

**What to build:** A script that replays real API calls against BOTH the running Next.js app and the new NestJS backend and diffs responses — focused on the highest-drift surfaces: gymInsights aggregations and membershipLifecycle edge cases (overlap, reverse-order, idempotency, void/refund).

**Blocked by:** 05, 06, 07, 08, 09, 10, 11

**Status:** ready-for-agent

- [ ] Harness replays a captured set of real requests against both backends
- [ ] Diff reports mismatches in output shape or values (esp. Insights + Lifecycle)
- [ ] Edge-case suite covers overlap, reverse-order, idempotent replay, void, refund, reversal
