import { NextRequest, NextResponse } from "next/server";
import { apiHandlerWithParams } from "@/lib/apiHandler";
import { SessionUser } from "@/lib/session";
import Plan from "@/models/Plan";
import ActivityLog from "@/models/ActivityLog";
import { planUpdateSchema } from "@/lib/validators/plan";

export const PUT = apiHandlerWithParams<{ id: string }>(
  async (req, user, { id }) => {
    const gymId = user.selectedGymId!;
    const body = await req.json();
    const validated = planUpdateSchema.parse(body);

    const plan = await Plan.findOneAndUpdate({ _id: id, gymId }, validated, { new: true });
    if (!plan) return NextResponse.json({ error: "Not found" }, { status: 404 });

    await ActivityLog.create({
      gymId,
      staffId: user.id,
      staffName: user.name || "Unknown",
      action: "updated",
      entity: "plan",
      entityId: id,
      details: `Updated plan: ${plan.name}`,
    });

    return NextResponse.json(plan);
  }
);

export const DELETE = apiHandlerWithParams<{ id: string }>(
  async (_req, user, { id }) => {
    const gymId = user.selectedGymId!;
    const plan = await Plan.findOneAndDelete({ _id: id, gymId });
    if (!plan) return NextResponse.json({ error: "Not found" }, { status: 404 });

    await ActivityLog.create({
      gymId,
      staffId: user.id,
      staffName: user.name || "Unknown",
      action: "deleted",
      entity: "plan",
      entityId: id,
      details: `Deleted plan: ${plan.name}`,
    });

    return NextResponse.json({ success: true });
  }
);
