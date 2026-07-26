import { NextRequest, NextResponse } from "next/server";
import { apiHandlerWithParams } from "@/lib/apiHandler";
import { ForbiddenError } from "@/lib/withAuth";
import { SessionUser } from "@/lib/session";
import Gym from "@/models/Gym";
import Staff from "@/models/Staff";
import Member from "@/models/Member";
import Payment from "@/models/Payment";
import Plan from "@/models/Plan";
import Membership from "@/models/Membership";
import ActivityLog from "@/models/ActivityLog";
import LifecycleMutation from "@/models/LifecycleMutation";
import { gymUpdateSchema } from "@/lib/validators/gym";

export const GET = apiHandlerWithParams<{ id: string }>(
  async (_req, user, { id }) => {
    if (!user.gymIds.includes(id)) throw new ForbiddenError("You can only view your own gyms");
    const gym = await Gym.findById(id).lean();
    if (!gym) return NextResponse.json({ error: "Not found" }, { status: 404 });
    return NextResponse.json(gym);
  }
);

export const PUT = apiHandlerWithParams<{ id: string }>(
  async (req, user, { id }) => {
    if (!user.gymIds.includes(id)) throw new ForbiddenError("You can only update your own gyms");
    const body = await req.json();
    const validated = gymUpdateSchema.parse(body);
    const gym = await Gym.findByIdAndUpdate(id, validated, { new: true });
    if (!gym) return NextResponse.json({ error: "Not found" }, { status: 404 });

    await ActivityLog.create({
      gymId: id,
      staffId: user.id,
      staffName: user.name || "Unknown",
      action: "updated",
      entity: "gym",
      entityId: id,
      details: `Updated gym: ${gym.name}`,
    });

    return NextResponse.json(gym);
  }
);

export const DELETE = apiHandlerWithParams<{ id: string }>(
  async (_req, user, { id }) => {
    if (!user.gymIds.includes(id)) throw new ForbiddenError("You can only delete your own gyms");
    const gym = await Gym.findById(id);
    if (!gym) return NextResponse.json({ error: "Not found" }, { status: 404 });

    await Staff.updateMany({ gymIds: id }, { $pull: { gymIds: id } });
    await Member.deleteMany({ gymId: id });
    await Payment.deleteMany({ gymId: id });
    await Plan.deleteMany({ gymId: id });
    await Membership.deleteMany({ gymId: id });
    await LifecycleMutation.deleteMany({ gymId: id });
    await ActivityLog.deleteMany({ gymId: id });
    await Gym.findByIdAndDelete(id);

    return NextResponse.json({ success: true });
  }
);
