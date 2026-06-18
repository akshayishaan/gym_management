import { type ClassValue, clsx } from "clsx";
import { twMerge } from "tailwind-merge";

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

export function formatCurrency(amount: number, currency = "INR") {
  return new Intl.NumberFormat("en-IN", {
    style: "currency",
    currency,
    maximumFractionDigits: 0,
  }).format(amount);
}

export function formatDate(date: string | Date) {
  return new Intl.DateTimeFormat("en-IN", {
    day: "2-digit",
    month: "short",
    year: "numeric",
  }).format(new Date(date));
}

export function daysUntilExpiry(expiryDate: string | Date): number {
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const expiry = new Date(expiryDate);
  expiry.setHours(0, 0, 0, 0);
  const diff = expiry.getTime() - today.getTime();
  return Math.ceil(diff / (1000 * 60 * 60 * 24));
}

export function getMemberStatus(expiryDate: string | Date): "active" | "expiring" | "expired" {
  const days = daysUntilExpiry(expiryDate);
  if (days < 0) return "expired";
  if (days <= 7) return "expiring";
  return "active";
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
 * Must be called after connectDB().
 */
export async function generateInvoiceNumber(): Promise<string> {
  const { default: Counter } = await import("@/models/Counter");
  const now = new Date();
  const y = now.getFullYear().toString().slice(-2);
  const m = String(now.getMonth() + 1).padStart(2, "0");
  const prefix = `${y}${m}`;

  const counter = await Counter.findOneAndUpdate(
    { _id: `invoice-${prefix}` },
    { $inc: { seq: 1 } },
    { upsert: true, returnDocument: "after" }
  );

  return `INV-${prefix}-${String(counter.seq).padStart(4, "0")}`;
}
