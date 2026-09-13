# 03 — Calendar/Utils pure-function port

**What to build:** The pure utility modules are ported verbatim so every date/number/format helper behaves identically: `lib/membershipCalendar.ts` (todayInTimeZone, addCalendarDays, calculateMembershipExpiry, membershipStatus, localYearRange, timezone offset math), `lib/utils.ts` (formatCurrency, formatDate, daysUntilExpiry, getMemberStatus, buildWhatsAppLink/buildSmsLink, generateInvoiceNumber via Counter), `lib/planUtils.ts`, `lib/clientRequestId.ts`.

**Blocked by:** 01

**Status:** ready-for-agent

- [ ] All calendar functions ported with identical timezone-correct behaviour (gym-local YYYY-MM-DD only)
- [ ] generateInvoiceNumber produces identical INV-YYMM-NNNN sequence using atomic Counter
- [ ] formatCurrency/formatDate match current en-IN output
- [ ] Build passes; spot-check a few known inputs against the existing app
