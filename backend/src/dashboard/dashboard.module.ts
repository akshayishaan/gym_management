import { Module } from "@nestjs/common";
import { AuthModule } from "../auth";
import { DatabaseModule } from "../database";
import { DashboardController } from "./dashboard.controller";
import { DashboardService } from "./dashboard.service";

@Module({
  imports: [AuthModule, DatabaseModule],
  controllers: [DashboardController],
  providers: [DashboardService],
})
export class DashboardModule {}
