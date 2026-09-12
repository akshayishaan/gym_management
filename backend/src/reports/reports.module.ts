import { Module } from "@nestjs/common";
import { AuthModule } from "../auth";
import { DatabaseModule } from "../database";
import { ReportsController } from "./reports.controller";
import { ReportsService } from "./reports.service";

@Module({
  imports: [AuthModule, DatabaseModule],
  controllers: [ReportsController],
  providers: [ReportsService],
})
export class ReportsModule {}
