import { Injectable } from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import type { ConnectOptions } from "mongoose";

export interface MongoConnectionConfig {
  uri: string;
  options: ConnectOptions;
}

/**
 * Reads the external MongoDB connection settings from the environment,
 * mirroring the Next.js `lib/mongoConfig.ts` behavior exactly.
 *
 * Credentials may be embedded in MONGODB_URI or provided separately as a
 * MONGODB_USERNAME / MONGODB_PASSWORD pair (both-or-neither rule).
 *
 * This service also surfaces JWT_SECRET, JWT_REFRESH_SECRET, and REDIS_URL
 * for later issues (auth / cache), with no existence validation yet.
 */
@Injectable()
export class MongoConfigService {
  constructor(private readonly config: ConfigService) {}

  getConnectionConfig(): MongoConnectionConfig {
    const uri = this.config.get<string>("MONGODB_URI")?.trim();
    if (!uri) {
      throw new Error("MONGODB_URI must be set to an external MongoDB connection string");
    }

    const username = this.config.get<string>("MONGODB_USERNAME")?.trim();
    const password = this.config.get<string>("MONGODB_PASSWORD");
    if (Boolean(username) !== Boolean(password)) {
      throw new Error("MONGODB_USERNAME and MONGODB_PASSWORD must be provided together");
    }

    return {
      uri,
      options: {
        bufferCommands: false,
        // Avoid exhausting free-tier connection limits when instances scale out.
        maxPoolSize: 5,
        ...(username && password ? { user: username, pass: password } : {}),
      },
    };
  }

  get jwtSecret(): string | undefined {
    return this.config.get<string>("JWT_SECRET");
  }

  get jwtRefreshSecret(): string | undefined {
    return this.config.get<string>("JWT_REFRESH_SECRET");
  }

  get redisUrl(): string | undefined {
    return this.config.get<string>("REDIS_URL");
  }
}
