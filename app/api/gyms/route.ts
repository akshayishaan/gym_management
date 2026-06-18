import { NextRequest, NextResponse } from "next/server";
import { apiHandler } from "@/lib/apiHandler";
import { requireSuperAdminOrRole } from "@/lib/withAuth";
import { SessionUser, isSuperAdmin } from "@/lib/session";
import Gym from "@/models/Gym";
import Staff from "@/models/Staff";
import ActivityLog from "@/models/ActivityLog";
import { gymCreateSchema } from "@/lib/validators/gym";

export const GET = apiHandler(async (_req: NextRequest, user: SessionUser) => {
  if (isSuperAdmin(user)) {
    const gyms = await Gym.find({}).sort({ createdAt: -1 }).lean();
    return NextResponse.json(gyms);
  }

  // Admin sees only their gyms
  const gyms = await Gym.find({ _id: { $in: user.gymIds } }).sort({ createdAt: -1 }).lean();
  return NextResponse.json(gyms);
});

export const POST = apiHandler(async (req: NextRequest, user: SessionUser) => {
  requireSuperAdminOrRole(user, "admin");

  const body = await req.json();
  const validated = gymCreateSchema.parse(body);

  const gym = await Gym.create({
    ...validated,
    ownerId: user.id,
  });

  // Add gym to creator's gymIds
  await Staff.findByIdAndUpdate(user.id, {
    $push: { gymIds: gym._id },
  });

  await ActivityLog.create({
    gymId: gym._id,
    staffId: user.id,
    staffName: user.name || "Admin",
    action: "created",
    entity: "gym",
    entityId: gym._id.toString(),
    details: `Created gym: ${gym.name}`,
  });

  return NextResponse.json(gym, { status: 201 });
});
