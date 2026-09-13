# 10 — Dashboard + Reports + Activity

**What to build:** `/dashboard` aggregates (totalMembers, activeMembers, expiredMembers, expiringMembers, monthRevenue = revenue − refunds, recentPayments(5), expiringList(10)). `/reports` returns getAnnualGymInsights ported verbatim (the `$facet`/`$setWindowFields` pipelines, timezone-aware `$month`, planKey id-vs-legacy-name, revenue status `$in ['paid','refunded']`, refunds via refundedAt). `/activity` paginated ActivityLog list.

**Blocked by:** 06, 07, 08, 09

**Status:** ready-for-agent

- [ ] /dashboard returns correct aggregate shape (verify monthRevenue subtracts refunds)
- [ ] /reports matches getAnnualGymInsights output (series[12], planPerformance, paymentMethods, insights, comparisons)
- [ ] Timezone-aware month/year bucketing identical (gym timezone, not server tz)
- [ ] /activity paginated list works
