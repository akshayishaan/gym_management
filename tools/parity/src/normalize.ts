const idKeys = new Set([
  "gymId",
  "memberId",
  "planId",
  "paymentId",
  "membershipId",
  "staffId",
  "createdBy",
  "grantedBy",
  "voidedBy",
  "refundedBy",
  "reversedBy",
  "entityId",
  "ownerId",
]);

const dateKeys = new Set([
  "createdAt",
  "updatedAt",
  "paidAt",
  "voidedAt",
  "refundedAt",
  "reversedAt",
  "asOf",
  "lastLogin",
  "refreshTokenExpiresAt",
]);

const tokenKeys = new Set(["accessToken", "refreshToken"]);

const HEX_ID_RE = /^[0-9a-f]{24}$/;

// Report plan keys (e.g. "id:gold", "legacy:silver").
const PLAN_KEY_RE = /^(id|legacy):/;

const JWT_RE = /^[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+$/;

const INVOICE_RE = /^INV-/;

// Strict full-ISO instant, e.g. "2026-09-12T13:45:00.000Z" or without offset.
// Intentionally REQUIRES the `T` separator and a time-of-day component so
// date-only ("2026-09-12") and year-only ("2026") strings can NEVER match.
const ISO_DATE_RE =
  /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:Z|[+-]\d{2}:\d{2})?$/;

function isPlainObject(value: unknown): value is Record<string, unknown> {
  if (value === null || typeof value !== "object") return false;
  const proto = Object.getPrototypeOf(value);
  return proto === Object.prototype || proto === null;
}

function isIsoDate(value: string): boolean {
  return ISO_DATE_RE.test(value);
}

export function normalizeValue(value: unknown): unknown {
  if (Array.isArray(value)) {
    return value.map((item) => normalizeValue(item));
  }

  if (isPlainObject(value)) {
    return reduceEntries(value);
  }

  if (typeof value === "string") {
    return normalizeString(value);
  }

  // number / boolean / null / undefined pass through unchanged.
  return value;
}

function reduceEntries(obj: Record<string, unknown>): Record<string, unknown> {
  const result: Record<string, unknown> = {};

  for (const [key, value] of Object.entries(obj)) {
    result[key] = normalizeField(key, value);
  }

  return result;
}

function normalizeField(key: string, value: unknown): unknown {
  // Token-shaped values win regardless of key.
  if (typeof value === "string" && JWT_RE.test(value)) {
    return "<token>";
  }

  if (idKeys.has(key)) {
    if (typeof value === "string") {
      if (HEX_ID_RE.test(value)) return "<id>";
      if (PLAN_KEY_RE.test(value)) return "<planKey>";
    }
    return normalizeValue(value);
  }

  if (key === "_id") {
    if (typeof value === "string" && HEX_ID_RE.test(value)) return "<id>";
    return normalizeValue(value);
  }

  if (dateKeys.has(key)) {
    if (typeof value === "string" && isIsoDate(value)) return "<date>";
    return normalizeValue(value);
  }

  if (key === "invoiceNumber") {
    if (typeof value === "string" && INVOICE_RE.test(value)) return "<invoice>";
    return normalizeValue(value);
  }

  if (tokenKeys.has(key)) {
    if (typeof value === "string") return "<token>";
    return normalizeValue(value);
  }

  return normalizeValue(value);
}

function normalizeString(value: string): unknown {
  // JSON-encoded fields (only attempt when it clearly looks like JSON).
  if (value.startsWith("{") || value.startsWith("[")) {
    const trimmed = value.trim();
    if (trimmed.startsWith("{") || trimmed.startsWith("[")) {
      try {
        const parsed: unknown = JSON.parse(trimmed);
        return stableSerialize(normalizeValue(parsed));
      } catch {
        // Not valid JSON — fall through to other rules.
      }
    }
  }

  //
  // NOTE on bare 24-hex masking: this rule is deliberately NARROW. We only
  // mask a bare 24-hex string when it is shaped like a MongoDB ObjectId
  //   (a) exactly 24 hex chars, AND
  //   (b) elapsed within the "ObjectId timestamp" epoch (the first 4 bytes
  //       encode a Unix-second that is >= 0x00000000 and < an implausible
  //       future bound), so arbitrary 24-char hex payloads are left untouched.
  //
  // Field-named ids are handled by `idKeys` above, which is the only fully
  // reliable signal. A bare string carries no field-name context, so we accept
  // a tradeoff: a bare 24-hex value that is NOT an ObjectId (but happens to
  // fall inside the epoch window) would still be masked. That window is large
  // (roughly 1970 → 2106), so in practice only genuine ObjectIds are masked.
  //
  // Date-only membership strings ("YYYY-MM-DD") never match HEX_ID_RE (too
  // short and contain hyphens), so they are left UNTOUCHED.
  if (HEX_ID_RE.test(value) && isObjectIdEpoch(value)) return "<id>";
  if (isIsoDate(value)) return "<date>";
  if (INVOICE_RE.test(value)) return "<invoice>";
  if (JWT_RE.test(value)) return "<token>";

  return value;
}

/**
 * True when a bare 24-hex string decodes to a plausible ObjectId timestamp.
 * ObjectId embeds a 4-byte big-endian Unix-second at the front; we accept any
 * value in the sane range 1970-01-01 → 2106-02-07 (rejecting 0 and all-0xff).
 */
function isObjectIdEpoch(value: string): boolean {
  const stamp = Number.parseInt(value.slice(0, 8), 16);
  if (!Number.isFinite(stamp) || stamp <= 0 || stamp >= 0xffffffff) return false;
  return true;
}

export function stableSerialize(value: unknown): string {
  return JSON.stringify(value, sortKeysReplacer);
}

function sortKeysReplacer(_key: string, value: unknown): unknown {
  if (Array.isArray(value)) {
    return value;
  }

  if (isPlainObject(value)) {
    const sorted: Record<string, unknown> = {};
    for (const key of Object.keys(value).sort()) {
      sorted[key] = value[key];
    }
    return sorted;
  }

  return value;
}
