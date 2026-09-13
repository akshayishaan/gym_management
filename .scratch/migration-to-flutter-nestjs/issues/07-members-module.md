# 07 — Members module

**What to build:** Member list/search/status/page/limit (search across name/phone/email, status filter active/expired/expiring/expiring30/due, soft-delete filter `isActive $ne:false`), create→onboardMember (returns 201 {member,payment,membershipId}), update (PUT, writes ActivityLog), soft-delete (DELETE sets isActive:false), and detail GET that is unfiltered (soft-deleted still viewable/restorable).

**Blocked by:** 05, 06

**Status:** ready-for-agent

- [ ] GET list with search + status filters + pagination returns {members,total,page,limit}
- [ ] POST creates member via onboardMember (with optional plan purchase + payment)
- [ ] PUT updates + logs ActivityLog; DELETE soft-deletes (restorable)
- [ ] Detail GET shows soft-deleted members (isActive:false)
