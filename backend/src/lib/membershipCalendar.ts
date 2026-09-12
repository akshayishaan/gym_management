export type DateOnly = string;

const DATE_ONLY_PATTERN = /^\d{4}-\d{2}-\d{2}$/;

export function isDateOnly(value: string): value is DateOnly {
  if (!DATE_ONLY_PATTERN.test(value)) return false;
  const [year, month, day] = value.split("-").map(Number);
  const parsed = new Date(Date.UTC(year, month - 1, day));
  return parsed.getUTCFullYear() === year
    && parsed.getUTCMonth() === month - 1
    && parsed.getUTCDate() === day;
}

export function assertDateOnly(value: string): DateOnly {
  if (!isDateOnly(value)) throw new Error(`Invalid calendar date: ${value}`);
  return value;
}

export function isValidTimeZone(timeZone: string): boolean {
  try {
    new Intl.DateTimeFormat("en", { timeZone }).format(new Date());
    return true;
  } catch {
    return false;
  }
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

export function toDateOnly(value: Date | string, timeZone: string): DateOnly {
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

function timeZoneOffsetMs(value: Date, timeZone: string): number {
  const parts = datePartsInTimeZone(value, timeZone);
  const representedAsUtc = Date.UTC(
    parts.year,
    parts.month - 1,
    parts.day,
    parts.hour,
    parts.minute,
    parts.second
  );
  return representedAsUtc - Math.floor(value.getTime() / 1000) * 1000;
}

export function localDateTimeToInstant(
  date: DateOnly,
  timeZone: string,
  time: { hour?: number; minute?: number; second?: number; millisecond?: number } = {}
): Date {
  const [year, month, day] = assertDateOnly(date).split("-").map(Number);
  const intendedUtc = Date.UTC(
    year,
    month - 1,
    day,
    time.hour ?? 0,
    time.minute ?? 0,
    time.second ?? 0,
    time.millisecond ?? 0
  );
  let result = new Date(intendedUtc - timeZoneOffsetMs(new Date(intendedUtc), timeZone));
  result = new Date(intendedUtc - timeZoneOffsetMs(result, timeZone));
  return result;
}

export function localYearRange(year: number, timeZone: string) {
  return {
    start: localDateTimeToInstant(`${year}-01-01`, timeZone),
    end: localDateTimeToInstant(`${year + 1}-01-01`, timeZone),
  };
}

export function previousYearAsOf(asOf: Date, timeZone: string): Date {
  const parts = datePartsInTimeZone(asOf, timeZone);
  const previousYear = parts.year - 1;
  const maxDay = new Date(Date.UTC(previousYear, parts.month, 0)).getUTCDate();
  const date = `${previousYear}-${String(parts.month).padStart(2, "0")}-${String(Math.min(parts.day, maxDay)).padStart(2, "0")}`;
  return localDateTimeToInstant(date, timeZone, parts);
}
