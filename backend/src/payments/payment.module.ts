import { Module } from "@nestjs/common";
import { AuthModule } from "../auth";
import { DatabaseModule } from "../database";
import { PaymentsController } from "./payment.controller";
import { PaymentsService } from "./payment.service";

/**
 * Payments feature wiring. Imports `AuthModule` (for `JwtAuthGuard` and
 * `RequireGymGuard`) and `DatabaseModule` (for `MongoConnectionService`).
 */
@Module({
  imports: [AuthModule, DatabaseModule],
  controllers: [PaymentsController],
  providers: [PaymentsService],
})
export class PaymentsModule {}
