import { Module } from "@nestjs/common";
import { AuthModule } from "../auth";
import { DatabaseModule } from "../database";
import { GymsController } from "./gym.controller";
import { GymsService } from "./gym.service";

/**
 * Gyms feature wiring. Imports `AuthModule` (for `JwtAuthGuard`) and
 * `DatabaseModule` (for `MongoConnectionService`, used by `GymsService` to
 * establish the connection before querying).
 */
@Module({
  imports: [AuthModule, DatabaseModule],
  controllers: [GymsController],
  providers: [GymsService],
})
export class GymsModule {}
