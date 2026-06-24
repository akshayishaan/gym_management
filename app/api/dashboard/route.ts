import { NextRequest, NextResponse } from "next/server";
import { apiHandler } from "@/lib/apiHandler";
import { SessionUser } from "@/lib/session";
import Member from "@/models/Member";
import Payment from "@/models/Payment";

export const GET = apiHandler(async (_req: NextRequest, user: SessionUser) => {
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
