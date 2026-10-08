import { Injectable } from "@nestjs/common";
import type { FilterQuery, Types } from "mongoose";
import { ActivityLog, Gym, Member, Payment, type IMember } from "../schemas";
import { DomainError } from "../common";
import { MongoConnectionService } from "../database";
import { CacheService } from "../cache";
import type { AuthenticatedUser } from "../auth";
import { onboardMember } from "../lib";
import {
  addCalendarDays,
  calendarDaysBetween,
  membershipStatus,
  partialPlanNamePattern,
  todayInTimeZone,
} from "../lib";
import { memberCreateSchema, memberUpdateSchema } from "./member.schemas";

interface ListParams {
  search?: string;
  status?: string;
  page?: string;
  limit?: string;
}

type MemberDisplayStatus = ReturnType<typeof membershipStatus>;

/**
 * Mirrors the web `MemberCard`: members without a `membershipExpiry` render no
 * status/days badge (`null`), so we leave the document untouched rather than
 * attaching empty fields.
 */
function withDisplayStatus<T extends { membershipExpiry?: string }>(
  member: T,
  today: string,
): T | (T & { status: MemberDisplayStatus; daysUntilExpiry: number }) {
  if (!member.membershipExpiry) return member;
  return {
    ...member,
    status: membershipStatus(member.membershipExpiry, today),
    daysUntilExpiry: calendarDaysBetween(today, member.membershipExpiry),
  };
}

/**
 * Member CRUD with 1:1 parity to the Next.js member routes. Every method
 * establishes the Mongo connection first (matching the gyms module pattern),
 * then runs tenant-scoped queries keyed on `gymId` (the `req.gymId` resolved
 * by `RequireGymGuard`).
 */
@Injectable()
export class MembersService {
  constructor(
    private readonly connection: MongoConnectionService,
    private readonly cache: CacheService,
  ) {}

  async list(gymId: Types.ObjectId, params: ListParams) {
    await this.connection.getConnection();

    const search = (params.search || "").trim();
    const status = params.status || "";
    const parsedPage = Number.parseInt(params.page || "1", 10);
    const parsedLimit = Number.parseInt(params.limit || "20", 10);
    const page = Number.isFinite(parsedPage) ? Math.max(1, parsedPage) : 1;
    const limit = Number.isFinite(parsedLimit) ? Math.min(100, Math.max(1, parsedLimit)) : 20;

    const gym = await Gym.findById(gymId).select("timezone").lean();
    const today = todayInTimeZone(gym?.timezone || "Asia/Kolkata");
    const query: FilterQuery<IMember> = { gymId, isActive: { $ne: false } };

    if (search) {
      const pattern = partialPlanNamePattern(search);
      query.$or = [{ name: pattern }, { phone: pattern }, { email: pattern }];
    }

    if (status === "active") {
      query.membershipExpiry = { $gte: today };
    } else if (status === "expired") {
      query.membershipExpiry = { $lt: today };
    } else if (status === "expiring" || status === "expiring30") {
      const days = status === "expiring" ? 7 : 30;
      query.membershipExpiry = { $gte: today, $lte: addCalendarDays(today, days) };
    } else if (status === "due") {
      query.dueAmount = { $gt: 0 };
    }

    const [total, members] = await Promise.all([
      Member.countDocuments(query),
      Member.find(query)
        .sort({ createdAt: -1 })
        .skip((page - 1) * limit)
        .limit(limit)
        .lean(),
    ]);

    return { members: members.map((m) => withDisplayStatus(m, today)), total, page, limit };
  }

  async create(user: AuthenticatedUser, gymId: Types.ObjectId, body: unknown) {
    await this.connection.getConnection();

    const validated = memberCreateSchema.parse(body);
    const {
      requestId,
      planId,
      membershipStart,
      amountPaid,
      paymentMethod,
      reference,
      ...member
    } = validated;

    const result = await onboardMember({
      gymId: String(gymId),
      requestId,
      actor: { id: user.id, name: user.name },
      now: new Date(),
      member,
      planId,
      membershipStart,
      amountPaid,
      paymentMethod,
      reference,
    });

    const [savedMember, payment] = await Promise.all([
      Member.findOne({ _id: result.memberId, gymId }).lean(),
      result.paymentId
        ? Payment.findOne({ _id: result.paymentId, gymId }).lean()
        : null,
    ]);

    this.cache.scheduleInvalidation(String(gymId));

    return { member: savedMember, payment, membershipId: result.membershipId };
  }

  async getOne(gymId: Types.ObjectId, id: string) {
    await this.connection.getConnection();

    const member = await Member.findOne({ _id: id, gymId }).lean();
    if (!member) throw new DomainError("Not found", 404);

    const gym = await Gym.findById(gymId).select("timezone").lean();
    const today = todayInTimeZone(gym?.timezone || "Asia/Kolkata");

    return withDisplayStatus(member, today);
  }

  async update(gymId: Types.ObjectId, id: string, body: unknown, user: AuthenticatedUser) {
    await this.connection.getConnection();

    const validated = memberUpdateSchema.parse(body);
    const member = await Member.findOneAndUpdate({ _id: id, gymId }, validated, {
      new: true,
    });
    if (!member) throw new DomainError("Not found", 404);

    await ActivityLog.create({
      gymId,
      staffId: user.id,
      staffName: user.name || "Unknown",
      action: "updated",
      entity: "member",
      entityId: id,
      details: `Updated member: ${member.name}`,
    });

    this.cache.scheduleInvalidation(String(gymId));

    return member;
  }

  async softDelete(gymId: Types.ObjectId, id: string, user: AuthenticatedUser) {
    await this.connection.getConnection();

    // Soft delete: members are never removed from the DB (preserves revenue /
    // payment history). Setting isActive=false hides them from lists. Restore
    // via PUT { isActive: true }.
    const member = await Member.findOneAndUpdate(
      { _id: id, gymId },
      { isActive: false },
      { new: true },
    );
    if (!member) throw new DomainError("Not found", 404);

    await ActivityLog.create({
      gymId,
      staffId: user.id,
      staffName: user.name || "Unknown",
      action: "deleted",
      entity: "member",
      entityId: id,
      details: `Deleted member: ${member.name}`,
    });

    this.cache.scheduleInvalidation(String(gymId));

    return { success: true };
  }
}
