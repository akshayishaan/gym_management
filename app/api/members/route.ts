import { NextRequest, NextResponse } from "next/server";
import { apiHandler } from "@/lib/apiHandler";
import { getGymFilter } from "@/lib/withAuth";
import { SessionUser } from "@/lib/session";
import Gym from "@/models/Gym";
import Member, { type IMember } from "@/models/Member";
import Payment from "@/models/Payment";
import { memberCreateSchema } from "@/lib/validators/member";
import { onboardMember } from "@/lib/membershipLifecycle";
import { partialPlanNamePattern } from "@/lib/planUtils";
import { todayInTimeZone } from "@/lib/membershipCalendar";
import type { FilterQuery } from "mongoose";

export const GET = apiHandler(async (req: NextRequest, user: SessionUser) => {
  const { searchParams } = new URL(req.url);
  const search = searchParams.get("search")?.trim() || "";
  const status = searchParams.get("status") || "";
  const parsedPage = Number.parseInt(searchParams.get("page") || "1", 10);
  const parsedLimit = Number.parseInt(searchParams.get("limit") || "20", 10);
  const page = Number.isFinite(parsedPage) ? Math.max(1, parsedPage) : 1;
  const limit = Number.isFinite(parsedLimit) ? Math.min(100, Math.max(1, parsedLimit)) : 20;
  const gymFilter = getGymFilter(user);
  const gym = await Gym.findById(gymFilter.gymId).select("timezone").lean();
  const today = todayInTimeZone(gym?.timezone || "Asia/Kolkata");
  const query: FilterQuery<IMember> = { ...gymFilter, isActive: { $ne: false } };

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
    const { addCalendarDays } = await import("@/lib/membershipCalendar");
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

  return NextResponse.json({ members, total, page, limit });
});

export const POST = apiHandler(async (req: NextRequest, user: SessionUser) => {
  const gymFilter = getGymFilter(user);
  const validated = memberCreateSchema.parse(await req.json());
  const {
    requestId,
    planId,
    membershipStart,
    amountPaid,
    paymentMethod,
    ...member
  } = validated;

  const result = await onboardMember({
    gymId: String(gymFilter.gymId),
    requestId,
    actor: { id: user.id, name: user.name },
    now: new Date(),
    member,
    planId,
    membershipStart,
    amountPaid,
    paymentMethod,
  });
  const [savedMember, payment] = await Promise.all([
    Member.findOne({ _id: result.memberId, ...gymFilter }).lean(),
    result.paymentId
      ? Payment.findOne({ _id: result.paymentId, ...gymFilter }).lean()
      : null,
  ]);

  return NextResponse.json(
    { member: savedMember, payment, membershipId: result.membershipId },
    { status: 201 }
  );
});
