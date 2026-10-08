import { Controller, Get, Query, Req, UseGuards } from "@nestjs/common";
import { JwtAuthGuard, RequireGymGuard } from "../auth";
import type { AuthenticatedRequest } from "../auth";
import {
  ActivityService,
  type ActivityListQuery,
  type ActivityListResult,
} from "./activity.service";

@Controller("activity")
@UseGuards(JwtAuthGuard, RequireGymGuard)
export class ActivityController {
  constructor(private readonly activityService: ActivityService) {}

  @Get()
  list(
    @Req() req: AuthenticatedRequest,
    @Query("page") page?: string,
    @Query("limit") limit?: string,
    @Query("range") range?: string,
    @Query("from") from?: string,
    @Query("to") to?: string,
    @Query("actions") actions?: string,
  ): Promise<ActivityListResult> {
    const filters: ActivityListQuery = { range, from, to, actions };
    return this.activityService.list(req.gymId!, page, limit, filters);
  }
}
