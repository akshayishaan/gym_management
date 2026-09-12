import { Controller, Get, Query, Req, UseGuards } from "@nestjs/common";
import { JwtAuthGuard, RequireGymGuard } from "../auth";
import type { AuthenticatedRequest } from "../auth";
import { ActivityService } from "./activity.service";

@Controller("activity")
@UseGuards(JwtAuthGuard, RequireGymGuard)
export class ActivityController {
  constructor(private readonly activityService: ActivityService) {}

  @Get()
  list(
    @Req() req: AuthenticatedRequest,
    @Query("page") page?: string,
    @Query("limit") limit?: string,
  ) {
    return this.activityService.list(req.gymId!, page, limit);
  }
}
