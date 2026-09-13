# 09 — Payments + Memberships module

**What to build:** Payment list (memberId/month/page/limit; month uses localDateTimeToInstant range on paidAt) with joined membershipId/membershipStatus + summary.netAmount (paid status aggregate). POST recordPayment (plan purchase vs dues). void/refund endpoints (paymentActionSchema {requestId, reason}). Membership history (GET ?memberId, newest first) and reverse (POST /[id]/reverse → reversePlanPurchase). Payments are audit records: GET single returns 404, DELETE returns 405.

**Blocked by:** 06, 07

**Status:** ready-for-agent

- [ ] Payment list with month/member filters + summary.netAmount
- [ ] recordPayment routes plan purchase vs dues correctly (dues: dueAmount>0, amount≤dueAmount, no Membership)
- [ ] void/refund via requestId, remove accounting effect but preserve Membership
- [ ] Membership history + reverse endpoints; payment GET→404, DELETE→405
