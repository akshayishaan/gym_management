# 14 — Flutter data layer + auth flow

**What to build:** dio interceptors (attach access token, auto-refresh on 401, `X-Selected-Gym` header, error normalization to `{error, details?}`). Refresh token in flutter_secure_storage, access token memory-only. Riverpod providers per query key mirroring `queryKeys.ts` (`['gym', gymId, ...]`), staleTime, app-resume refetch, invalidateGymScope() on gym switch/mutation. GymSettingsProvider equivalent (switchGym persists selected gym, invalidates scoped providers, dirty-form guard). Dart client generated from the OpenAPI spec (openapi_generator).

**Blocked by:** 04, 11, 13

**Status:** ready-for-agent

- [ ] Login/signup flow works end-to-end with token storage + auto-refresh
- [ ] Generated Dart client types match backend OpenAPI
- [ ] Query-key providers + invalidateGymScope behave like TanStack Query
- [ ] Gym switch persists selection, invalidates scoped data, guards dirty forms
