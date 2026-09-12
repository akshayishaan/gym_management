import { Body, Controller, Get, Param, Post, Query, Req, UseGuards } from "@nestjs/common";
import { JwtAuthGuard, RequireGymGuard } from "../auth";
import type { AuthenticatedRequest } from "../auth";
import { MembershipsService } from "./membership.service";

/**
 * Membership history and reversal, tenant-scoped by `RequireGymGuard`.
 * Membership records are immutable except for reversal, which must occur
 * newest-first (enforced by `reversePlanPurchase`).
 */
@Controller("memberships")
@UseGuards(JwtAuthGuard, RequireGymGuard)
export class MembershipsController {
  constructor(private readonly membershipsService: MembershipsService) {}

  @Get()
  list(
    @Req() req: AuthenticatedRequest,
    @Query("memberId") memberId?: string,
  ) {
    return this.membershipsService.list(req.gymId!, memberId);
  }

  @Post(":id/reverse")
  reverse(@Param("id") id: string, @Body() body: unknown, @Req() req: AuthenticatedRequest) {
    return this.membershipsService.reverse(req.gymId!, req.user, id, body);
  }
}
