import { NextRequest } from "next/server";
import { SessionUser } from "@/lib/session";
import { ForbiddenError } from "@/lib/withAuth";

/**
 * Read the selectedGymId from the request cookie and validate it
 * against the user's gymIds array. Falls back to the first gym.
 */
export function getSelectedGymId(req: NextRequest, user: SessionUser): string | undefined {
  const cookieGymId = req.cookies.get("selectedGymId")?.value;

  if (cookieGymId && user.gymIds.includes(cookieGymId)) {
    return cookieGymId;
  }

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
