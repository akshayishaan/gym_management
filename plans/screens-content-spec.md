# Gym Manager — Mobile App Screen Content Specification

This document describes the **content and functionality** of every screen in
a gym-management mobile app — what information is shown, what a person can
do on each screen, what states each screen can be in, and the business
rules that govern the data. It intentionally does **not** prescribe layout,
component choices (cards vs. lists vs. sheets vs. pages), navigation chrome,
or visual arrangement — that is left entirely open for a fresh design.

**Every screen described below is a mobile phone app screen** (portrait,
touch-first, ~375–430px wide). There is no desktop or tablet version.

## Suggested theme direction (optional starting point)

- **Primary / brand**: a warm, energetic orange-red (fitness, motivation,
  energy) — e.g. `#F97316`-ish. Not prescriptive; a design tool should feel
  free to propose an alternative energetic primary color.
- **Success**: green — used for "active," "paid," "cleared," positive states.
- **Warning**: amber/yellow — used for "expiring soon," "due," "pending."
- **Destructive**: red — used for "expired," "delete," negative states.
- **Neutral**: a clean light-gray/white background with a dark near-black
  text color; the app should also support a dark theme (dark background,
  light text) using the same semantic color roles (primary/success/warning/
  destructive stay recognizable in both modes).
- Currency values are formatted per the gym's configured currency (INR ₹,
  USD $, EUR €, GBP £ are the four supported currencies).

## Global concepts referenced across screens

- **Gym**: the tenant/organization. A person can belong to and switch
  between multiple gyms. One gym is "active" at a time — all data shown
  everywhere in the app (members, payments, plans, reports, activity) is
  scoped to the active gym.
- **Member status**: derived from a member's membership expiry date —
  **Active** (expiry is in the future, more than 7 days away), **Expiring
  Soon** (expiry within the next 7 days), or **Expired** (expiry date has
  passed). A member with no plan/expiry has no status.
- **Due amount**: a running balance per member — the total plan price(s)
  owed minus total payments made. Zero means "paid in full."
- **Soft delete**: deleting a member doesn't erase them — they're marked
  deleted and can be restored later. Deleted members are hidden from normal
  lists but their detail record remains viewable.

---

## 1. Login Screen

**Purpose**: authenticate an existing staff account.

**Content**:
- App name / logo mark
- Email input field
- Password input field
- A way to submit and sign in
- A way to switch to the Sign Up screen for a new account
- Error feedback when email/password is incorrect

**States**: idle, submitting (button shows a loading state), error (invalid
credentials message).

## 2. Sign Up Screen

**Purpose**: self-register a new staff account.

**Content**:
- Full name input
- Email input
- Password input
- Confirm password input
- A way to submit and create the account
- A way to switch back to the Login screen

**Rules**:
- Password and confirm-password must match (client-side check before
  submit).
- Minimum password length of 6 characters.
- On success, the person is guided to sign in with their new credentials.
- A newly signed-up account has no gym yet — after signing in they must
  create or be added to a gym before anything else is usable (see "No Gym"
  state below).

**States**: idle, submitting, error (e.g. "email already registered",
"passwords do not match").

## 3. "No Gym" State

**Purpose**: shown in place of any main content when a signed-in person has
zero gyms associated with their account yet.

**Content**:
- Explanation that a gym must be created first
- A call to action to create the first gym (opens the Add Gym flow,
  described below)

## 4. Dashboard / Home Screen

**Purpose**: the landing screen after login — an at-a-glance overview of the
active gym's health.

**Content — quick actions** (shortcuts to the most common tasks):
- Add Member
- Record Payment
- Send Reminders (jumps to the expiring-members list)
- View Reports

**Content — stat summary** (four figures, each a number/currency amount):
- Total Members — all-time registrations count
- Active Members — members with a currently valid membership
- Expiring Soon — members whose membership expires within 7 days
- This Month's Revenue — total payments collected in the current
  calendar month, in the gym's currency

Each stat can optionally show a small illustrative trend indicator (not
based on precise historical data — just a lightweight visual cue of
direction), and the numbers should count up/animate on load.

**Content — Expiring Soon list** (a short list, e.g. top 5):
For each member: avatar/initials, name, plan name (or "No plan"), expiry
date, a day-count badge (e.g. "3d" or "Today"), and quick contact actions
(WhatsApp message, SMS) pre-filled with a renewal reminder message. A link
to view the full expiring-members list.

