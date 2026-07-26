import { NextResponse } from "next/server";
import { apiHandlerWithParams } from "@/lib/apiHandler";
import { getGymFilter } from "@/lib/withAuth";
import Plan from "@/models/Plan";
import ActivityLog from "@/models/ActivityLog";
import { planUpdateSchema } from "@/lib/validators/plan";
import { exactPlanNamePattern, normalizePlanFeatures } from "@/lib/planUtils";

export const PUT = apiHandlerWithParams<{ id: string }>(
  async (req, user, { id }) => {
    const gymFilter = getGymFilter(user);
    const gymId = gymFilter.gymId;
    const body = await req.json();
    const validated = planUpdateSchema.parse(body);

    if (validated.name) {
      const duplicate = await Plan.exists({
        ...gymFilter,
        _id: { $ne: id },
        name: exactPlanNamePattern(validated.name),
      });
      if (duplicate) {
        return NextResponse.json({ error: "A plan with this name already exists" }, { status: 409 });
      }
    }

    const update = {
      ...validated,
      ...(validated.features && { features: normalizePlanFeatures(validated.features) }),
    };

    const plan = await Plan.findOneAndUpdate({ _id: id, ...gymFilter }, update, { new: true });
    if (!plan) return NextResponse.json({ error: "Not found" }, { status: 404 });

    await ActivityLog.create({
      gymId,
      staffId: user.id,
      staffName: user.name || "Unknown",
      action: "updated",
      entity: "plan",
      entityId: id,
      details: validated.isActive === false
        ? `Deactivated plan: ${plan.name}`
        : validated.isActive === true
        ? `Activated plan: ${plan.name}`
        : `Updated plan: ${plan.name}`,
    });

    return NextResponse.json(plan);
  }
);

// Plans are never deleted — deactivate them via PUT { isActive: false } instead.
// Historical Payments / Memberships keep their plan snapshots, and inactive
// plans simply stop appearing in assignment dropdowns.
