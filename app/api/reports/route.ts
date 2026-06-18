import { NextRequest, NextResponse } from "next/server";
import { apiHandler } from "@/lib/apiHandler";
import { getGymFilter } from "@/lib/withAuth";
import { SessionUser } from "@/lib/session";
import Payment from "@/models/Payment";
import Member from "@/models/Member";

export const GET = apiHandler(async (req: NextRequest, user: SessionUser) => {
  const { searchParams } = new URL(req.url);
  const year = parseInt(searchParams.get("year") || String(new Date().getFullYear()));
  const gymIdParam = searchParams.get("gymId");

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const gymFilter: any = getGymFilter(user, gymIdParam);

  // Monthly revenue for the year
  const monthlyRevenue = await Payment.aggregate([
    {
      $match: {
        ...gymFilter,
        status: "paid",
        paidAt: {
          $gte: new Date(year, 0, 1),
          $lt: new Date(year + 1, 0, 1),
        },
      },
    },
    {
      $group: {
        _id: { $month: "$paidAt" },
        revenue: { $sum: "$amount" },
        count: { $sum: 1 },
      },
    },
    { $sort: { _id: 1 } },
  ]);

  // New members per month
  const monthlyMembers = await Member.aggregate([
    {
      $match: {
        ...gymFilter,
        createdAt: {
          $gte: new Date(year, 0, 1),
          $lt: new Date(year + 1, 0, 1),
        },
      },
    },
    {
      $group: {
        _id: { $month: "$createdAt" },
        count: { $sum: 1 },
      },
    },
    { $sort: { _id: 1 } },
  ]);

  // Plan distribution
  const planDistribution = await Member.aggregate([
    { $match: { ...gymFilter, planName: { $exists: true, $ne: null } } },
    { $group: { _id: "$planName", count: { $sum: 1 } } },
    { $sort: { count: -1 } },
  ]);

  // Total revenue
  const totalRevenue = await Payment.aggregate([
    { $match: { ...gymFilter, status: "paid" } },
    { $group: { _id: null, total: { $sum: "$amount" } } },
  ]);

  return NextResponse.json({
    monthlyRevenue,
    monthlyMembers,
    planDistribution,
    totalRevenue: totalRevenue[0]?.total || 0,
    year,
  });
});
