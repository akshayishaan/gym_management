import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";
import { connectDB } from "@/lib/mongodb";
import { SessionUser, getSessionUser } from "@/lib/session";
import Staff from "@/models/Staff";

export class AuthError extends Error {
  status = 401;
  constructor(message = "Unauthorized") {
    super(message);
    this.name = "AuthError";
  }
}

export class ForbiddenError extends Error {
  status = 403;
  constructor(message = "Forbidden") {
    super(message);
    this.name = "ForbiddenError";
  }
}

/**
 * Authenticate the request, connect to DB, and return the typed session user.
 * gymIds are hydrated fresh from the DB so gym membership changes take effect
 * immediately without requiring a new login.
 */
export async function requireAuth(): Promise<SessionUser> {
  const session = await getServerSession(authOptions);
  const user = getSessionUser(session!);
  if (!user) throw new AuthError();
  await connectDB();
  const staff = await Staff.findById(user.id).select("gymIds").lean();
  user.gymIds = (staff?.gymIds ?? []).map(
    (g: { toString: () => string }) => g.toString()
  );
  return user;
}

/**
 * Build the MongoDB gym-scoped filter for the current user.
 * Always scopes by the active gym (selectedGymId or first gym).
 * Throws ForbiddenError if the user has no gym or the cookie value is invalid.
 */
export function getGymFilter(user: SessionUser): Record<string, string> {
  const activeGymId = user.selectedGymId || user.gymIds[0];
  if (!activeGymId) throw new ForbiddenError("No gym selected");
  if (!user.gymIds.includes(activeGymId)) throw new ForbiddenError("Access denied to this gym");
  return { gymId: activeGymId };
}
