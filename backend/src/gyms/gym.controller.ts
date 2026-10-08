import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Post,
  Put,
  Req,
  UseGuards,
} from "@nestjs/common";
import { JwtAuthGuard } from "../auth";
import type { AuthenticatedRequest } from "../auth";
import { GymsService } from "./gym.service";
import type {
  GymCreateInput,
  GymDeleteInput,
  GymUpdateInput,
} from "./gym.schemas";

/**
 * Gym CRUD. Guarded by `JwtAuthGuard` only — not `RequireGymGuard` — so a
 * freshly-signed-up admin (empty `gymIds`) can create their first gym. The
 * selected-gym resolution is reserved for tenant-scoped resources in later
 * issues.
 */
@Controller("gyms")
@UseGuards(JwtAuthGuard)
export class GymsController {
  constructor(private readonly gymsService: GymsService) {}

  @Get()
  list(@Req() req: AuthenticatedRequest) {
    return this.gymsService.list(req.user.gymIds);
  }

  @Post()
  create(@Body() body: GymCreateInput, @Req() req: AuthenticatedRequest) {
    return this.gymsService.create(body, req.user);
  }

  @Get(":id")
  getOne(@Param("id") id: string, @Req() req: AuthenticatedRequest) {
    return this.gymsService.getOne(id, req.user.gymIds);
  }

  @Put(":id")
  update(
    @Param("id") id: string,
    @Body() body: GymUpdateInput,
    @Req() req: AuthenticatedRequest,
  ) {
    return this.gymsService.update(id, body, req.user, req.user.gymIds);
  }

  @Get(":id/deletion-summary")
  deletionSummary(@Param("id") id: string, @Req() req: AuthenticatedRequest) {
    return this.gymsService.deletionSummary(id, req.user);
  }

  @Delete(":id")
  remove(
    @Param("id") id: string,
    @Body() body: GymDeleteInput,
    @Req() req: AuthenticatedRequest,
  ) {
    return this.gymsService.remove(id, body, req.user);
  }
}
