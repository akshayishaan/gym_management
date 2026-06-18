import { NextRequest, NextResponse } from "next/server";
import { apiHandler } from "@/lib/apiHandler";
import { requireRole, requireSuperAdmin, getGymFilter, ForbiddenError } from "@/lib/withAuth";
import { SessionUser, isSuperAdmin } from "@/lib/session";
import Staff from "@/models/Staff";
import ActivityLog from "@/models/ActivityLog";
import { staffCreateSchema } from "@/lib/validators/staff";

export const GET = apiHandler(async (req: NextRequest, user: SessionUser) => {
  // Superadmin can list staff of a specific gym; gym admin lists their own gym
  if (!isSuperAdmin(user) && user.role !== "admin") {
    throw new ForbiddenError("Only admins and superadmins can list staff");
  }

  const { searchParams } = new URL(req.url);
  const page = parseInt(searchParams.get("page") || "1");
  const limit = parseInt(searchParams.get("limit") || "50");
  const gymIdParam = searchParams.get("gymId");

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const query: any = {};

  if (isSuperAdmin(user)) {
    // Superadmin: filter by gymId param if provided
    if (gymIdParam) {
      query.gymIds = gymIdParam;
    } else {
      // Don't list superadmins when no gym filter
      query.role = { $ne: "superadmin" };
    }
  } else {
    // Gym admin: only staff in their selected gym
    const gymId = user.selectedGymId!;
    query.gymIds = gymId;
  }

  const total = await Staff.countDocuments(query);
  const staff = await Staff.find(query)
    .select("-password")
    .sort({ createdAt: -1 })
    .skip((page - 1) * limit)
    .limit(limit)
    .lean();

  return NextResponse.json({ staff, total, page, limit });
});

export const POST = apiHandler(async (req: NextRequest, user: SessionUser) => {
  const body = await req.json();
  const validated = staffCreateSchema.parse(body);

  // Superadmin can create gym admins; gym admin can create receptionists/trainers in their gym
  if (isSuperAdmin(user)) {
    // Superadmin must provide gymIds in body
    if (!validated.gymIds || validated.gymIds.length === 0) {
      return NextResponse.json({ error: "gymIds required" }, { status: 400 });
    }
  } else {
    if (user.role !== "admin") throw new ForbiddenError("Only admins can create staff");
    // Gym admin cannot create another admin or superadmin
    if (validated.role === "admin" || validated.role === "superadmin") {
      throw new ForbiddenError("Cannot create admin from gym panel");
    }
    // Assign to the currently selected gym
    validated.gymIds = [user.selectedGymId!];
  }

  const staff = await Staff.create(validated);

  await ActivityLog.create({
    gymId: validated.gymIds[0],
    staffId: user.id,
    staffName: user.name || "Unknown",
    action: "created",
    entity: "staff",
    entityId: staff._id.toString(),
    details: `Created staff: ${staff.name} (${staff.role})`,
  });

  const { password: _, ...safeStaff } = staff.toObject();
  return NextResponse.json(safeStaff, { status: 201 });
});
