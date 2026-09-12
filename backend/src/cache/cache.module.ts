import { Global, Module } from "@nestjs/common";
import { CacheService } from "./cache.service";

/**
 * Global cache module. Provides a single `CacheService` that owns the
 * read-through Redis cache and the BullMQ invalidation pipeline. Global so any
 * feature service can inject it without an explicit per-module import.
 */
@Global()
@Module({
  providers: [CacheService],
  exports: [CacheService],
})
export class CacheModule {}