**Content — Recent Payments list** (a short list, e.g. top 5):
For each payment: avatar/initials, member name, payment method, date, and
amount (in success/green styling). A link to view the full payments list.

**Empty states**: "No members expiring soon — all memberships are up to
date" / "No payments yet — record your first payment to see it here."

**States**: loading (skeleton placeholders for stats and lists), loaded.

## 5. Members List Screen

**Purpose**: browse, search, and filter every member of the active gym.

**Content**:
- A running count: "N total members"
- A text search (searches by name, phone, or email)
- A status filter: All / Active / Expiring Soon / Expired
- A list of members, each showing: avatar/initials, name, an outstanding
  due-amount badge (only if they owe money, e.g. "₹500 due"), phone number
  (tappable to call), current plan name (or "No plan"), membership expiry
  date, and a status badge (Active / Expiring / Expired) — for members
  expiring within 7 days, the badge shows a day count instead (e.g. "3d")
- Per-member quick actions: View Details, Renew Membership (only shown for
  Expiring/Expired members), Edit, message via WhatsApp, message via SMS,
  Delete (with a confirmation step warning the action can't be undone)
- A way to start adding a brand-new member

**Empty state**: "No members found — try adjusting your search or
filters."

**States**: loading (placeholder rows), loaded, empty (zero results).

## 6. Member Detail Screen

**Purpose**: the full record for one member, including their membership and
payment history.

**Content — header**:
- Avatar/initials, full name, current status badge (Active/Expiring/
  Expired), or a "Deleted" badge if the member has been soft-deleted
- Current plan name (or "No plan assigned") and phone number

**Content — quick actions** (hidden/replaced with "Restore Member" if the
member is deleted):
- Message via WhatsApp (pre-filled renewal reminder)
- Message via SMS (same message)
- Renew (shown only when the member's status is Expiring or Expired) —
  opens the Record Payment flow pre-filled for this member
- Record Payment — opens the Record Payment flow pre-filled for this
  member
- Edit — opens the Edit Member flow, pre-filled with this member's data

**Content — Overview section**:
- Personal Info: phone, email, gender, date of birth, address, emergency
  contact, notes (each only shown if present)
- Membership: current plan, start date, expiry date, status, and
  outstanding balance (a "Paid in full" badge or a "₹X due" badge)

**Content — Membership History section** (every past and current
membership period, newest first): for each period — plan name, purchase
date, the period's start–end date range, duration in days, and the price
paid for that period, plus a status badge for that period.

**Content — Payment History section** (every payment made by this member,
newest first): for each payment — invoice number, plan name (or none for a
dues-only payment), payment method, date, and amount.

**Empty states**: "No membership history yet" / "No payments yet."

**States**: loading (skeleton), loaded.

## 7. Add Member Flow

**Purpose**: register a brand-new member, optionally starting a paid
membership at the same time.

**Content — Personal Info** (required fields marked):
- Full Name *(required)*
- Phone *(required)*
- Email
- Date of Birth
- Gender (Male / Female / Other)
- Address
- Emergency Contact
- Notes (free text — allergies, goals, preferences, etc.)

**Content — Membership** (optional — only relevant if a plan is being sold
right away):
- Plan selector (lists the gym's active plans with their price and
  duration; "No plan" is a valid choice, meaning just register the person
  without starting a membership yet)
- If a plan is chosen: Start Date (defaults to today) and an
  auto-calculated, read-only Expiry Date
- If a plan is chosen: Amount Paid (defaults to the full plan price but can
  be a partial payment) and Payment Method (Cash / Card / UPI / Bank
  Transfer / Other)
- A running breakdown showing plan price, amount being paid, and the
  resulting balance (paid-in-full or amount still due)

**Rules**: Name and Phone are mandatory; everything else is optional. If no
plan is selected, the member is created with no membership/dues at all.

**States**: idle, submitting ("Adding…"), success (toast confirmation),
validation error (e.g. missing name/phone).

## 8. Edit Member Flow

**Purpose**: update an existing member's personal details.

**Content**: the same Personal Info fields as Add Member (Full Name, Phone,
Email, Date of Birth, Gender, Address, Emergency Contact, Notes),
pre-filled with the member's current values. Does **not** include the
Membership/Payment section — changing a membership happens via Record
Payment / Renew, not through editing personal info.

**States**: idle, submitting ("Saving…"), success, validation error.

## 9. Payments List Screen

**Purpose**: browse every payment recorded for the active gym.

**Content**:
- A running summary: "N records · Total: ₹X" (total reflects the currently
  applied filter)
- A month/year filter (defaults to the current month; can be cleared to
  show all payments, or narrowed to any month within the last 5 years)
- A list of payments, each showing: member avatar/initials and name
  (tapping navigates to that member's detail screen), invoice number, plan
  name (or none), amount (in success/green styling), a payment-method
  badge (Cash / Card / UPI / Bank Transfer / Other), and the payment date
- Per-payment actions: View Invoice, Delete (only the single most-recent
  payment for a member can be deleted — this is enforced, not just a UI
  suggestion)
- A way to start recording a new payment

**Empty state**: "No payments found" — with context-aware sub-text
depending on whether a month filter is active.

**States**: loading, loaded, empty.

## 10. Record Payment Flow

**Purpose**: the single place where money changes hands — either clearing
an existing balance, or selling/renewing a membership plan. A payment is
always one or the other, never both at once.

**Content — Member selection**: search-and-select from the gym's members
(shows name, phone, and any existing due amount per result) — or, when
launched from a specific member's context (e.g. from their detail screen),
the member is pre-set and locked.

**Content — Plan (optional)**: a selector for the gym's active plans,
defaulting to "No plan — clear dues only." Choosing a plan switches the
form into the **membership path**; leaving it unset stays on the **dues
path**.

**Membership path** (a plan is selected):
- Membership Start Date — defaults to today, or to the member's current
  expiry date if their membership is still active (so renewals stack
  on top of remaining time rather than losing it)
- A read-only preview of the resulting active-until date
- Amount ($) — defaults to the full plan price; can be a partial payment,
  capped at the plan price
- A breakdown: plan price, amount being paid, resulting balance
  (paid-in-full or amount still due for this specific plan purchase)
- If the member separately has old outstanding dues, a note explains those
  need a separate no-plan payment to clear
- Payment Method (Cash / Card / UPI / Bank Transfer / Other)
- Notes (optional free text)

**Dues path** (no plan selected):
- If the member has outstanding dues: Amount ($), capped at the
  outstanding balance; a breakdown showing outstanding dues, amount paid,
  and remaining due (or "Cleared")
- If the member has zero outstanding dues: a message explaining there's
  nothing to record and to select a plan instead to start/renew a
  membership — in this case the form has nothing submittable

**States**: idle, submitting ("Recording…"), success, validation errors
(no member selected, invalid/zero amount, amount exceeds what's owed, no
payment method chosen).

## 11. Invoice Screen

**Purpose**: a formal, printable/shareable receipt for one payment.

**Content**:
- Gym name, address, phone, email (whichever are configured)
- "INVOICE" label, invoice number, payment date
- "Bill To" — the member's name
- A line item: plan name (or "Membership Fee" if no plan), any notes on the
  payment, and the amount
- Total amount
- Payment method
- A "PAID" confirmation badge
- A closing thank-you line
- A way to print / save as PDF (and optionally share, e.g. via the
  device's native share sheet)

**States**: loading, loaded.

## 12. Plans List Screen

**Purpose**: manage the gym's membership plan offerings.

**Content**:
- A running count: "N plans configured"
- A list of plans, each showing: plan name, an "Inactive" badge if
  deactivated, description, price (large/prominent), duration in days, an
  approximate per-day cost, and a bulleted list of included features (if
  any)
- Per-plan actions (admin only): Edit, and Activate/Deactivate (deactivated
  plans can no longer be assigned to new members/payments but remain
  visible for historical reference — plans are never hard-deleted)
- A way to create a new plan (admin only)

**Empty state**: "No plans yet — create your first membership plan to get
started."

**States**: loading, loaded, empty.

## 13. Add/Edit Plan Flow

**Purpose**: create or update a membership plan definition.

**Content**:
- Name *(required)* — e.g. "Monthly," "Quarterly," "Annual"
- Description (short free text)
- Duration in days *(required)*
- Price *(required)*
- Features — a free-form list of included perks (e.g. "Locker room,
  Personal trainer, Pool access"), entered as a simple comma-separated list
- An active/inactive toggle ("Plan is active and available to members")

**States**: idle, submitting ("Saving…" / "Creating…"), success, validation
error (missing name, invalid duration, invalid price).

## 14. Reports Screen

**Purpose**: yearly business analytics for the active gym.

**Content**:
- A year selector (previous/next year navigation)
- Three summary stats for the selected year: Total Revenue (with average
  per month), New Members (with average per month), Total Payments
  (transaction count)
- Monthly Revenue — revenue collected in each of the 12 months of the
  selected year
- New Members per Month — how many new members joined in each of the 12
  months
- Plan Distribution — what share of members are on each plan, as a ranked
  breakdown with percentages (e.g. "Monthly — 45 members — 60%")

**Empty state** (plan distribution): "No data yet — add members to see
plan distribution."

**States**: loading, loaded.

## 15. Activity Log Screen

**Purpose**: an audit trail of every meaningful action taken in the gym
(who did what, and when) — members created/updated/deleted, payments
recorded/deleted, plans changed, gym settings changed, etc.

**Content**:
- A running count: "N total activities"
- A list of log entries, each showing: staff member's avatar/initials and
  name, an action badge (Created / Updated / Deleted, color-coded), the
  entity affected (e.g. "member," "payment," "plan"), a short human-
  readable detail string, and a timestamp
- A way to load additional older entries beyond the first page

**Empty state**: "No activity yet — actions will appear here as they
happen."

**States**: loading, loaded (with a distinct "loading more" state while
fetching additional entries).

## 16. My Gyms Screen

**Purpose**: manage every gym location the signed-in person has access to,
and switch which one is currently active.

**Content**:
- A list of gyms, each showing: logo (or generated initials avatar in the
  gym's theme color), name, an Active/Inactive status badge, a "Current"
  badge on whichever gym is presently selected, and (if set) address,
  phone, email
- Per-gym actions: Switch to this gym (disabled/replaced with "Current
  Gym" label for the already-active one), Edit, Delete (with a strong
  confirmation warning that deleting a gym permanently removes **all**
  of its members, plans, payments, and activity logs — this cannot be
  undone)
- A way to add a new gym

**Empty state**: "No gyms yet — create your first gym to start managing
members and payments."

**States**: loading, loaded, empty.

## 17. Add/Edit Gym Flow

**Purpose**: create or update a gym's identity and branding.

**Content**:
- Logo — upload an image (max 500 KB); falls back to a generated initials
  avatar if none is set
- Name *(required)*
- Phone
- Email
- Address
- Currency — a 3-letter currency code (INR / USD / EUR / GBP supported)
- Theme Color — a color picker plus a set of quick preset swatches; this
  color is used to tint that gym's branded elements (e.g. its avatar/logo
  background) throughout the app

**States**: idle, submitting ("Saving…" / "Creating…"), success, validation
error (missing name, invalid currency code, invalid color format).

## 18. Switch Gym / Gym Picker

**Purpose**: quickly jump between gyms without leaving the current screen,
available from anywhere in the app.

**Content**:
- A searchable list of every gym the person has access to, each showing
  logo/initials and name, with a checkmark on the currently active one
- Selecting a different gym switches the active context immediately (all
  screens' data refreshes to the newly selected gym)
- A way to add a new gym from within this picker

## 19. More / Menu Screen

**Purpose**: a hub for less-frequently-used destinations and account
actions.

**Content**:
- A profile summary: the signed-in person's avatar/initials, name, and
  email
- Menu entries linking to: Plans, Reports, Activity Log, My Gyms, Settings
- A Sign Out action

## 20. Settings Screen

**Purpose**: personal app preferences and account info.

**Content**:
- Account section (read-only): name, email
- Preferences: a light/dark theme toggle
- A Sign Out action

## 21. Unsupported Device Screen

**Purpose**: shown instead of the app to anyone opening it on a non-phone
device (desktop or tablet browser).

**Content**:
- A brief, friendly explanation: this app is only available on mobile
  devices — please open it on your phone.
- No functional content or navigation — this is a dead end by design.
