import mongoose from "mongoose";
import type { ConnectOptions } from "mongoose";

/**
 * A module-level cache that mirrors the Next.js `lib/mongodb.ts` global-cache
 * pattern. Holding `conn` and `promise` on `global` avoids opening a new
 * connection on every hot-reload / module re-import during development.
 */
interface MongooseCache {
  conn: typeof mongoose | null;
  promise: Promise<typeof mongoose> | null;
}

declare global {
  // eslint-disable-next-line no-var
  var mongoose: MongooseCache;
}

const cached: MongooseCache = global.mongoose || { conn: null, promise: null };

if (!global.mongoose) {
  global.mongoose = cached;
}

/**
 * Reuses the cached connection if present, otherwise connects once and caches
 * the in-flight promise so concurrent callers share a single connection.
 *
 * `getConfig` is a lazy thunk — it is only invoked when a new connection is
 * actually needed (cache-miss AND no in-flight promise), so the env is not
 * re-read/validated once a live connection is cached.
 */
export async function connectWithCache(
  getConfig: () => { uri: string; options: ConnectOptions },
): Promise<typeof mongoose> {
  if (cached.conn) return cached.conn;

  if (!cached.promise) {
    const { uri, options } = getConfig();
    cached.promise = mongoose.connect(uri, options).catch((error: unknown) => {
      // Reset so a failed attempt can be retried rather than caching a rejection.
      cached.promise = null;
      throw error;
    });
  }

  cached.conn = await cached.promise;
  return cached.conn;
}

/**
 * Closes and clears the cached connection (used on app shutdown).
 */
export async function disconnectDB(): Promise<void> {
  if (!cached.conn) return;

  const conn = cached.conn;
  cached.conn = null;
  cached.promise = null;
  await conn.disconnect();
}
