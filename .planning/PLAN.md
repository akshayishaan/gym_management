# PLAN: Flutter Android App from Figma "Gym Manager"

**Source design**: Figma `iDBLlEK2TLtlPpdLRFoj0U` → node `86:95` ("Lato Typography - Final Screens")
**Target**: `mobile/` (fresh Flutter starter, Android-only, real backend integration)
**Stack (locked)**: Flutter 3.13+ · Riverpod 2.x · Dio · freezed + json_serializable · GoRouter · Material 3 + Lato

---

## 0. What I know now (from discovery)

**Figma screen inventory** (21 frames, 13 distinct screens; some are state variants):

| # | Screen | Node IDs | Notes |
|---|---|---|---|
| 1 | Login — sign up ("01 login") | 86:3452 | single |
| 2 | Login — sign in ("02 login") | 86:3351, 86:3393 | 2 states (empty / error or success) |
| 3 | Gym Management Dashboard (loaded) | 86:3012, 86:3467 | 2 variants (with data) |
| 4 | Dashboard — empty state | 86:3269 | first-run / no gym selected |
| 5 | Members Directory | 86:1784, 86:1985 | 2 states (list / search-active) |
| 6 | Member Detail — Marcus Vance | 86:2302, 86:2413, 86:2575 | 3 states (view / payment / activity tab) |
| 7 | Plans | 86:982, 86:1159, 86:1386 | 3 states (list / create / edit) |
| 8 | Payments & Ledger | 86:1561 | single |
| 9 | Invoice & Receipt | 86:248 | detail of a payment |
| 10 | Reports | 86:2694 | single |
| 11 | Activity Log & Audit | 86:386 | single |
| 12 | My Gyms — Location Mgmt | 86:637, 86:786 | 2 states (list / edit) |
| 13 | More — Operations Menu | 86:96 | overflow menu / settings entry |

**Backend contracts (from `backend/src/schemas/*`):**
- `Staff` → `POST /auth/signup`, `POST /auth/login`, `POST /auth/refresh` (returns access + refresh tokens, staff profile, gymIds[])
- `Gym` → `GET /gyms`, `GET/PUT /gyms/:id`, no `/settings` endpoint
- `Member` → `GET /members` (list with `total/page/limit`), `GET/PUT /members/:id`, soft delete via `isActive:false`
- `Plan` → `GET/POST /plans`, `GET/PUT /plans/:id`, deactivate via `isActive:false` (no delete)
- `Payment` → `GET/POST /payments`, status enum `paid|voided|refunded`, kind `plan_purchase|dues`, method `cash|card|upi|bank_transfer|other`
- `Membership` → lifecycle via `backend/src/lib/membershipLifecycle.ts` (Plan purchase / Dues payment / Void / Refund / Reverse)
- All gym-scoped routes require `X-Selected-Gym` header (fallback to first gym in staff.gymIds)

**Mobile starter state (`mobile/lib/main.dart`):**
- Only the default counter app
- pubspec has no dependencies beyond `cupertino_icons`
- Android-only (no iOS scaffolding)
- No Lato font, no theme, no router, no state, no HTTP, no models

---

## 1. Build phases

The plan is sequenced so the app is runnable end-to-end as early as possible, then layered with depth. Each phase ends with a `flutter run`-able build on Android emulator against `http://10.0.2.2:3001`.

### Phase 0 — Foundation (single PR, ~half day)
- `pubspec.yaml`: add `flutter_riverpod ^2.5.1`, `dio ^5.4.0`, `go_router ^14.2.0`, `freezed_annotation ^2.4.1`, `json_annotation ^4.8.1`, `intl ^0.19.0`, `flutter_secure_storage ^9.2.0`; dev: `build_runner ^2.4.9`, `freezed ^2.5.0`, `json_serializable ^6.8.0`, `flutter_lints ^6.0.0` (already present)
- `flutter pub get` + `dart run build_runner build` once for codegen
- Add Lato font (`.ttf` files in `assets/fonts/`, declare in pubspec — uses Lato only per Figma name)
- `lib/main.dart` → minimal MaterialApp with Lato theme, light + dark variants
- `lib/app/router.dart` → GoRouter scaffold with a single placeholder `/` route
- `lib/theme/app_theme.dart` → Material 3 ThemeData with Lato, neutral palette matching Figma (deferred color extraction until Phase 1)
- Verify: `flutter analyze` + `flutter test` both pass; `flutter run` boots the placeholder

