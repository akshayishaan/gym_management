import { NextRequest, NextResponse } from "next/server";
import { apiHandler } from "@/lib/apiHandler";
import { SessionUser } from "@/lib/session";
import Member from "@/models/Member";
import Payment from "@/models/Payment";
import Gym from "@/models/Gym";
import { getGymFilter } from "@/lib/withAuth";
import {
  addCalendarDays,
  localDateTimeToInstant,
  todayInTimeZone,
} from "@/lib/membershipCalendar";

export const GET = apiHandler(async (_req: NextRequest, user: SessionUser) => {
  const gymFilter = getGymFilter(user);
  const gymId = gymFilter.gymId;
  const gym = await Gym.findById(gymId).select("timezone").lean();
  const timeZone = gym?.timezone || "Asia/Kolkata";
  const now = new Date();
  const today = todayInTimeZone(timeZone, now);
  const weekLater = addCalendarDays(today, 7);
  const startOfMonth = localDateTimeToInstant(`${today.slice(0, 7)}-01`, timeZone);

  const [
    totalMembers,
    activeMembers,
    expiredMembers,
    expiringMembers,
    monthCollections,
    monthRefunds,
    recentPayments,
    expiringList,
  ] = await Promise.all([
    Member.countDocuments({ gymId, isActive: { $ne: false } }),
    Member.countDocuments({ gymId, isActive: { $ne: false }, membershipExpiry: { $gte: today } }),
    Member.countDocuments({ gymId, isActive: { $ne: false }, membershipExpiry: { $lt: today } }),
    Member.countDocuments({ gymId, isActive: { $ne: false }, membershipExpiry: { $gte: today, $lte: weekLater } }),
    Payment.aggregate([
      { $match: { gymId: { $eq: gymId }, paidAt: { $gte: startOfMonth }, status: { $in: ["paid", "refunded"] } } },
      { $group: { _id: null, total: { $sum: "$amount" } } },
    ]),
    Payment.aggregate([
      { $match: { gymId: { $eq: gymId }, refundedAt: { $gte: startOfMonth }, status: "refunded" } },
      { $group: { _id: null, total: { $sum: "$amount" } } },
    ]),
    Payment.find({ gymId, status: "paid" }).sort({ paidAt: -1 }).limit(5).lean(),
    Member.find({ gymId, isActive: { $ne: false }, membershipExpiry: { $gte: today, $lte: weekLater } })
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
    monthRevenue: (monthCollections[0]?.total || 0) - (monthRefunds[0]?.total || 0),
    recentPayments,
    expiringList,
  });
});
