import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  Param,
  Post,
  Put,
  Query,
  Req,
  UseGuards,
} from "@nestjs/common";
import { JwtAuthGuard, RequireGymGuard } from "../auth";
import type { AuthenticatedRequest } from "../auth";
import { MembersService } from "./member.service";
import type { MemberCreateInput, MemberUpdateInput } from "./member.schemas";

/**
 * Member CRUD, tenant-scoped by `RequireGymGuard` (which resolves `req.gymId`).
 * Query-string paging parameters are passed through as raw strings; the service
 * coerces and clamps them (parity with the Next.js `Number.parseInt` handling).
 */
@Controller("members")
@UseGuards(JwtAuthGuard, RequireGymGuard)
export class MembersController {
  constructor(private readonly membersService: MembersService) {}

  @Get()
  list(
    @Req() req: AuthenticatedRequest,
    @Query() query: { search?: string; status?: string; page?: string; limit?: string },
  ) {
    return this.membersService.list(req.gymId!, query);
  }

  @Post()
  @HttpCode(201)
  create(@Body() body: MemberCreateInput, @Req() req: AuthenticatedRequest) {
    return this.membersService.create(req.user, req.gymId!, body);
  }

  @Get(":id")
  getOne(@Param("id") id: string, @Req() req: AuthenticatedRequest) {
    return this.membersService.getOne(req.gymId!, id);
  }

  @Put(":id")
  update(
    @Param("id") id: string,
    @Body() body: MemberUpdateInput,
    @Req() req: AuthenticatedRequest,
  ) {
    return this.membersService.update(req.gymId!, id, body, req.user);
  }

  @Delete(":id")
  softDelete(@Param("id") id: string, @Req() req: AuthenticatedRequest) {
    return this.membersService.softDelete(req.gymId!, id, req.user);
  }
}
