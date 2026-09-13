# 04 — Auth: login/refresh/signup + JWT guards + exception mapping

**What to build:** Replaces NextAuth. `POST /auth/login` (email + bcrypt compare, issue ~15m access token `{sub,role}` + refresh token stored hashed as refreshTokenHash/refreshTokenExpiresAt on Staff, rotated on use), `POST /auth/refresh` (rotate, issue new pair), `POST /auth/signup` (public, name/email/password≥6, 409 dup). JwtAuthGuard + RequireGym guard hydrate gymIds from Staff per request and resolve selectedGymId (header `X-Selected-Gym` or first gym). Central exception mapping mirrors apiHandler: Domain(status), Auth(401), Forbidden(403), ZodError(422), dup-key 11000→409, CastError→400, fallback 500 with shape `{error, details?}`.

**Blocked by:** 01, 02

**Status:** ready-for-agent

- [ ] login/signup/refresh endpoints behave per spec (test signup 409, login wrong-password 401)
- [ ] Access token payload is `{sub, role}` only — no gymIds in token
- [ ] Refresh token rotated on use; hash-at-rest on Staff doc
- [ ] Guard hydrates gymIds per request and enforces Active Gym membership (Forbidden when not a gym member)
- [ ] Error shape/status mapping matches apiHandler exactly
