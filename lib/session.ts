/**
 * Typed session user extracted from NextAuth session.
 */
export interface SessionUser {
  id: string;
  name?: string | null;
  email?: string | null;
  role: "superadmin" | "admin" | "receptionist" | "trainer";
  gymIds: string[];        // all gyms this user has access to
  selectedGymId?: string;  // currently active gym (set from cookie)
}

export function getSessionUser(session: { user?: unknown }): SessionUser | null {
  if (!session?.user) return null;
  return session.user as SessionUser;
}

export function isSuperAdmin(user: SessionUser) {
  return user.role === "superadmin";
}

/**
 * Return the currently selected gym ID.
 * Validates that the selectedGymId is in the user's gymIds array.
 * Falls back to the first gym in gymIds if none selected.
 * Throws if the user has no gyms at all.
 */
export function requireGymId(user: SessionUser): string {
  // Superadmins must explicitly select a gym
  if (isSuperAdmin(user)) {
    if (user.selectedGymId) return user.selectedGymId;
    throw new Error("No gymId on session");
  }

  // If selectedGymId is set and valid, use it
  if (user.selectedGymId && user.gymIds.includes(user.selectedGymId)) {
    return user.selectedGymId;
  }

  // Fallback to first gym
  if (user.gymIds.length > 0) {
    return user.gymIds[0];
  }

  throw new Error("No gymId on session");
}
