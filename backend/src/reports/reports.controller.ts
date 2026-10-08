import { Controller, Get, Query, Req, UseGuards } from "@nestjs/common";
import { JwtAuthGuard, RequireGymGuard } from "../auth";
import type { AuthenticatedRequest } from "../auth";
import { ReportsService } from "./reports.service";

@Controller("reports")
@UseGuards(JwtAuthGuard, RequireGymGuard)
export class ReportsController {
  constructor(private readonly reportsService: ReportsService) {}

  @Get()
  get(@Req() req: AuthenticatedRequest, @Query("year") year?: string) {
    return this.reportsService.getReport(req.gymId!, year);
  }
}
