import { NextRequest, NextResponse } from "next/server";
import { apiHandler } from "@/lib/apiHandler";
import { getGymFilter } from "@/lib/withAuth";
import { SessionUser } from "@/lib/session";
import Plan, { IPlan } from "@/models/Plan";
import Gym from "@/models/Gym";
import ActivityLog from "@/models/ActivityLog";
import { planCreateSchema } from "@/lib/validators/plan";
import {
  exactPlanNamePattern,
  normalizePlanFeatures,
  partialPlanNamePattern,
} from "@/lib/planUtils";
import type { PlansResponse } from "@/lib/planTypes";
import { FilterQuery } from "mongoose";
import { getPlanPortfolioInsights } from "@/lib/gymInsights";

export const GET = apiHandler(async (req: NextRequest, user: SessionUser) => {
  const { searchParams } = new URL(req.url);
  const parsedPage = Number.parseInt(searchParams.get("page") || "1", 10);
  const parsedLimit = Number.parseInt(searchParams.get("limit") || "50", 10);
  const page = Number.isFinite(parsedPage) ? Math.max(1, parsedPage) : 1;
  const limit = Number.isFinite(parsedLimit)
    ? Math.min(100, Math.max(1, parsedLimit))
    : 50;
  const status = searchParams.get("status") || "all";
  const search = searchParams.get("search")?.trim() || "";
  const includeStats = searchParams.get("includeStats") !== "false";

  const scopedFilter = getGymFilter(user);
  const query: FilterQuery<IPlan> = { ...scopedFilter };
  if (status === "active") query.isActive = { $ne: false };
  if (status === "inactive") query.isActive = false;
  if (search) query.name = partialPlanNamePattern(search);

  const [total, plans] = await Promise.all([
    Plan.countDocuments(query),
    Plan.find(query)
      .sort({ isActive: -1, price: 1 })
      .skip((page - 1) * limit)
      .limit(limit)
      .lean(),
  ]);

  const serializedPlans = plans.map((plan) => ({
    ...plan,
    _id: plan._id.toString(),
  }));

  if (!includeStats) {
    const response: PlansResponse = { plans: serializedPlans, total, page, limit };
    return NextResponse.json(response);
  }

  const gym = await Gym.findById(scopedFilter.gymId).select("timezone").lean();
  if (!gym) return NextResponse.json({ error: "Gym not found" }, { status: 404 });
  const insights = await getPlanPortfolioInsights({
    gymId: String(scopedFilter.gymId),
    timeZone: gym.timezone || "Asia/Kolkata",
    asOf: new Date(),
  });
  const enrichedPlans = serializedPlans.map((plan) => ({
    ...plan,
    stats: insights.byPlan[plan._id] ?? {
      activeMembers: 0,
      salesYtd: 0,
      revenueAtSaleYtd: 0,
      totalMemberships: 0,
    },
  }));
  const summary = insights.summary;

  const response: PlansResponse = { plans: enrichedPlans, total, page, limit, summary };
  return NextResponse.json(response);
});

export const POST = apiHandler(async (req: NextRequest, user: SessionUser) => {
  const gymFilter = getGymFilter(user);
  const gymId = gymFilter.gymId;
  const body = await req.json();
  const validated = planCreateSchema.parse(body);

  const duplicate = await Plan.exists({
    ...gymFilter,
    name: exactPlanNamePattern(validated.name),
  });
  if (duplicate) {
    return NextResponse.json({ error: "A plan with this name already exists" }, { status: 409 });
  }

  const plan = await Plan.create({
    ...validated,
    features: normalizePlanFeatures(validated.features),
    gymId,
  });

  await ActivityLog.create({
    gymId,
    staffId: user.id,
    staffName: user.name || "Unknown",
    action: "created",
    entity: "plan",
    entityId: plan._id.toString(),
    details: `Created plan: ${plan.name}`,
  });

  return NextResponse.json(plan, { status: 201 });
});
