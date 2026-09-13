# 05 — Gyms module

**What to build:** Gym list/create/edit/delete endpoints with the existing semantics: list returns user's gyms (sorted createdAt desc), create pushes gymId onto Staff + writes ActivityLog, edit updates fields, delete is a ForbiddenError when not in user's gymIds and cascades hard-delete of all tenant collections. Active Gym selection/resolution works (settings, currency, timezone, primaryColor).

**Blocked by:** 04

**Status:** ready-for-agent

- [ ] GET/POST /api/gyms and GET/PUT/DELETE /api/gyms/[id] behave as today
- [ ] Create writes ActivityLog and links Staff.gymIds
- [ ] Delete cascade hard-deletes tenant data; Forbidden for non-members
- [ ] Multi-tenancy: every query scoped to Active Gym
