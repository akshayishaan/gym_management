import { NextRequest, NextResponse } from "next/server";
import { apiHandler } from "@/lib/apiHandler";
import { SessionUser, isSuperAdmin } from "@/lib/session";
import Gym from "@/models/Gym";

/**
 * POST /api/auth/select-gym
 * Sets the selectedGymId cookie after validating the user has access to that gym.
 */
export const POST = apiHandler(async (req: NextRequest, user: SessionUser) => {
  const body = await req.json();
  const { gymId } = body;

  if (!gymId) {
    return NextResponse.json({ error: "gymId is required" }, { status: 400 });
  }

  // Superadmins can select any active gym
  if (!isSuperAdmin(user)) {
    // Validate gymId is in user's gymIds
    if (!user.gymIds.includes(gymId)) {
      return NextResponse.json({ error: "Access denied to this gym" }, { status: 403 });
    }
  }

  // Verify gym exists and is active
  const gym = await Gym.findById(gymId).lean();
  if (!gym) {
    return NextResponse.json({ error: "Gym not found" }, { status: 404 });
  }
  if (!gym.isActive) {
    return NextResponse.json({ error: "Gym is deactivated" }, { status: 400 });
  }

  // Set the selectedGymId cookie
  const response = NextResponse.json({
    success: true,
    gym: {
      _id: gym._id,
      name: gym.name,
      logo: gym.logo,
      primaryColor: gym.primaryColor,
      currency: gym.currency,
    },
  });

  response.cookies.set("selectedGymId", gymId, {
    httpOnly: true,
    secure: process.env.NODE_ENV === "production",
    sameSite: "lax",
    path: "/",
    maxAge: 30 * 24 * 60 * 60, // 30 days
  });

  return response;
});
