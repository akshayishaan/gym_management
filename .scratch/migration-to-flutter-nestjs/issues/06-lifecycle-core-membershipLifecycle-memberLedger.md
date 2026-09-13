# 06 — Lifecycle core (membershipLifecycle + memberLedger)

**What to build:** The single write interface, ported verbatim. Service methods onboardMember, recordPayment, createPlanPurchase, voidPayment, refundPayment, reversePlanPurchase, wrapped by runIdempotent (requestId + LifecycleMutation receipt) inside withMongoTransaction. recomputeMemberAggregates is the sole writer of Member cached fields (dueAmount, planId/planName/membershipStart/membershipExpiry). ActivityLog written synchronously in-transaction (ADR-0004). All date math server-owned (ADR-0005).

**Blocked by:** 02, 03, 04

**Status:** ready-for-agent

- [ ] All 5 operations ported with identical logic (plan.resolve, overlap check, start/expiry computation, amount bounds, invoice generation, dues validation)
- [ ] Idempotency: duplicate requestId returns cached result (no double-charge)
- [ ] recomputeMemberAggregates reproduces `dueAmount = max(0, Σ planPrice − Σ payment.amount)` + latest-membership cache
- [ ] reversePlanPurchase throws 409 "Reverse newer membership transactions first" when newer txns exist; void/refund preserve Membership access
- [ ] ActivityLog written synchronously inside the transaction
