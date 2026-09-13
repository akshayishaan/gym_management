// ============================================================================
// KEEP IN SYNC with backend/src/lib/membershipCalendar.ts
// ============================================================================
//
// This file is a SELF-CONTAINED copy of the five canonical calendar functions
// the NestJS backend uses to compute the server-owned display-status fields
// (ADR-0005). The parity harness has its own `rootDir: src` and must NOT import
// across `../../backend/src`, so the math is duplicated here and kept verbatim.
//
// If you change any of these algorithms in the backend, mirror the change here
// or the display-status verification will drift.
// ============================================================================

export type DateOnly = string;

const DATE_ONLY_PATTERN = /^\d{4}-\d{2}-\d{2}$/;

function isDateOnly(value: string): value is DateOnly {
  if (!DATE_ONLY_PATTERN.test(value)) return false;
  const [year, month, day] = value.split("-").map(Number);
  const parsed = new Date(Date.UTC(year, month - 1, day));
  return parsed.getUTCFullYear() === year
    && parsed.getUTCMonth() === month - 1
    && parsed.getUTCDate() === day;
}

function assertDateOnly(value: string): DateOnly {
  if (!isDateOnly(value)) throw new Error(`Invalid calendar date: ${value}`);
  return value;
}

function datePartsInTimeZone(value: Date, timeZone: string) {
  const parts = new Intl.DateTimeFormat("en-CA", {
    timeZone,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit",
    hourCycle: "h23",
  }).formatToParts(value);
  const get = (type: Intl.DateTimeFormatPartTypes) =>
    Number(parts.find((part) => part.type === type)?.value ?? 0);
  return {
    year: get("year"),
    month: get("month"),
    day: get("day"),
    hour: get("hour"),
    minute: get("minute"),
    second: get("second"),
  };
}

function toDateOnly(value: Date | string, timeZone: string): DateOnly {
  if (typeof value === "string" && isDateOnly(value)) return value;
  const date = value instanceof Date ? value : new Date(value);
  if (Number.isNaN(date.getTime())) throw new Error(`Invalid date value: ${String(value)}`);
  const parts = datePartsInTimeZone(date, timeZone);
  return `${String(parts.year).padStart(4, "0")}-${String(parts.month).padStart(2, "0")}-${String(parts.day).padStart(2, "0")}`;
}

export function todayInTimeZone(timeZone: string, asOf = new Date()): DateOnly {
  return toDateOnly(asOf, timeZone);
}

function dateOnlyAsUtc(value: DateOnly): Date {
  const [year, month, day] = assertDateOnly(value).split("-").map(Number);
  return new Date(Date.UTC(year, month - 1, day));
}

export function addCalendarDays(value: DateOnly, days: number): DateOnly {
  const date = dateOnlyAsUtc(value);
  date.setUTCDate(date.getUTCDate() + days);
  return date.toISOString().slice(0, 10);
}

export function calendarDaysBetween(start: DateOnly, end: DateOnly): number {
  return Math.round((dateOnlyAsUtc(end).getTime() - dateOnlyAsUtc(start).getTime()) / 86_400_000);
}

export function calculateMembershipExpiry(start: DateOnly, durationDays: number): DateOnly {
  if (!Number.isInteger(durationDays) || durationDays < 1) {
    throw new Error("Membership duration must be at least one day");
  }
  return addCalendarDays(start, durationDays - 1);
}

export function membershipStatus(
  expiryDate: DateOnly,
  today: DateOnly,
  expiringWithinDays = 7
): "active" | "expiring" | "expired" {
  if (expiryDate < today) return "expired";
  return calendarDaysBetween(today, expiryDate) <= expiringWithinDays ? "expiring" : "active";
}

/**
 * "Today" in the parity gym's fixed timezone (`Asia/Kolkata`), as a `YYYY-MM-DD`
 * date-only string. Centralized here so the seed and the display-status
 * verifier derive the same value from the same implementation.
 */
export function todayInGymTz(asOf = new Date()): DateOnly {
  return todayInTimeZone("Asia/Kolkata", asOf);
}
