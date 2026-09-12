import { Module } from "@nestjs/common";
import { AuthModule } from "../auth";
import { DatabaseModule } from "../database";
import { MembersController } from "./member.controller";
import { MembersService } from "./member.service";

/**
 * Members feature wiring. Imports `AuthModule` (for `JwtAuthGuard` and
 * `RequireGymGuard`) and `DatabaseModule` (for `MongoConnectionService`).
 */
@Module({
  imports: [AuthModule, DatabaseModule],
  controllers: [MembersController],
  providers: [MembersService],
})
export class MembersModule {}