### Phase 1 — Design system & shell (depends on Phase 0)
- `lib/design/` directory: `colors.dart`, `spacing.dart`, `radius.dart`, `typography.dart`, `components/` (LatoButton, LatoCard, LatoTextField, LatoAppBar, LatoBottomSheet, LatoStatusChip, LatoEmptyState)
- Tokens derived from Figma screenshots once captured (Phase 1 reads them)
- `lib/app/scaffold.dart` → bottom-tab shell (Today / Members / Plans / More — 4 tabs to match the typical gym-app pattern, confirmed in Phase 1 when screenshots are reviewed)
- `lib/design/components/lato_scaffold.dart` — phone-width = 390 (matches Figma frames), centered on tablets

### Phase 2 — Networking & auth (~half day)
- `lib/core/api/dio_client.dart` → Dio with base URL from `--dart-define=API_BASE=http://10.0.2.2:3001`, auth interceptor reading JWT from `flutter_secure_storage`, `X-Selected-Gym` interceptor reading active gym from a Riverpod provider, automatic refresh on 401 via `/auth/refresh`
- `lib/core/api/api_exceptions.dart` → typed errors (NetworkError, AuthError, ServerError, ValidationError) mapped from the NestJS exception filter
- `lib/core/storage/secure_storage.dart` → typed wrapper around flutter_secure_storage (accessToken, refreshToken, selectedGymId, staffProfile JSON)
- `lib/features/auth/data/auth_repository.dart` → `signup()`, `login()`, `refresh()`, `me()`
- `lib/features/auth/domain/auth_state.dart` → freezed union: `Unauthenticated | Authenticated(staff, gymIds)`
- `lib/features/auth/presentation/login_screen.dart` — **Phase 1 deliverable, screen 1 & 2 of Figma** (sign-up form, sign-in form, error state, loading, navigation to dashboard on success)
- `lib/features/auth/application/auth_controller.dart` → Riverpod Notifier exposing `signIn`, `signUp`, `signOut`, auto-redirect via GoRouter `redirect`
- Verify: sign up via real backend, sign in returns tokens, refresh round-trips, sign out clears storage; dashboard route guard works

### Phase 3 — Gym picker & active-gym (depends on Phase 2)
- `lib/features/gyms/data/gym_repository.dart` → list, get, update, create
- `lib/features/gyms/presentation/gym_picker_sheet.dart` — bottom sheet when a staff account has 2+ gyms
- `lib/features/gyms/application/active_gym_controller.dart` → persists `selectedGymId` in secure storage, drives the `X-Selected-Gym` header
- Route: if no gym selected and none exists → push `GymCreateScreen`; if 1 gym exists → auto-select; if 2+ → show picker
- `lib/features/gyms/presentation/more_my_gyms_screen.dart` — **screen 12** (list & edit) wired to `GET/PUT /gyms/:id`
- Verify: real backend round-trip; switching gyms reloads all dependent providers

### Phase 4 — Dashboard (depends on Phase 3)
- `lib/features/dashboard/data/dashboard_repository.dart` → wraps `GET /dashboard`
- `lib/features/dashboard/presentation/dashboard_screen.dart` — **screens 3 & 4** (loaded + empty state). Empty state shows the `NoGymState`-style card (no gym created) and the `EmptyDataState` (zero members/plans)
- Freezed models for dashboard summary (kpiCards, recentPayments, expiringSoon, etc.) — exact shape will be derived from the screenshots
- Verify: dashboard renders against live backend; pull-to-refresh; loading + error states

### Phase 5 — Members (depends on Phase 3)
- `lib/features/members/data/member_repository.dart` → list (paginated), get, create, update, soft-delete
- `lib/features/members/presentation/members_list_screen.dart` — **screen 5** (list + search)
- `lib/features/members/presentation/member_detail_screen.dart` — **screen 6** (view, payment tab, activity tab) using nested scroll
- `lib/features/members/presentation/member_form_sheet.dart` — create/edit in bottom sheet, soft delete confirmation
- Verify: list paginates and searches against real backend; detail loads + tabs; create + edit + soft-delete round-trips

### Phase 6 — Plans (depends on Phase 3)
- `lib/features/plans/data/plan_repository.dart`
- `lib/features/plans/presentation/plans_screen.dart` — **screen 7** (list, create, edit)
- `lib/features/plans/presentation/plan_form_sheet.dart`
- Verify: CRUD + deactivate round-trips

### Phase 7 — Payments & invoice (depends on Phase 5, 6)
- `lib/features/payments/data/payment_repository.dart`
- `lib/features/payments/presentation/payments_screen.dart` — **screen 8** (list with status filter)
- `lib/features/payments/presentation/payment_invoice_screen.dart` — **screen 9** (rendered invoice with QR placeholder, void/refund actions)
- `lib/features/payments/presentation/payment_form_sheet.dart` — record payment (cash/card/upi/etc.)
- `lib/features/payments/application/record_payment_controller.dart` — calls into MembershipLifecycle for `plan_purchase` and `dues`
- Verify: invoice round-trips; void/refund calls lifecycle; status updates on detail

