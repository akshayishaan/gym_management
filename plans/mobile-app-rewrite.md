# Mobile-Only App Rewrite — Plan

## 0. What this is

A ground-up rewrite of every page/component under `app/` and `components/`
so the product is a **mobile-only web app** — not a responsive version of
the current desktop app. Backend is untouched: `app/api/*`, `models/*`,
`lib/apiHandler.ts`, `lib/withAuth.ts`, `lib/memberLedger.ts`,
`lib/validators/*`, the Payments/Membership business logic in
`CLAUDE.md` — all stay exactly as-is. Every feature that exists today
remains available; only the UI layer is replaced.

Desktop browsers get a plain "please use a mobile device" page instead of
the app — enforced server-side, not just visually hidden.

## 1. Desktop gating

- **`middleware.ts`** — widen the current matcher (today: `/dashboard/:path*`,
  `/login`) to run on effectively all page routes: everything except
  `/api/*`, `/_next/*`, `/favicon.ico`, `/manifest.json`, `/icons/*`, and any
  path with a file extension (mirrors the existing exclusion style already
  in the file).
- Add a small dependency-free helper, e.g. `lib/deviceDetect.ts` →
  `isMobileUserAgent(ua: string): boolean`, using a regex against the
  `User-Agent` header (`/Android|iPhone|iPod|Mobile|CriOS|FxiOS/i` —
  intentionally **excludes iPad/tablet UAs**, see open question below).
  Pure regex keeps it Edge-runtime-safe (no parsing library needed).
- In `middleware.ts`, before the existing auth logic: if the UA doesn't
  match and the path isn't already `/unsupported-device`, redirect there.
  This runs *before* the NextAuth token check, so it also blocks
  unauthenticated desktop visitors from ever reaching `/login`.
- **New page `app/unsupported-device/page.tsx`** — static, no session
  required: brand mark + "This app is only available on mobile devices.
  Please open it on your phone." No functionality, nothing fetched.
- Dev workflow note: Chrome/Safari device-emulation mode overrides the UA
  string, so local development still works by toggling the device toolbar.

## 2. PWA / installability

Goal: launching from the home screen hides the browser chrome entirely
(`display: standalone`), which does more for the "feels like a real app"
requirement than any CSS.

- `public/manifest.json` — `name`, `short_name`, `start_url: "/dashboard"`,
  `display: "standalone"`, `theme_color`/`background_color` derived from
  the existing `--primary` / `--background` tokens in `globals.css`,
  `icons` (192×192, 512×512, plus a maskable variant).
- `app/layout.tsx` — add the `viewport` export (Next 15 `Viewport` type):
  `width: "device-width", initialScale: 1, viewportFit: "cover"` (the
  `cover` value + `env(safe-area-inset-*)` padding is what makes the bottom
  tab bar and top bar sit correctly around the iPhone notch/home-indicator).
  Add `<link rel="manifest">`, `<link rel="apple-touch-icon">`,
  `<meta name="theme-color">`.
- Icons: no existing icon asset exists (the current brand mark is just an
  inline `<Dumbbell>` lucide icon). Implementation will generate a simple
  placeholder icon set (orange rounded-square + dumbbell glyph) at the
  required sizes; swap for real branding later.
- **Out of scope for this pass**: offline support / service worker /
  background sync. Nothing today requires offline reads, and adding
  Workbox/`next-pwa` is a separate, sizable decision — flagging it as a
  future option, not part of this rewrite.

## 3. Navigation architecture

Replaces the collapsible `Sidebar` system entirely.

- **Bottom tab bar**, 4 destinations, thumb-reachable, `fixed bottom-0` with
  `env(safe-area-inset-bottom)` padding: **Dashboard · Members · Payments ·
  More**. Active tab highlighted with the primary color.
