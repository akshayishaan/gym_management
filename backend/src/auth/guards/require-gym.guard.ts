import {
  CanActivate,
  ExecutionContext,
  Injectable,
} from "@nestjs/common";
import type { Request } from "express";
import { Types } from "mongoose";
import { ForbiddenError } from "../../common";
import type { AuthenticatedRequest } from "../auth.types";

const SELECTED_GYM_HEADER = "x-selected-gym";

/**
 * Resolves the active gym for a request and enforces membership. Runs after
 * `JwtAuthGuard` (which populates `req.user`) and mirrors the Next.js
 * `getSelectedGymId` + `getGymFilter` + `requireGymId` semantics:
 *
 * - reads the `X-Selected-Gym` header (the migration replaces the
 *   `selectedGymId` cookie with this header);
 * - falls back to the user's first gym when the header is absent;
 * - rejects with 403 when the header names a gym the user is not a member of;
 * - rejects with 403 when the user has no gym at all.
 *
 * On success it attaches a validated `req.gymId` (`Types.ObjectId`) for use in
 * tenant-scoped queries.
 */
@Injectable()
export class RequireGymGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean {
    const request = context
      .switchToHttp()
      .getRequest<AuthenticatedRequest & Request>();

    if (!request.user) {
      throw new ForbiddenError("No gym selected");
    }

    const { gymIds } = request.user;
    const headerValue = request.headers[SELECTED_GYM_HEADER];

    let resolved: string | undefined;

    if (typeof headerValue === "string" && headerValue.length > 0) {
      if (!gymIds.includes(headerValue)) {
        throw new ForbiddenError("Access denied to this gym");
      }
      resolved = headerValue;
    } else {
      resolved = gymIds[0];
    }

    if (!resolved) {
      throw new ForbiddenError("No gym selected");
    }

    if (!Types.ObjectId.isValid(resolved)) {
      throw new ForbiddenError("Access denied to this gym");
    }

    request.gymId = new Types.ObjectId(resolved);
    return true;
  }
}