### Phase 8 — Activity log & reports (depends on Phase 3)
- `lib/features/activity/data/activity_repository.dart`
- `lib/features/activity/presentation/activity_log_screen.dart` — **screen 11**
- `lib/features/reports/data/reports_repository.dart`
- `lib/features/reports/presentation/reports_screen.dart` — **screen 10**
- Verify: both render against live backend; date filter works

### Phase 9 — More menu & polish (depends on all above)
- `lib/features/more/presentation/more_screen.dart` — **screen 13** (overflow menu: settings, gyms, activity, reports, sign out)
- `lib/features/settings/presentation/settings_screen.dart` — gym settings read/write
- Theme polish, dark mode pass, accessibility (semantics labels, contrast)
- Error boundaries, empty states, loading skeletons consistent across all screens
- App icon (deferred — needs assets from Figma)
- Verify: full app walkthrough against real backend, on Android emulator, dark + light, with the staff signed in to a multi-gym account

### Phase 10 — Test & ship
- `flutter analyze` (zero warnings)
- `flutter test` — unit tests for repositories (with mock Dio adapter), widget tests for one screen per feature, golden test for the design system
- Manual QA on physical Android device if available
- Tag a release commit; no Play Store push (out of scope)

---

## 2. Critical architecture decisions

- **API base URL**: configurable via `--dart-define=API_BASE=http://10.0.2.2:3001` (default for Android emulator). For real devices, set to the host LAN IP. Documented in `mobile/README.md`.
- **Token storage**: `flutter_secure_storage` (Android Keystore-backed). Never `shared_preferences`.
- **State persistence**: tokens + selectedGymId + cached staff profile in secure storage. Domain data is **not** cached locally in Phase 1 — every screen fetches fresh on entry. A persistent cache layer (Hive / ObjectBox) is a Phase 2 stretch goal if screens feel slow.
- **Snappiness levers** (you said "snappy"): Riverpod's `select`, `keepAlive: false` for one-shot fetches, `AutoDispose` providers, ListView.builder for any list, `const` widgets everywhere, image caching via `cached_network_image` (added in Phase 1 if the Figma has imagery), precompiled Material 3 themes.
- **Fidelity vs. Figma**: screen layouts are reproduced 1:1 from the Figma screenshots; spacing/radius/color tokens are extracted once and reused via `Lato` prefixed design tokens — never hard-coded.
- **What "snappy" does NOT mean**: skipping backend error handling, or caching everything aggressively. The data is read-heavy but not latency-critical (operator UI, not customer-facing), so we optimize for code simplicity + per-frame perf, not aggressive prefetch.
- **Backend dev workflow**: `cd backend && npm run start:dev` runs on 3001. You run it; I build against it. I'll show curl commands for the endpoints I need to consume as I go.

---

## 3. Open questions before starting

1. **Lato font files**: do you have the `.ttf` files, or should I source them (Google Fonts via the `google_fonts` package is the cleanest path — adds them on demand, no license hassle)?  **My pick: `google_fonts` package, no asset bundling.**
2. **App icon & splash**: the Figma may have these. Confirm in screenshots — I can mirror them or use defaults for now.
3. **Backend URL outside emulator**: when you test on a real device, what's the host machine's LAN IP? (Or stay on emulator only for now.)
4. **iOS**: README says Android-only. Confirm we skip iOS — even if Figma has iOS-frame variants, I'll deliver Android.

---

## 4. Out of scope (call out so I don't get pulled into it)

- iOS build / iOS-specific polish
- Push notifications, deep links, app shortcuts
- Offline-first (data is server-derived; no offline mutation queue)
- Play Store release
- i18n / l10n
- Analytics / crash reporting

---

## 5. Sequencing proposal (first two PRs after approval)

**PR 1 — Phase 0 + Phase 1 + Phase 2 (Foundation + Design System + Auth)**
- App boots, Lato font loads, theme + tokens in place, login screen matches Figma screens 1 & 2, real signup/login round-trips against backend, dashboard placeholder gated by auth.
- Verifier: `flutter analyze` clean, login → dashboard works, sign-out clears state, refresh on 401 works, dark mode looks correct.

**PR 2 — Phase 3 + Phase 4 (Gym picker + Dashboard)**
- Real gym switching, dashboard with live KPIs.
- Verifier: dashboard renders against a real seeded gym; empty-state variant renders for a brand-new account.

**PRs 3+** — one feature area each, in the order listed in §1.

---

## 6. What I will not do without checking first

- Introduce any new role workflows (CLAUDE.md says backend creates admins by default; don't add role pickers without your say-so).
- Add iOS-specific code (README + your message are clear).
- Pre-empt the Gym deletion cascade — that's backend territory, not client.
- Compute date math on the device for membership windows (CLAUDE.md says it's server-owned; client renders `YYYY-MM-DD` strings).
