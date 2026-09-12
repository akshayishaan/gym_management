import mongoose from "mongoose";
import { Member, Membership, Payment, Plan } from "../schemas";
import { localYearRange, todayInTimeZone } from "./membershipCalendar";
import type { PlanStats } from "./planTypes";

interface InsightsContext {
  gymId: string;
  timeZone: string;
  asOf: Date;
}

// Only the plan-portfolio insights are ported here. `getAnnualGymInsights` and
// `ReportsResponse` belong to the reports module (issue 10) and live in the
// Next.js reference under `lib/gymInsights.ts` / `lib/reportTypes.ts`.
export async function getPlanPortfolioInsights(context: InsightsContext): Promise<{
  byPlan: Record<string, PlanStats>;
  summary: {
    activePlans: number;
    activeMembers: number;
    salesYtd: number;
    revenueAtSaleYtd: number;
  };
}> {
  const gymId = new mongoose.Types.ObjectId(context.gymId);
  const year = Number(todayInTimeZone(context.timeZone, context.asOf).slice(0, 4));
  const { start } = localYearRange(year, context.timeZone);
  const today = todayInTimeZone(context.timeZone, context.asOf);
  const [activePlans, activeMembers, sales, collections, refunds, totals] = await Promise.all([
    Plan.countDocuments({ gymId, isActive: { $ne: false } }),
    Member.aggregate<{ _id: mongoose.Types.ObjectId; count: number }>([
      {
        $match: {
          gymId,
          isActive: { $ne: false },
          membershipExpiry: { $gte: today },
          planId: { $ne: null },
        },
      },
      { $group: { _id: "$planId", count: { $sum: 1 } } },
    ]),
    Membership.aggregate<{ _id: mongoose.Types.ObjectId; count: number }>([
      {
        $match: {
          gymId,
          status: { $ne: "reversed" },
          createdAt: { $gte: start, $lt: context.asOf },
          planId: { $ne: null },
        },
      },
      { $group: { _id: "$planId", count: { $sum: 1 } } },
    ]),
    Payment.aggregate<{ _id: mongoose.Types.ObjectId; amount: number }>([
      {
        $match: {
          gymId,
          status: { $in: ["paid", "refunded"] },
          paidAt: { $gte: start, $lt: context.asOf },
          planId: { $ne: null },
        },
      },
      { $group: { _id: "$planId", amount: { $sum: "$amount" } } },
    ]),
    Payment.aggregate<{ _id: mongoose.Types.ObjectId; amount: number }>([
      {
        $match: {
          gymId,
          status: "refunded",
          refundedAt: { $gte: start, $lt: context.asOf },
          planId: { $ne: null },
        },
      },
      { $group: { _id: "$planId", amount: { $sum: "$amount" } } },
    ]),
    Membership.aggregate<{ _id: mongoose.Types.ObjectId; count: number }>([
      { $match: { gymId, status: { $ne: "reversed" }, planId: { $ne: null } } },
      { $group: { _id: "$planId", count: { $sum: 1 } } },
    ]),
  ]);

  const byPlan: Record<string, PlanStats> = {};
  const get = (id: string) => byPlan[id] ??= {
    activeMembers: 0,
    salesYtd: 0,
    revenueAtSaleYtd: 0,
    totalMemberships: 0,
  };
  for (const item of activeMembers) get(item._id.toString()).activeMembers = item.count;
  for (const item of sales) get(item._id.toString()).salesYtd = item.count;
  for (const item of collections) get(item._id.toString()).revenueAtSaleYtd += item.amount;
  for (const item of refunds) get(item._id.toString()).revenueAtSaleYtd -= item.amount;
  for (const item of totals) get(item._id.toString()).totalMemberships = item.count;

  return {
    byPlan,
    summary: {
      activePlans,
      activeMembers: activeMembers.reduce((sum, item) => sum + item.count, 0),
      salesYtd: sales.reduce((sum, item) => sum + item.count, 0),
      revenueAtSaleYtd: Object.values(byPlan).reduce(
        (sum, item) => sum + item.revenueAtSaleYtd,
        0
      ),
    },
  };
}
