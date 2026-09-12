import { Module } from "@nestjs/common";
import { APP_FILTER } from "@nestjs/core";
import { AppConfigModule } from "./config";
import { CacheModule } from "./cache";
import { DatabaseModule } from "./database";
import { OpenApiModule } from "./openapi";
import { AuthModule } from "./auth";
import { GymsModule } from "./gyms";
import { MembersModule } from "./members";
import { PlansModule } from "./plans";
import { PaymentsModule } from "./payments";
import { MembershipsModule } from "./memberships";
import { DashboardModule } from "./dashboard";
import { ReportsModule } from "./reports";
import { ActivityModule } from "./activity";
import { HttpExceptionFilter } from "./common";
import { AppController } from "./app.controller";
import { AppService } from "./app.service";

@Module({
  imports: [
    AppConfigModule,
    CacheModule,
    DatabaseModule,
    OpenApiModule,
    AuthModule,
    GymsModule,
    MembersModule,
    PlansModule,
    PaymentsModule,
    MembershipsModule,
    DashboardModule,
    ReportsModule,
    ActivityModule,
  ],
  controllers: [AppController],
  providers: [
    AppService,
    {
      provide: APP_FILTER,
      useClass: HttpExceptionFilter,
    },
  ],
})
export class AppModule {}
