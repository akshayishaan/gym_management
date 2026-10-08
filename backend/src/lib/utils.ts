import type { ClientSession } from "mongoose";
import {
  calendarDaysBetween,
  isDateOnly,
  membershipStatus,
  todayInTimeZone,
} from "./membershipCalendar";
import { Counter } from "../schemas";

export function formatCurrency(amount: number, currency = "INR") {
  return new Intl.NumberFormat("en-IN", {
    style: "currency",
    currency,
    maximumFractionDigits: 0,
  }).format(amount);
}

export function formatDate(date: string | Date) {
  if (typeof date === "string" && isDateOnly(date)) {
    const [year, month, day] = date.split("-").map(Number);
    return new Intl.DateTimeFormat("en-IN", {
      day: "2-digit",
      month: "short",
      year: "numeric",
      timeZone: "UTC",
    }).format(new Date(Date.UTC(year, month - 1, day)));
  }
  return new Intl.DateTimeFormat("en-IN", {
    day: "2-digit",
    month: "short",
    year: "numeric",
  }).format(new Date(date));
}

export function daysUntilExpiry(
  expiryDate: string | Date,
  timeZone = Intl.DateTimeFormat().resolvedOptions().timeZone
): number {
  const today = todayInTimeZone(timeZone);
  const expiry = typeof expiryDate === "string" && isDateOnly(expiryDate)
    ? expiryDate
    : todayInTimeZone(timeZone, new Date(expiryDate));
  return calendarDaysBetween(today, expiry);
}

export function getMemberStatus(
  expiryDate: string | Date,
  timeZone = Intl.DateTimeFormat().resolvedOptions().timeZone
): "active" | "expiring" | "expired" {
  const today = todayInTimeZone(timeZone);
  const expiry = typeof expiryDate === "string" && isDateOnly(expiryDate)
    ? expiryDate
    : todayInTimeZone(timeZone, new Date(expiryDate));
  return membershipStatus(expiry, today);
}

export function buildSmsLink(phone: string, message: string) {
  const clean = phone.replace(/\D/g, "");
  return `sms:${clean}?body=${encodeURIComponent(message)}`;
}

export function buildWhatsAppLink(phone: string, message: string) {
  // Remove leading zeros, spaces, dashes; add country code if needed
  let clean = phone.replace(/\D/g, "");
  if (clean.startsWith("0")) clean = clean.slice(1);
  return `https://wa.me/${clean}?text=${encodeURIComponent(message)}`;
}

/**
 * Generate a concurrency-safe invoice number using an atomic MongoDB counter.
 * Format: INV-YYMM-NNNN (e.g. INV-2606-0001)
 */
export async function generateInvoiceNumber(session?: ClientSession): Promise<string> {
  const now = new Date();
  const y = now.getFullYear().toString().slice(-2);
  const m = String(now.getMonth() + 1).padStart(2, "0");
  const prefix = `${y}${m}`;

  const counter = await Counter.findOneAndUpdate(
    { _id: `invoice-${prefix}` },
    { $inc: { seq: 1 } },
    { upsert: true, returnDocument: "after", session }
  );

  return `INV-${prefix}-${String(counter.seq).padStart(4, "0")}`;
}
