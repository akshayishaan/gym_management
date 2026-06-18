import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";
import { connectDB } from "@/lib/mongodb";
import { SessionUser } from "@/lib/session";
import { getSessionUser, isSuperAdmin } from "@/lib/session";

/**
 * Custom error classes for auth flow — caught by apiHandler.
 */
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
 * Throws AuthError if no session.
 */
export async function requireAuth(): Promise<SessionUser> {
  const session = await getServerSession(authOptions);
  const user = getSessionUser(session!);
  if (!user) throw new AuthError();
  await connectDB();
  return user;
}

/**
 * Require that the authenticated user has one of the specified roles.
 * Throws ForbiddenError if the user's role is not in the allowed list.
 */
export async function requireRole(
  user: SessionUser,
  ...roles: SessionUser["role"][]
): Promise<void> {
  if (!roles.includes(user.role)) {
    throw new ForbiddenError(
      `Role '${user.role}' is not allowed. Required: ${roles.join(", ")}`
    );
  }
}

/**
 * Require that the user is NOT a superadmin (superadmins are read-only on gym data).
 * Throws ForbiddenError if the user is a superadmin.
 */
export function requireNotSuperAdmin(user: SessionUser): void {
  if (isSuperAdmin(user)) {
    throw new ForbiddenError("Superadmins cannot modify gym-specific data");
  }
}

/**
 * Require that the user is a superadmin.
 * Throws ForbiddenError if the user is not a superadmin.
 */
export function requireSuperAdmin(user: SessionUser): void {
  if (!isSuperAdmin(user)) {
    throw new ForbiddenError("Superadmin access required");
  }
}

/**
 * Require that the user is either a superadmin or has the specified role.
 * This is the correct RBAC check that replaces the buggy `isSuperAdmin(user) || user.role !== "admin"` pattern.
 */
export function requireSuperAdminOrRole(
  user: SessionUser,
  ...roles: SessionUser["role"][]
): void {
  if (isSuperAdmin(user)) return;
  if (roles.includes(user.role)) return;
  throw new ForbiddenError(
    `Access denied. Required: superadmin or ${roles.join(", ")}`
  );
}

/**
 * Get the gym-scoped filter for the current user.
 * Uses user.selectedGymId (injected by apiHandler from cookie).
 * Superadmins can optionally pass a gymId query param.
 * Gym staff always get their selectedGymId.
 */
export function getGymFilter(
  user: SessionUser,
  gymIdParam?: string | null
): Record<string, string> {
  if (isSuperAdmin(user)) {
    return gymIdParam ? { gymId: gymIdParam } : {};
  }
  const activeGymId = user.selectedGymId || user.gymIds[0];
  if (!activeGymId) {
    throw new ForbiddenError("No gym selected");
  }
  // Security: validate selectedGymId is in user's gymIds
  if (!user.gymIds.includes(activeGymId)) {
    throw new ForbiddenError("Access denied to this gym");
  }
  return { gymId: activeGymId };
}
