import { Module } from "@nestjs/common";
import { JwtModule } from "@nestjs/jwt";
import { DatabaseModule } from "../database";
import { AuthController } from "./auth.controller";
import { AuthService } from "./auth.service";
import { JwtAuthGuard, RequireGymGuard } from "./guards";

/**
 * Auth wiring. `JwtModule` is registered bare (no global secret): every
 * sign/verify call passes an explicit `{ secret }` options object so the
 * access and refresh tokens use distinct, purpose-specific secrets resolved
 * from `MongoConfigService` at signing time. The guards are provided and
 * exported here (along with `JwtService`) so feature modules can import
 * `AuthModule` and use them via `@UseGuards`.
 */
@Module({
  imports: [DatabaseModule, JwtModule.register({})],
  controllers: [AuthController],
  providers: [AuthService, JwtAuthGuard, RequireGymGuard],
  exports: [JwtModule, JwtAuthGuard, RequireGymGuard],
})
export class AuthModule {}
