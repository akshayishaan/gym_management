# 08 — Plans module

**What to build:** Plan list (status active/inactive, search, includeStats toggle → getPlanPortfolioInsights per-plan stats), create (dup-name 409 via exactPlanNamePattern; normalizePlanFeatures), update (partial, isActive toggle for deactivate; no DELETE).

**Blocked by:** 05

**Status:** ready-for-agent

- [ ] GET list returns {plans,total,page,limit[,summary]} with stats when includeStats
- [ ] POST create normalizes features (trim/dedupe case-insensitive) and 409s on duplicate name
- [ ] PUT partial update + isActive toggle (deactivate-by-update)
