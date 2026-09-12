import { Controller, Get, Req, UseGuards } from "@nestjs/common";
import { JwtAuthGuard, RequireGymGuard } from "../auth";
import type { AuthenticatedRequest } from "../auth";
import { DashboardService } from "./dashboard.service";

@Controller("dashboard")
@UseGuards(JwtAuthGuard, RequireGymGuard)
export class DashboardController {
  constructor(private readonly dashboardService: DashboardService) {}

  @Get()
  get(@Req() req: AuthenticatedRequest) {
    return this.dashboardService.getDashboard(req.gymId!);
  }
}
