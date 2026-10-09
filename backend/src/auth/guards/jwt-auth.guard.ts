import {
  CanActivate,
  ExecutionContext,
  Injectable,
} from "@nestjs/common";
import { JwtService } from "@nestjs/jwt";
import type { Request } from "express";
import { Staff, type IStaff } from "../../schemas";
import { MongoConnectionService } from "../../database";
import { MongoConfigService } from "../../config";
import { AuthError } from "../../common";
import type { AuthenticatedRequest, AuthenticatedUser } from "../auth.types";

interface AccessTokenPayload {
  sub: string;
  sid?: string;
}

/**
 * Authenticates a request from its `Authorization: Bearer <token>` header.
 * Verifies the access token, loads the Staff document, rejects inactive users,
 * and hydrates `req.user` (including per-request `gymIds`) for downstream use —
 * notably `RequireGymGuard`.
 *
 * The token's `sid` must equal the Staff's current `sessionId`. Signing in
 * again replaces that value, so a replaced login's access token is rejected on
 * its next request instead of staying valid until it expires.
 */
@Injectable()
export class JwtAuthGuard implements CanActivate {
  constructor(
    private readonly jwtService: JwtService,
    private readonly config: MongoConfigService,
    private readonly connection: MongoConnectionService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context
      .switchToHttp()
      .getRequest<AuthenticatedRequest & Request>();

    const token = this.extractToken(request);
    if (!token) {
      throw new AuthError();
    }

    let payload: AccessTokenPayload;
    try {
      payload = await this.jwtService.verifyAsync<AccessTokenPayload>(token, {
        secret: this.accessSecret(),
      });
    } catch {
      throw new AuthError();
    }

    await this.connection.getConnection();
    const staff = await Staff.findById(payload.sub);

    if (!staff || staff.isActive !== true) {
      throw new AuthError();
    }

    // Tokens without `sid` predate single-session enforcement and are rejected
    // too, so every client signs in once more after deploy.
    if (!payload.sid || payload.sid !== staff.sessionId) {
      throw new AuthError();
    }

    request.user = this.hydrateUser(staff);
    return true;
  }

  private extractToken(request: Request): string | null {
    const header = request.headers.authorization;
    if (!header) return null;

    const [scheme, token] = header.split(" ");
    if (scheme !== "Bearer" || !token) return null;

    return token;
  }

  private hydrateUser(staff: IStaff): AuthenticatedUser {
    return {
      id: staff._id.toString(),
      name: staff.name,
      email: staff.email,
      role: staff.role,
      gymIds: staff.gymIds.filter(Boolean).map((g) => g.toString()),
    };
  }

  private accessSecret(): string {
    const secret = this.config.jwtSecret;
    if (!secret) throw new Error("JWT_SECRET must be set");
    return secret;
  }
}
