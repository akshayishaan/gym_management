const COOKIE_NAME = "selectedGymId";
const MAX_AGE = 30 * 24 * 60 * 60; // 30 days

/**
 * Read the selected gym ID from the browser cookie.
 * Returns null during SSR or when no cookie is set.
 */
export function getGymCookie(): string | null {
  if (typeof document === "undefined") return null;
  const match = document.cookie
    .split("; ")
    .find((r) => r.startsWith(`${COOKIE_NAME}=`));
  return match ? match.split("=")[1] : null;
}

/**
 * Write the selected gym ID to the browser cookie.
 * Not httpOnly — intentionally JS-readable so the client can:
 * - Initialise the selected gym on load without an API call
 * - Switch gyms without a server round-trip
 * The server still validates this cookie against user.gymIds on every
 * request (lib/selectedGym.ts), so a tampered value just falls back to
 * the user's first gym.
 */
export function setGymCookie(gymId: string): void {
  const secure =
    typeof window !== "undefined" && window.location.protocol === "https:"
      ? "; Secure"
      : "";
  document.cookie = `${COOKIE_NAME}=${gymId}; path=/; max-age=${MAX_AGE}; SameSite=Lax${secure}`;
}
