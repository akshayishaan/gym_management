import { NextRequest } from "next/server";
import { SessionUser, isSuperAdmin } from "@/lib/session";
import { ForbiddenError } from "@/lib/withAuth";

/**
 * Read the selectedGymId from the request cookie and validate it
 * against the user's gymIds array.
 *
 * Returns the validated gymId, or falls back to the first gym in gymIds.
 * Returns undefined for superadmins with no gym selected.
 */
export function getSelectedGymId(req: NextRequest, user: SessionUser): string | undefined {
  const cookieGymId = req.cookies.get("selectedGymId")?.value;

  // Superadmins don't have a default gym
  if (isSuperAdmin(user)) {
    if (cookieGymId) return cookieGymId;
    return undefined;
  }

  // Validate cookie value is in user's gymIds
  if (cookieGymId && user.gymIds.includes(cookieGymId)) {
    return cookieGymId;
  }

  // Fallback to first gym
  if (user.gymIds.length > 0) {
    return user.gymIds[0];
  }

  return undefined;
}

/**
 * Require a selected gym ID. Throws ForbiddenError if none available.
 */
export function requireSelectedGymId(req: NextRequest, user: SessionUser): string {
  const gymId = getSelectedGymId(req, user);
  if (!gymId) {
    throw new ForbiddenError("No gym selected. Please select a gym to continue.");
  }
  return gymId;
}
