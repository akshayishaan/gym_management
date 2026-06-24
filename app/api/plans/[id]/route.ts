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

// Plans are never deleted — deactivate them via PUT { isActive: false } instead.
// Historical Payments / Memberships keep their plan snapshots, and inactive
// plans simply stop appearing in assignment dropdowns.