- **"More" hub page** (new route) — a simple list of rows linking to: Plans,
  Reports, Activity Log, My Gyms, Settings, and a Sign Out action at the
  bottom. This is where the 3 lower-frequency nav items from the old
  sidebar (Plans, Reports, Activity Log) plus Gyms and the new Settings
  screen live.
- **Top app bar** on every tab-root screen: page title + the gym switcher
  control (gym avatar/name, tap → bottom sheet with searchable gym list —
  replaces `GymSwitcher.tsx`'s sidebar-coupled popover).
- **Drill-in pages** (member detail, edit forms, invoice) push full-screen
  with a **back-arrow header** and **hide the bottom tab bar** — standard
  "tab root shows tabs, anything pushed from it hides them" mobile pattern.
  Implementation detail: a client-side layout checks `usePathname()` against
  the 4 tab-root paths (+ `/dashboard/more`) to decide whether to render the
  tab bar, rather than fighting Next's layout nesting with route groups.
- **Forms — hybrid placement** (per your decision):
  - **Full-screen pages** (long forms): Add/Edit Member, Add/Edit Gym,
    Add/Edit Plan.
  - **Bottom sheets** (`components/ui/sheet.tsx`, `side="bottom"`, already
    in the repo): Record Payment, list filters (status/month/year), and all
    delete/destructive confirmations (replacing the centered `AlertDialog`).
- **Create actions**: a circular **FAB** bottom-right on Members, Payments,
  Plans, and Gyms list screens (per your decision), positioned above the
  tab bar with safe-area awareness.

## 4. Design system — what carries over vs. what's rewritten

**Kept as-is** (unopinionated primitives, not desktop-shaped):
`button.tsx`, `input.tsx`, `label.tsx`, `badge.tsx`, `avatar.tsx`,
`separator.tsx`, `popover.tsx`, `sonner.tsx` (toasts), `checkbox.tsx`,
`command.tsx` (used inside the new gym-picker sheet), `gym-avatar.tsx`.
Same CSS tokens in `globals.css`/`tailwind.config.ts` (colors, radius,
`shadow-card`) — same brand, new layouts.

**Deleted** (encode desktop layout assumptions, no mobile equivalent):
`components/ui/sidebar.tsx`, `components/ui/table.tsx` (no `<table>`
survives anywhere in the app), `components/layout/Sidebar.tsx`,
`components/layout/PageHeader.tsx`, `hooks/use-mobile.tsx` (superseded —
device capability is now decided once, server-side, not polled client-side).

**Rewritten from scratch** (same responsibility, mobile-native
implementation — not a resized version of the old component):
- `GymSwitcher.tsx` → bottom-sheet gym picker, triggered from the new top
  app bar instead of a sidebar popover.
- `ThemeToggle.tsx` → a plain row inside the new Settings screen.
- `StatCard.tsx` → compact stat tile with an inline **sparkline** replacing
  the separate full-size chart cards on Dashboard (see §6).
- `RevenueChart` / `MemberTrendChart` → horizontally-scrollable Recharts bar
  chart (fixed per-bar width, swipe instead of squeezing 12 months into
  340px) — kept for the Reports screen; Dashboard drops the full chart in
  favor of the StatCard sparkline (same underlying numbers, no data loss).
- Plan Distribution pie chart → ranked list with horizontal progress bars
  (same `planDistribution` API data, more legible than pie slices at phone
  width).
- `QuickActions.tsx` → 2×2 icon tile grid (Add Member / Record Payment /
  Send Reminders / Reports).
- `MemberFormDialog.tsx`, `GymFormDialog.tsx`, the inline plan form in
  `plans/page.tsx` → full-screen pages with a back header + sticky bottom
  submit button (not a centered `Dialog`).
- `PaymentFormDialog.tsx` → bottom sheet, same business logic
  (member search → optional plan → amount/method), restyled for a partial-
  height sheet.
- `PaymentBreakdown.tsx` → restacked vertically (3 side-by-side `flex-1`
  cells don't fit 375px cleanly); same data, one column.
- Every list table (Members, Payments, Activity, Member-detail's
  Memberships/Payments tabs) → **card list rows**, no `overflow-x-auto`
  escape hatch anywhere.
- `app/login/page.tsx` → single-column mobile layout (drop the
  desktop split-panel branding side entirely, not just hide it at a
  breakpoint).

**New components needed**: `BottomTabBar`, `TopAppBar`, `FAB`,
`BottomSheetForm` (shared sticky-footer wrapper for sheet-based forms,
mirroring the existing full-screen-form footer pattern), `StackHeader`
(back button + title, used on every drill-in page), `GymPickerSheet`,
`MemberCard` / `PaymentCard` / `ActivityRow` (the card-list row components
replacing table rows), `SparklineStat`.

**Form input conventions** (recommended defaults, applied everywhere):
- Replace the custom Radix-popover `DatePicker` with a native
  `<input type="date">` — it invokes the OS's native date wheel/picker,
  which is both more authentically mobile and removes a whole component's
  worth of overflow/positioning risk.
- Prefer native `<select>` (styled to match the design tokens) over the
  Radix `Select` for simple single-choice fields (status filter, payment
  method, gender, month/year) so it triggers the OS picker UI. Radix
  `Select`/`Command` stays only where custom rendering is genuinely needed
  (e.g. the searchable member picker in the Payment sheet).

## 5. Screen-by-screen spec

- **Login/Signup** (`app/login/page.tsx`) — single column, logo top,
  segmented Sign In / Sign Up control, large (h-12+) inputs, full-width
  primary button. Same `signIn("credentials")` / `POST /api/auth/signup`
  calls.
- **Dashboard** (`app/dashboard/page.tsx`) — top app bar with gym switcher;
  2×2 `QuickActions` tile grid; 4 `StatCard`s (Total Members, Active,
  Expiring Soon, Month Revenue) each with a small sparkline instead of the
  current full bar/line charts; "Expiring Soon" and "Recent Payments" as
  card lists (avatar, name, one-line meta, WhatsApp/SMS/amount), each with a
  "View all" link into the corresponding tab.
- **Members** (`app/dashboard/members/page.tsx`) — top app bar w/ search
  icon opening a search field inline (or a dedicated search state), filter
  icon opening a bottom sheet (status radio list), card list of members
  (avatar, name, due badge, phone as `tel:` link, plan, expiry status
  badge, kebab → actions), FAB → full-screen Add Member page.
- **Member detail** (`app/dashboard/members/[id]/page.tsx`) — `StackHeader`
  with back arrow; header block (avatar, name, status); action row
  (WhatsApp/SMS/Renew/Record Payment as icon buttons or a horizontal
  scroll strip); tabs (Overview/Memberships/Payments) keep `Tabs` but each
  tab's table becomes a card list; Record Payment opens the same bottom
  sheet used elsewhere; Edit opens the full-screen Member form pre-filled.
- **Payments** (`app/dashboard/payments/page.tsx`) — top app bar, filter
  icon → bottom sheet (month/year), card list (avatar, member name,
  invoice #, plan, amount, method badge, date, kebab → view invoice /
  delete-via-sheet-confirm), FAB → Record Payment bottom sheet.
- **Plans** (`app/dashboard/plans/page.tsx`, reached via More) — vertical
  stack of plan cards (already close to card-shaped today, just full-width
  single column instead of a 3-col grid), FAB → full-screen Plan form.
- **Reports** (`app/dashboard/reports/page.tsx`, via More) — year
  prev/next control in the top app bar; 3 stat tiles; horizontally-
  scrollable revenue bar chart; horizontally-scrollable new-members bar
  chart; Plan Distribution as a ranked progress-bar list (see §4).
- **Activity Log** (`app/dashboard/activity/page.tsx`, via More) — card
  list (staff avatar, action badge, entity + details, relative timestamp),
  infinite-scroll or "Load more" button instead of prev/next pagination
  buttons.
- **My Gyms** (`app/dashboard/gyms/page.tsx`, via More) — vertical card
  list (was already a responsive grid; becomes single column), FAB → 
  full-screen Add Gym page; switch/edit/delete actions per card, delete
  confirmed via bottom sheet.
- **Settings** (new — `app/dashboard/settings/`, currently an empty dir
  with no page) — theme toggle row, account info (name/email, read-only),
  sign-out row. Small net-new surface, but the directory already exists so
  this fills a real gap rather than inventing a new concept.
- **Invoice** (`app/dashboard/payments/[id]/invoice/page.tsx`) — kept
  print-first per `CLAUDE.md`, restyled single-column for a phone screen,
  `window.print()` retained (mobile Safari/Chrome route this to the native
  Share/Print sheet); consider adding a Web Share API button as a bonus,
  not required.

## 6. Routing map (old → new)

| Old | New |
|---|---|
| `/dashboard` | unchanged |
| `/dashboard/members`, `/dashboard/members/[id]` | unchanged |
| *(new)* | `/dashboard/members/new`, `/dashboard/members/[id]/edit` (full-screen forms, replacing the dialogs) |
| `/dashboard/payments`, `/dashboard/payments/[id]/invoice` | unchanged |
| `/dashboard/payments/new` (currently a dead redirect) | removed — Record Payment is a bottom sheet now, no dedicated route |
| `/dashboard/plans` | unchanged (reached via More) |
| *(new)* | `/dashboard/plans/new`, `/dashboard/plans/[id]/edit` |
| `/dashboard/reports`, `/dashboard/activity` | unchanged (reached via More) |
| `/dashboard/gyms` | unchanged (reached via More) |
| *(new)* | `/dashboard/gyms/new`, `/dashboard/gyms/[id]/edit` |
| `/dashboard/settings` (empty dir today) | becomes a real page |
| *(new)* | `/dashboard/more` (tab hub) |
| *(new)* | `/unsupported-device` |

## 7. Data layer — unchanged

`lib/useGymSettings.tsx`, `lib/hooks/useGyms.ts`, `lib/gymCookie.ts`,
`lib/selectedGym.ts`, `lib/withAuth.ts`, all `app/api/*` routes, all
Mongoose models, all Zod validators: **no changes**. Every new component
calls the exact same endpoints the old one did. `switchGym()`'s
cookie-write + context-update behavior is reused verbatim by the new
`GymPickerSheet`.

## 8. Decisions locked in

1. **Tablets (iPad/Android tablets): blocked**, same as desktop — the UA
   regex treats them as non-mobile and routes to `/unsupported-device`.
   Scope stays phone-only (~375–430px), no mid-size breakpoint needed.
2. **App icon**: no real logo file exists yet; a placeholder will be
   generated from the Dumbbell mark so the PWA manifest has something to
   ship. Swap in real artwork whenever it's ready.
3. **No test runner** (per `CLAUDE.md`) — verification will be
   `npm run build` for type-checking plus manual QA in Chrome DevTools
   device emulation (iPhone SE/12/14 Pro Max, a mid-range Android width)
   and ideally one real-device pass before calling any screen done.

## 9. Build phases

1. **Foundation** — device gating (`middleware.ts` + `/unsupported-device`),
   PWA manifest/icons/viewport, delete `Sidebar`/`sidebar.tsx`/`table.tsx`/
   `PageHeader.tsx`, scaffold `BottomTabBar`, `TopAppBar`, `StackHeader`,
   `FAB`, `BottomSheetForm`.
2. **Auth** — rewrite `app/login/page.tsx`.
3. **Shell + Dashboard** — tab layout wiring, `GymPickerSheet`,
   `QuickActions` tile grid, `SparklineStat`, Dashboard page.
4. **Members** — list (card rows, FAB, filter sheet), detail page
   (tabs → card lists), full-screen Add/Edit Member forms.
5. **Payments** — list (card rows, FAB, filter sheet), Record Payment
   bottom sheet, invoice page restyle.
6. **Plans, Reports, Activity, My Gyms, Settings, More hub**.
7. **Polish** — safe-area insets, tap/press feedback animations, empty
   states, loading skeletons matched to the new card layouts,
   `prefers-reduced-motion` handling.
8. **Verification** — `npm run build`, device-emulation pass per screen,
   confirm every business rule in `CLAUDE.md` (dues capping, renewal
   stacking, soft-delete visibility, newest-first payment deletion) still
   holds since only presentation changed.

## 10. Files touched (high level)

**Deleted**: `components/ui/sidebar.tsx`, `components/ui/table.tsx`,
`components/layout/Sidebar.tsx`, `components/layout/PageHeader.tsx`,
`hooks/use-mobile.tsx`.

**Rewritten**: `app/login/page.tsx`, `app/dashboard/layout.tsx`,
`app/dashboard/page.tsx`, `app/dashboard/members/page.tsx`,
`app/dashboard/members/[id]/page.tsx`, `app/dashboard/payments/page.tsx`,
`app/dashboard/payments/[id]/invoice/page.tsx`,
`app/dashboard/plans/page.tsx`, `app/dashboard/reports/page.tsx`,
`app/dashboard/activity/page.tsx`, `app/dashboard/gyms/page.tsx`,
`middleware.ts`, `app/layout.tsx`,
`components/dashboard/GymFormDialog.tsx` → full-screen form,
`components/dashboard/MemberFormDialog.tsx` → full-screen form,
`components/dashboard/PaymentFormDialog.tsx` → bottom sheet,
`components/dashboard/PaymentBreakdown.tsx`, `components/dashboard/StatCard.tsx`,
`components/dashboard/QuickActions.tsx`, `components/dashboard/RevenueChart.tsx`,
`components/dashboard/MemberTrendChart.tsx`, `components/layout/GymSwitcher.tsx`,
`components/layout/ThemeToggle.tsx`, `components/ui/date-picker.tsx`.

**New**: `app/unsupported-device/page.tsx`, `app/dashboard/more/page.tsx`,
`app/dashboard/settings/page.tsx`, `app/dashboard/members/new/page.tsx`,
`app/dashboard/members/[id]/edit/page.tsx`, `app/dashboard/plans/new/page.tsx`,
`app/dashboard/plans/[id]/edit/page.tsx`, `app/dashboard/gyms/new/page.tsx`,
`app/dashboard/gyms/[id]/edit/page.tsx`, `lib/deviceDetect.ts`,
`public/manifest.json` + icon assets,
`components/layout/BottomTabBar.tsx`, `components/layout/TopAppBar.tsx`,
`components/layout/StackHeader.tsx`, `components/ui/fab.tsx`,
`components/dashboard/MemberCard.tsx`, `components/dashboard/PaymentCard.tsx`,
`components/dashboard/ActivityRow.tsx`, `components/dashboard/SparklineStat.tsx`,
`components/dashboard/GymPickerSheet.tsx`.

**Unchanged**: everything in `app/api/`, `models/`, `lib/apiHandler.ts`,
`lib/withAuth.ts`, `lib/memberLedger.ts`, `lib/mongodb.ts`, `lib/session.ts`,
`lib/selectedGym.ts`, `lib/gymCookie.ts`, `lib/useGymSettings.tsx`,
`lib/hooks/useGyms.ts`, `lib/validators/*`, `lib/utils.ts`,
`components/Providers.tsx`, `components/dashboard/GymGuard.tsx`,
`components/dashboard/NoGymState.tsx` (restyled visually as part of the
mobile pass but same logic), and every low-level `components/ui/*`
primitive listed as "kept" in §4.
