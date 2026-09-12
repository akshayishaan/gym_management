import type { Request } from "express";
import type { Types } from "mongoose";

/**
 * The authenticated user object populated onto the request by `JwtAuthGuard`.
 * `gymIds` are hydrated from the Staff document on every request (never stored
 * in the JWT), mirroring the Next.js per-request `gymIds` hydration.
 */
export interface AuthenticatedUser {
  id: string;
  name: string;
  email: string;
  role: string;
  gymIds: string[];
}

/**
 * Express request extended with the auth context. `user` is set by
 * `JwtAuthGuard`; `gymId` is set by `RequireGymGuard` (which runs after).
 */
export interface AuthenticatedRequest extends Request {
  user: AuthenticatedUser;
  gymId?: Types.ObjectId;
}
