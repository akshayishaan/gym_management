import { NextRequest, NextResponse } from "next/server";
import { apiHandler } from "@/lib/apiHandler";
import { SessionUser, isSuperAdmin } from "@/lib/session";
import Member from "@/models/Member";
import Payment from "@/models/Payment";
import Gym from "@/models/Gym";

export const GET = apiHandler(async (req: NextRequest, user: SessionUser) => {
  // Superadmin gets aggregate stats across all gyms
  if (isSuperAdmin(user)) {
    const { searchParams } = new URL(req.url);
    const gymId = searchParams.get("gymId");
    const gymFilter = gymId ? { gymId } : {};
    const [totalGyms, totalMembers, totalRevenue] = await Promise.all([
      Gym.countDocuments({ isActive: true }),
      Member.countDocuments(gymFilter),
      Payment.aggregate([
        { $match: { status: "paid", ...gymFilter } },
        { $group: { _id: null, total: { $sum: "$amount" } } },
      ]),
    ]);
    return NextResponse.json({ isSuperAdmin: true, totalGyms, totalMembers, totalRevenue: totalRevenue[0]?.total || 0 });
  }

  const gymId = user.selectedGymId!;
  const today = new Date();
  const weekLater = new Date();
  weekLater.setDate(weekLater.getDate() + 7);
  const startOfMonth = new Date(today.getFullYear(), today.getMonth(), 1);

  const [
    totalMembers,
    activeMembers,
    expiredMembers,
    expiringMembers,
    monthRevenue,
    recentPayments,
    expiringList,
  ] = await Promise.all([
    Member.countDocuments({ gymId }),
    Member.countDocuments({ gymId, membershipExpiry: { $gte: today } }),
    Member.countDocuments({ gymId, membershipExpiry: { $lt: today } }),
    Member.countDocuments({ gymId, membershipExpiry: { $gte: today, $lte: weekLater } }),
    Payment.aggregate([
      { $match: { gymId: { $eq: gymId }, paidAt: { $gte: startOfMonth }, status: "paid" } },
      { $group: { _id: null, total: { $sum: "$amount" } } },
    ]),
    Payment.find({ gymId, status: "paid" }).sort({ paidAt: -1 }).limit(5).lean(),
    Member.find({ gymId, membershipExpiry: { $gte: today, $lte: weekLater } })
      .sort({ membershipExpiry: 1 })
      .limit(10)
      .select("name phone membershipExpiry planName")
      .lean(),
  ]);

  return NextResponse.json({
    totalMembers,
    activeMembers,
    expiredMembers,
    expiringMembers,
    monthRevenue: monthRevenue[0]?.total || 0,
    recentPayments,
    expiringList,
  });
});
