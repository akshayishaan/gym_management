import { Body, Controller, Get, Param, Post, Put, Query, Req, UseGuards } from "@nestjs/common";
import { JwtAuthGuard, RequireGymGuard } from "../auth";
import type { AuthenticatedRequest } from "../auth";
import { PlansService } from "./plan.service";

/**
 * Plan CRUD, tenant-scoped by `RequireGymGuard` (which resolves `req.gymId`).
 * Plans are never deleted — deactivate them via `PUT { isActive: false }`.
 * Query-string paging parameters are passed through as raw strings; the service
 * coerces and clamps them (parity with the Next.js `Number.parseInt` handling).
 */
@Controller("plans")
@UseGuards(JwtAuthGuard, RequireGymGuard)
export class PlansController {
  constructor(private readonly plansService: PlansService) {}

  @Get()
  list(
    @Req() req: AuthenticatedRequest,
    @Query() query: { search?: string; status?: string; page?: string; limit?: string; includeStats?: string },
  ) {
    return this.plansService.list(req.gymId!, query);
  }

  @Post()
  create(@Body() body: unknown, @Req() req: AuthenticatedRequest) {
    return this.plansService.create(req.user, req.gymId!, body);
  }

  @Put(":id")
  update(@Param("id") id: string, @Body() body: unknown, @Req() req: AuthenticatedRequest) {
    return this.plansService.update(req.user, req.gymId!, id, body);
  }
}
