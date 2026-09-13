# Only the backend computes gym-local dates; the Flutter app never does date math

All calendar/date derivation (gym-local "today", membership start/expiry, year ranges, status like expiring/expired) stays on the server, which ports `lib/membershipCalendar.ts` verbatim. Dart has no built-in IANA timezone support (`DateTime.now()` is device-local), so client-side date math would drift or mishandle non-local timezones. The Flutter app renders `YYYY-MM-DD` strings and any server-computed display values but never derives "today", expiry, duration, or member status locally.

Status: accepted
Considered Options: Bundling `timezone` + tzdata in Dart to replicate `Intl.DateTimeFormat` timezone math client-side (rejected — duplicates calendar logic in a second language, the exact drift risk, plus a large tzdata dependency); using the device clock (rejected — wrong "today" when device tz ≠ gym tz).
