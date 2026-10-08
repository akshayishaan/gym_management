import { Module } from "@nestjs/common";
import { AuthModule } from "../auth";
import { DatabaseModule } from "../database";
import { MembershipsController } from "./membership.controller";
import { MembershipsService } from "./membership.service";

/**
 * Memberships feature wiring. Imports `AuthModule` (for `JwtAuthGuard` and
 * `RequireGymGuard`) and `DatabaseModule` (for `MongoConnectionService`).
 */
@Module({
  imports: [AuthModule, DatabaseModule],
  controllers: [MembershipsController],
  providers: [MembershipsService],
})
export class MembershipsModule {}
