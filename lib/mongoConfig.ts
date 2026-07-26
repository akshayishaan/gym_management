import type { ConnectOptions } from "mongoose";

export interface MongoConnectionConfig {
  uri: string;
  options: ConnectOptions;
}

/**
 * Read the external MongoDB connection settings from the environment.
 * Credentials may be embedded in MONGODB_URI or provided separately.
 */
export function getMongoConnectionConfig(): MongoConnectionConfig {
  const uri = process.env.MONGODB_URI?.trim();
  if (!uri) {
    throw new Error("MONGODB_URI must be set to an external MongoDB connection string");
  }

  const username = process.env.MONGODB_USERNAME?.trim();
  const password = process.env.MONGODB_PASSWORD;
  if (Boolean(username) !== Boolean(password)) {
    throw new Error("MONGODB_USERNAME and MONGODB_PASSWORD must be provided together");
  }

  return {
    uri,
    options: {
      bufferCommands: false,
      // Keep each Vercel function instance from exhausting free-tier
      // connection limits when several instances scale out concurrently.
      maxPoolSize: 5,
      ...(username && password ? { user: username, pass: password } : {}),
    },
  };
}
