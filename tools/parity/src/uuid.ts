/**
 * Creates an RFC 4122 v4 UUID for idempotency keys.
 *
 * Uses `crypto.randomUUID()` (a Node 24 global). A defensive fallback via
 * `crypto.getRandomValues` is provided only in case `randomUUID` is somehow
 * absent (not expected to run in this environment).
 */
export function createRequestId(): string {
  const cryptoGlobal = globalThis.crypto;

  if (cryptoGlobal && typeof cryptoGlobal.randomUUID === "function") {
    return cryptoGlobal.randomUUID();
  }

  // Fallback: assemble a v4 UUID from 16 random bytes, setting the
  // version (4) and variant (10xx) bits by hand.
  const bytes = new Uint8Array(16);
  cryptoGlobal.getRandomValues(bytes);

  bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
  bytes[8] = (bytes[8] & 0x3f) | 0x80; // variant 10xx

  const hex = [...bytes].map((b) => b.toString(16).padStart(2, "0")).join("");

  return `${hex.slice(0, 8)}-${hex.slice(8, 12)}-${hex.slice(12, 16)}-${hex.slice(16, 20)}-${hex.slice(20)}`;
}
