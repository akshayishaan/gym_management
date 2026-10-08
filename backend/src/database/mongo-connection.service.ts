import { Injectable, OnModuleDestroy } from "@nestjs/common";
import mongoose from "mongoose";
import { MongoConfigService } from "../config";
import { connectWithCache, disconnectDB } from "./mongo-cache";

/**
 * Injectable facade over the cached Mongoose connection. Reads the connection
 * config from the env (via MongoConfigService) and delegates to the
 * module-level global cache so only one connection is ever opened.
 *
 * Connection is lazy: nothing connects at module import time, so `nest build`
 * and app boot succeed even when MongoDB is unreachable.
 */
@Injectable()
export class MongoConnectionService implements OnModuleDestroy {
  constructor(private readonly config: MongoConfigService) {}

  getConnection(): Promise<typeof mongoose> {
    return connectWithCache(() => this.config.getConnectionConfig());
  }

  async onModuleDestroy(): Promise<void> {
    await disconnectDB();
  }
}
