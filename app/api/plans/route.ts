import { NextRequest, NextResponse } from "next/server";
import { apiHandler } from "@/lib/apiHandler";
import { getGymFilter } from "@/lib/withAuth";
import { SessionUser } from "@/lib/session";
import Plan from "@/models/Plan";
import ActivityLog from "@/models/ActivityLog";
import { planCreateSchema } from "@/lib/validators/plan";

export const GET = apiHandler(async (req: NextRequest, user: SessionUser) => {
  const { searchParams } = new URL(req.url);
  const page = parseInt(searchParams.get("page") || "1");
  const limit = parseInt(searchParams.get("limit") || "50");

  const query = { ...getGymFilter(user) };
  const total = await Plan.countDocuments(query);
  const plans = await Plan.find(query)
    .sort({ price: 1 })
    .skip((page - 1) * limit)
    .limit(limit)
    .lean();

  return NextResponse.json({ plans, total, page, limit });
});

export const POST = apiHandler(async (req: NextRequest, user: SessionUser) => {
  const gymId = user.selectedGymId!;
  const body = await req.json();
  const validated = planCreateSchema.parse(body);

  const plan = await Plan.create({ ...validated, gymId });

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
