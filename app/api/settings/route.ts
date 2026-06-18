import { NextRequest, NextResponse } from "next/server";
import { apiHandler } from "@/lib/apiHandler";
import { requireSuperAdminOrRole } from "@/lib/withAuth";
import { SessionUser, isSuperAdmin } from "@/lib/session";
import Gym from "@/models/Gym";
import { gymUpdateSchema } from "@/lib/validators/gym";

export const GET = apiHandler(async (req: NextRequest, user: SessionUser) => {
  if (isSuperAdmin(user)) return NextResponse.json({});

  const { searchParams } = new URL(req.url);
  const gymId = searchParams.get("gymId") || user.selectedGymId;
  if (!gymId) return NextResponse.json({});
  const gym = await Gym.findById(gymId).lean();
  return NextResponse.json(gym || {});
});

export const PUT = apiHandler(async (req: NextRequest, user: SessionUser) => {
  requireSuperAdminOrRole(user, "admin");

  const gymId = user.selectedGymId;
  if (!gymId) {
    return NextResponse.json({ error: "No gym selected" }, { status: 400 });
  }

  const body = await req.json();
  const validated = gymUpdateSchema.parse(body);

  const gym = await Gym.findByIdAndUpdate(gymId, validated, { new: true });
  return NextResponse.json(gym);
});
