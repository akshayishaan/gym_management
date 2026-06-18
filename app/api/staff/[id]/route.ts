import { NextRequest, NextResponse } from "next/server";
import { apiHandlerWithParams } from "@/lib/apiHandler";
import { requireRole, ForbiddenError } from "@/lib/withAuth";
import { SessionUser } from "@/lib/session";
import Staff from "@/models/Staff";
import ActivityLog from "@/models/ActivityLog";
import { staffUpdateSchema } from "@/lib/validators/staff";

export const PUT = apiHandlerWithParams<{ id: string }>(
  async (req, user, { id }) => {
    requireRole(user, "admin");

    const body = await req.json();
    const validated = staffUpdateSchema.parse(body);

    // If updating password, let mongoose pre-save hook hash it
    if (validated.password) {
      const staff = await Staff.findById(id);
      if (!staff) return NextResponse.json({ error: "Not found" }, { status: 404 });

      // Scope check: gym admin can only update staff in their gym
      if (user.selectedGymId && !staff.gymIds.map(String).includes(user.selectedGymId)) {
        throw new ForbiddenError("You can only update staff in your gym");
      }

      Object.assign(staff, validated);
      await staff.save();
      const { password: _, ...safeStaff } = staff.toObject();
      return NextResponse.json(safeStaff);
    }

    const { password: _, ...safeBody } = validated;
    const staff = await Staff.findByIdAndUpdate(id, safeBody, { new: true }).select("-password");
    if (!staff) return NextResponse.json({ error: "Not found" }, { status: 404 });

    await ActivityLog.create({
      gymId: user.selectedGymId,
      staffId: user.id,
      staffName: user.name || "Unknown",
      action: "updated",
      entity: "staff",
      entityId: id,
      details: `Updated staff: ${staff.name}`,
    });

    return NextResponse.json(staff);
  }
);

export const DELETE = apiHandlerWithParams<{ id: string }>(
  async (_req, user, { id }) => {
    requireRole(user, "admin");

    // Cannot delete self
    if (user.id === id) {
      return NextResponse.json({ error: "Cannot delete yourself" }, { status: 400 });
    }

    const staff = await Staff.findByIdAndDelete(id);
    if (!staff) return NextResponse.json({ error: "Not found" }, { status: 404 });

    return NextResponse.json({ success: true });
  }
);
