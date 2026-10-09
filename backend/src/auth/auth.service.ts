import { createHash, randomUUID } from "node:crypto";
import { Injectable } from "@nestjs/common";
import { JwtService } from "@nestjs/jwt";
import { Staff, type IStaff } from "../schemas";
import { MongoConfigService } from "../config";
import { MongoConnectionService } from "../database";
import { AuthError, DomainError } from "../common";
import {
  loginSchema,
  refreshSchema,
  signupSchema,
  type LoginInput,
  type RefreshInput,
  type SignupInput,
} from "./auth.schemas";

const ACCESS_TOKEN_TTL = "15m";
const REFRESH_TOKEN_TTL_DAYS = 30;
const REFRESH_TOKEN_TTL_MS = REFRESH_TOKEN_TTL_DAYS * 24 * 60 * 60 * 1000;

export interface AuthSession {
  accessToken: string;
  refreshToken: string;
  user: {
    id: string;
    name: string;
    email: string;
    role: string;
    gymIds: string[];
  };
}

/**
 * Issues and rotates JWT credentials. Replaces the Next.js NextAuth flow with
 * a plain short-lived access token + long-lived rotating refresh token. The
 * refresh token is stored only as a sha256 hash on the Staff document.
 *
 * One login is active per account: login/signup mint a new `sessionId`, and
 * both tokens carry it as `sid`. Signing in again replaces the stored value, so
 * every token from the previous login is rejected (access tokens by
 * JwtAuthGuard on the next request, refresh tokens here).
 */
@Injectable()
export class AuthService {
  constructor(
    private readonly jwtService: JwtService,
    private readonly config: MongoConfigService,
    private readonly connection: MongoConnectionService,
  ) {}

  async login(input: LoginInput): Promise<AuthSession> {
    await this.connection.getConnection();
    const parsed = loginSchema.parse(input);
    const staff = await Staff.findOne({
      email: parsed.email.toLowerCase(),
      isActive: true,
    });

    if (!staff || !(await staff.comparePassword(parsed.password))) {
      throw new AuthError("Invalid email or password");
    }

    staff.lastLogin = new Date();

    return this.issueTokens(staff, randomUUID());
  }

  async signup(input: SignupInput): Promise<AuthSession> {
    await this.connection.getConnection();
    const parsed = signupSchema.parse(input);
    const existing = await Staff.findOne({
      email: parsed.email.toLowerCase(),
    });

    if (existing) {
      throw new DomainError("An account with this email already exists", 409);
    }

    const staff = await Staff.create({
      name: parsed.name,
      email: parsed.email,
      password: parsed.password,
      role: "admin",
      gymIds: [],
      isActive: true,
    });

    // Issue tokens so signup logs the new operator straight in, matching the
    // login contract the client expects ({ accessToken, refreshToken, user }).
    return this.issueTokens(staff, randomUUID());
  }

  async refresh(input: RefreshInput): Promise<AuthSession> {
    await this.connection.getConnection();
    const parsed = refreshSchema.parse(input);

    let payload: { sub: string; sid?: string };
    try {
      payload = await this.jwtService.verifyAsync<{ sub: string; sid?: string }>(
        parsed.refreshToken,
        { secret: this.refreshSecret() },
      );
    } catch {
      throw new AuthError("Invalid refresh token");
    }

    const staff = await Staff.findById(payload.sub);
    if (!staff) {
      throw new AuthError("Invalid refresh token");
    }

    // A token without `sid` predates single-session enforcement; it is
    // rejected like one from a replaced login, so the client signs in again.
    if (!payload.sid || payload.sid !== staff.sessionId) {
      throw new AuthError("Invalid refresh token");
    }

    const rawHash = createHash("sha256")
      .update(parsed.refreshToken)
      .digest("hex");

    if (
      staff.refreshTokenHash !== rawHash ||
      !staff.refreshTokenExpiresAt ||
      staff.refreshTokenExpiresAt.getTime() < Date.now()
    ) {
      throw new AuthError("Invalid refresh token");
    }

    return this.issueTokens(staff, payload.sid, rawHash);
  }

  /**
   * Signs a token pair for `sessionId` and persists the refresh token hash.
   *
   * Without `rotateFrom` (login/signup) this starts a new session and
   * overwrites the previous one. With `rotateFrom` (refresh) it only swaps the
   * hash if the session and the presented token are still current, so a login
   * or another refresh that won a race is never overwritten.
   */
  private async issueTokens(
    staff: IStaff,
    sessionId: string,
    rotateFrom?: string,
  ): Promise<AuthSession> {
    const accessSecret = this.accessSecret();
    const refreshSecret = this.refreshSecret();

    const sub = staff._id.toString();
    const payload = { sub, role: staff.role, sid: sessionId };

    const accessToken = await this.jwtService.signAsync(payload, {
      secret: accessSecret,
      expiresIn: ACCESS_TOKEN_TTL,
    });

    // `jti` makes every refresh token unique even when two are signed in the
    // same second; otherwise rotation could yield an identical token and hash.
    const refreshToken = await this.jwtService.signAsync(
      { ...payload, jti: randomUUID() },
      {
        secret: refreshSecret,
        expiresIn: `${REFRESH_TOKEN_TTL_DAYS}d`,
      },
    );

    const refreshTokenHash = createHash("sha256")
      .update(refreshToken)
      .digest("hex");
    const refreshTokenExpiresAt = new Date(Date.now() + REFRESH_TOKEN_TTL_MS);

    if (rotateFrom) {
      const result = await Staff.updateOne(
        { _id: staff._id, sessionId, refreshTokenHash: rotateFrom },
        { $set: { refreshTokenHash, refreshTokenExpiresAt } },
      );
      if (result.matchedCount === 0) {
        throw new AuthError("Invalid refresh token");
      }
    } else {
      staff.sessionId = sessionId;
      staff.refreshTokenHash = refreshTokenHash;
      staff.refreshTokenExpiresAt = refreshTokenExpiresAt;
      await staff.save();
    }

    return {
      accessToken,
      refreshToken,
      user: {
        id: staff._id.toString(),
        name: staff.name,
        email: staff.email,
        role: staff.role,
        gymIds: staff.gymIds.filter(Boolean).map((g) => g.toString()),
      },
    };
  }

  private accessSecret(): string {
    const secret = this.config.jwtSecret;
    if (!secret) throw new Error("JWT_SECRET must be set");
    return secret;
  }

  private refreshSecret(): string {
    const secret = this.config.jwtRefreshSecret;
    if (!secret) throw new Error("JWT_REFRESH_SECRET must be set");
    return secret;
  }
}
