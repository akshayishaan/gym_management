# 02 — Mongoose schemas (1:1 parity with models/*)

**What to build:** All eight Mongoose models are defined in `/backend` with identical field names, types, defaults, and indexes to the existing `models/*.ts` — gym, staff, member, payment, membership, activity-log, lifecycle-mutation, counter. The `mongoose.models.X || model()` module-level singleton guard pattern is preserved.

**Blocked by:** 01

**Status:** ready-for-agent

- [ ] All 8 schemas exist with field-for-field parity (spot-check against models/)
- [ ] Indexes match exactly (incl `{gymId,status,paidAt:-1}`, `{gymId,memberId}`, `{gymId,expiryDate:-1}`, Counter atomic upsert)
- [ ] Staff keeps bcrypt pre-save hash (cost 12) + comparePassword; new refreshTokenHash/refreshTokenExpiresAt fields present
- [ ] Soft-delete semantics preserved (`isActive` default true; query filter `{ isActive: { $ne: false } }`)
- [ ] Build passes
