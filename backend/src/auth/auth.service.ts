import { createHash } from "node:crypto";
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

    return this.issueTokens(staff);
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
    return this.issueTokens(staff);
  }

  async refresh(input: RefreshInput): Promise<AuthSession> {
    await this.connection.getConnection();
    const parsed = refreshSchema.parse(input);

    let payload: { sub: string };
    try {
      payload = await this.jwtService.verifyAsync<{ sub: string }>(
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

    return this.issueTokens(staff);
  }

  private async issueTokens(staff: IStaff): Promise<AuthSession> {
    const accessSecret = this.accessSecret();
    const refreshSecret = this.refreshSecret();

    const sub = staff._id.toString();
    const payload = { sub, role: staff.role };

    const accessToken = await this.jwtService.signAsync(payload, {
      secret: accessSecret,
      expiresIn: ACCESS_TOKEN_TTL,
    });

    const refreshToken = await this.jwtService.signAsync(payload, {
      secret: refreshSecret,
      expiresIn: `${REFRESH_TOKEN_TTL_DAYS}d`,
    });

    staff.refreshTokenHash = createHash("sha256")
      .update(refreshToken)
      .digest("hex");
    staff.refreshTokenExpiresAt = new Date(Date.now() + REFRESH_TOKEN_TTL_MS);
    await staff.save();

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
