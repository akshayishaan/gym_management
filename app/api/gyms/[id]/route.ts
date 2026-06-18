import { NextRequest, NextResponse } from "next/server";
import { apiHandlerWithParams } from "@/lib/apiHandler";
import { requireSuperAdmin, requireSuperAdminOrRole, ForbiddenError } from "@/lib/withAuth";
import { SessionUser, isSuperAdmin } from "@/lib/session";
import Gym from "@/models/Gym";
import Staff from "@/models/Staff";
import Member from "@/models/Member";
import Payment from "@/models/Payment";
import Plan from "@/models/Plan";
import ActivityLog from "@/models/ActivityLog";
import { gymUpdateSchema } from "@/lib/validators/gym";

export const GET = apiHandlerWithParams<{ id: string }>(
  async (_req, user, { id }) => {
    // Superadmin can view any gym; gym admin can view their own gyms
    if (!isSuperAdmin(user) && !user.gymIds.includes(id)) {
      throw new ForbiddenError("You can only view your own gyms");
    }

    const gym = await Gym.findById(id).lean();
    if (!gym) return NextResponse.json({ error: "Not found" }, { status: 404 });
    return NextResponse.json(gym);
  }
);

export const PUT = apiHandlerWithParams<{ id: string }>(
  async (req, user, { id }) => {
    // Superadmin or gym admin (their own gym)
    if (!isSuperAdmin(user) && !user.gymIds.includes(id)) {
      throw new ForbiddenError("You can only update your own gyms");
    }
    requireSuperAdminOrRole(user, "admin");

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
    requireSuperAdmin(user);

    // Soft-delete: deactivate gym and all its staff instead of hard-deleting
    // This preserves data integrity (members, payments, plans, activity logs)
    await Gym.findByIdAndUpdate(id, { isActive: false });
    await Staff.updateMany({ gymIds: id }, { isActive: false });

    await ActivityLog.create({
      staffId: user.id,
      staffName: user.name || "Superadmin",
      action: "deleted",
      entity: "gym",
      entityId: id,
      details: `Deactivated gym and its staff (soft delete)`,
    });

    return NextResponse.json({ success: true });
  }
);
