import { Module } from "@nestjs/common";
import { AuthModule } from "../auth";
import { DatabaseModule } from "../database";
import { PlansController } from "./plan.controller";
import { PlansService } from "./plan.service";

/**
 * Plans feature wiring. Imports `AuthModule` (for `JwtAuthGuard` and
 * `RequireGymGuard`) and `DatabaseModule` (for `MongoConnectionService`).
 */
@Module({
  imports: [AuthModule, DatabaseModule],
  controllers: [PlansController],
  providers: [PlansService],
})
export class PlansModule {}
