import { Injectable, OnModuleDestroy } from "@nestjs/common";
import { Queue, Worker } from "bullmq";
import Redis from "ioredis";
import { MongoConfigService } from "../config";

/**
 * Canonical cache-key scheme.
 *
 * Every cache key is namespaced under a single leading `cache:` prefix so a
 * single `SCAN`/`MATCH` pass can clear every entry belonging to one gym:
 *
 *   cache:dashboard:{gymId}         → dashboard summary
 *   cache:dashboard-previous:{gymId}:{date} → last-month comparison figures
 *   cache:plans:{gymId}             → plan portfolio insights (gym-scoped)
 *   cache:reports:{gymId}:{year}    → annual report
 *
 * Invalidating a gym runs `MATCH cache:*:{gymId}*`, which clears all three
 * families (dashboard/plans match the trailing `{gymId}` exactly; reports adds
 * the `:{year}` suffix, captured by the trailing `*`). `gymId` is a 24-hex
 * ObjectId string, so the glob cannot over-match another gym's keys.
 *
 * TTLs are intentionally short: this cache only shields expensive read
 * aggregations from bursts of repeat traffic. All cache layers degrade
 * gracefully — with no REDIS_URL the whole service is a no-op passthrough.
 */
export const CACHE_TTL_SECONDS = {
  dashboard: 30,
  dashboardPrevious: 3600,
  plans: 30,
  reports: 60,
} as const;

const INVALIDATION_QUEUE_NAME = "cache-invalidation";
const INVALIDATION_JOB_NAME = "invalidate-gym";
const SCAN_COUNT = 100;

/**
 * A single injectable that owns both the read-through cache and the
 * async (BullMQ) invalidation pipeline.
 *
 * Degradation contract: when `REDIS_URL` is unset the `client`, `queue`, and
 * `worker` are all left null and every method no-ops (reads fall straight
 * through to the loader; invalidations are dropped). When Redis is configured
 * but unreachable, cache errors are swallowed so requests still succeed.
 */
@Injectable()
export class CacheService implements OnModuleDestroy {
  private readonly client: Redis | null;
  private readonly queue: Queue<{ gymId: string }> | null;
  private readonly worker: Worker<{ gymId: string }> | null;

  constructor(config: MongoConfigService) {
    const redisUrl = config.redisUrl;

    if (redisUrl) {
      this.client = new Redis(redisUrl, {
        maxRetriesPerRequest: 1,
        retryStrategy: () => null, // never reconnect — keeps dev/harness safe
      });
      this.client.on("error", (error: Error) => {
        console.error("[cache] redis client error", error.message);
      });

      this.queue = new Queue<{ gymId: string }>(INVALIDATION_QUEUE_NAME, {
        connection: { url: redisUrl, maxRetriesPerRequest: 1 },
        defaultJobOptions: {
          attempts: 3,
          backoff: { type: "exponential", delay: 1000 },
          removeOnComplete: true,
          removeOnFail: false,
        },
      });

      this.worker = new Worker<{ gymId: string }>(
        INVALIDATION_QUEUE_NAME,
        async (job) => {
          await this.invalidateGym(job.data.gymId);
        },
        { connection: { url: redisUrl, maxRetriesPerRequest: null } },
      );
      this.worker.on("failed", (job, error: Error) => {
        console.error(`[cache] invalidation job failed for ${job?.data.gymId ?? "unknown"}`, error.message);
      });
      this.worker.on("error", (error: Error) => {
        console.error("[cache] invalidation worker error", error.message);
      });
    } else {
      this.client = null;
      this.queue = null;
      this.worker = null;
    }
  }

  /**
   * Read-through get: returns the cached value if present and parseable,
   * otherwise runs the loader, best-effort caches the result, and returns it.
   * Never throws — every cache-path failure falls through to a fresh value.
   */
  async getOrCompute<T>(key: string, ttlSeconds: number, loader: () => Promise<T>): Promise<T> {
    const client = this.client;
    if (!client) return loader();

    try {
      const cached = await client.get(key);
      if (cached !== null) {
        return JSON.parse(cached) as T;
      }
    } catch {
      // fall through to the loader on any get/parse error
    }

    const value = await loader();

    try {
      await client.set(key, JSON.stringify(value), "EX", ttlSeconds);
    } catch {
      // a lost write is acceptable — the next read simply recomputes
    }

    return value;
  }

  /**
   * Deletes every cache key for a gym via SCAN+MATCH and unlink. No-ops when
   * Redis is unavailable; errors are swallowed (a stale cache entry is cheaper
   * than a thrown invalidation).
   */
  async invalidateGym(gymId: string): Promise<void> {
    const client = this.client;
    if (!client) return;

    const pattern = `cache:*:${gymId}*`;
    try {
      let cursor = "0";
      do {
        const [nextCursor, keys] = await client.scan(
          cursor,
          "MATCH",
          pattern,
          "COUNT",
          SCAN_COUNT,
        );
        cursor = nextCursor;
        if (keys.length > 0) {
          await client.unlink(...keys);
        }
      } while (cursor !== "0");
    } catch (error) {
      console.error(`[cache] failed to invalidate gym ${gymId}`, (error as Error).message);
    }
  }

  /**
   * Fire-and-forget enqueue of an async invalidation. Call AFTER a lifecycle
   * mutation has resolved so the job runs post-commit (ADR-0004: cache-only).
   * Never throws to the caller.
   */
  scheduleInvalidation(gymId: string): void {
    const queue = this.queue;
    if (!queue) return;

    queue.add(INVALIDATION_JOB_NAME, { gymId }).catch((error: Error) => {
      console.error(`[cache] failed to enqueue invalidation for gym ${gymId}`, error.message);
    });
  }

  async onModuleDestroy(): Promise<void> {
    await this.worker?.close();
    await this.queue?.close();
    await this.client?.quit();
  }
}
