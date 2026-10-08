import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  Param,
  Post,
  Query,
  Req,
  UseGuards,
} from "@nestjs/common";
import { JwtAuthGuard, RequireGymGuard } from "../auth";
import type { AuthenticatedRequest } from "../auth";
import { PaymentsService } from "./payment.service";

/**
 * Payment listing and lifecycle actions, tenant-scoped by `RequireGymGuard`
 * (which resolves `req.gymId`). Payments are audit records — they are never
 * deleted; void/refund are explicit lifecycle operations and membership access
 * removal goes through `reversePlanPurchase` on the memberships module.
 */
@Controller("payments")
@UseGuards(JwtAuthGuard, RequireGymGuard)
export class PaymentsController {
  constructor(private readonly paymentsService: PaymentsService) {}

  @Get()
  list(
    @Req() req: AuthenticatedRequest,
    @Query() query: { memberId?: string; month?: string; status?: string; page?: string; limit?: string },
  ): Promise<Record<string, unknown>> {
    return this.paymentsService.list(req.gymId!, query);
  }

  @Post()
  @HttpCode(201)
  create(@Body() body: unknown, @Req() req: AuthenticatedRequest) {
    return this.paymentsService.create(req.user, req.gymId!, body);
  }

  @Get(":id")
  getOne(@Param("id") id: string, @Req() req: AuthenticatedRequest) {
    return this.paymentsService.getOne(req.gymId!, id);
  }

  @Delete(":id")
  remove() {
    return this.paymentsService.deleteOne();
  }

  @Post(":id/void")
  void(@Param("id") id: string, @Body() body: unknown, @Req() req: AuthenticatedRequest) {
    return this.paymentsService.void(req.gymId!, req.user, id, body);
  }

  @Post(":id/refund")
  refund(@Param("id") id: string, @Body() body: unknown, @Req() req: AuthenticatedRequest) {
    return this.paymentsService.refund(req.gymId!, req.user, id, body);
  }
}
