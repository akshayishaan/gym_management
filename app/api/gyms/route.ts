import { NextRequest, NextResponse } from "next/server";
import { apiHandler } from "@/lib/apiHandler";
import { SessionUser } from "@/lib/session";
import Gym from "@/models/Gym";
import Staff from "@/models/Staff";
import ActivityLog from "@/models/ActivityLog";
import { gymCreateSchema } from "@/lib/validators/gym";

export const GET = apiHandler(async (_req: NextRequest, user: SessionUser) => {
  const gyms = await Gym.find({ _id: { $in: user.gymIds } }).sort({ createdAt: -1 }).lean();
  return NextResponse.json(gyms);
});

export const POST = apiHandler(async (req: NextRequest, user: SessionUser) => {
  const body = await req.json();
  const validated = gymCreateSchema.parse(body);

  const gym = await Gym.create({ ...validated, ownerId: user.id });

  await Staff.findByIdAndUpdate(user.id, { $push: { gymIds: gym._id } });

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
