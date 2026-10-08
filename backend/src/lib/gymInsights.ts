import mongoose from "mongoose";
import { Member, Membership, Payment, Plan } from "../schemas";
import {
  addCalendarDays,
  localYearRange,
  previousYearAsOf,
  todayInTimeZone,
} from "./membershipCalendar";
import type { PlanStats } from "./planTypes";
import type { ReportsResponse } from "./reportTypes";

interface InsightsContext {
  gymId: string;
  timeZone: string;
  asOf: Date;
}

interface PaymentFacetResult {
  summary: Array<{ revenue: number; count: number }>;
  monthly: Array<{ _id: number; revenue: number; count: number }>;
  methods: Array<{ _id: string; amount: number; count: number }>;
  plans: Array<{
    _id: string;
    planId?: mongoose.Types.ObjectId;
    name: string;
    revenue: number;
  }>;
}

interface MembershipFacetResult {
  currentSummary: Array<{ count: number; renewals: number }>;
  currentMonthly: Array<{ _id: number; count: number; renewals: number }>;
  previousSummary: Array<{ count: number; renewals: number }>;
  planSales: Array<{
    _id: string;
    planId?: mongoose.Types.ObjectId;
    name: string;
    sales: number;
  }>;
}

interface MemberStateResult {
  activeMembers: Array<{ count: number }>;
  expiringSoon: Array<{ count: number }>;
  expiredMembers: Array<{ count: number }>;
  dues: Array<{ count: number; amount: number }>;
  activePlans: Array<{
    _id: string;
    planId?: mongoose.Types.ObjectId;
    name: string;
    count: number;
  }>;
}

function changePercent(current: number, previous: number): number | null {
  if (previous === 0) return current === 0 ? 0 : null;
  return Math.round(((current - previous) / previous) * 1000) / 10;
}

function metric(value: number, previous: number) {
  return { value, previous, changePercent: changePercent(value, previous) };
}

function planKeyExpression(planIdField: string, planNameField: string) {
  return {
    $cond: [
      { $ne: [planIdField, null] },
      { $concat: ["id:", { $toString: planIdField }] },
      { $concat: ["legacy:", { $ifNull: [planNameField, "Unlinked plan"] }] },
    ],
  };
}

function paymentFacets(
  dateField: "$paidAt" | "$refundedAt",
  timeZone: string
) {
  return {
    summary: [
      { $group: { _id: null, revenue: { $sum: "$amount" }, count: { $sum: 1 } } },
      { $project: { _id: 0, revenue: 1, count: 1 } },
    ],
    monthly: [
      {
        $group: {
          _id: { $month: { date: dateField, timezone: timeZone } },
          revenue: { $sum: "$amount" },
          count: { $sum: 1 },
        },
      },
      { $sort: { _id: 1 as const } },
    ],
    methods: [
      { $group: { _id: "$method", amount: { $sum: "$amount" }, count: { $sum: 1 } } },
      { $sort: { amount: -1 as const } },
    ],
    plans: [
      {
        $match: {
          $or: [
            { kind: "plan_purchase" },
            {
              kind: { $exists: false },
              $or: [
                { planId: { $ne: null } },
                { planName: { $nin: [null, ""] } },
              ],
            },
          ],
        },
      },
      {
        $set: {
          planKey: planKeyExpression("$planId", "$planName"),
        },
      },
      {
        $group: {
          _id: "$planKey",
          planId: { $first: "$planId" },
          name: { $last: { $ifNull: ["$planName", "Unlinked plan"] } },
          revenue: { $sum: "$amount" },
        },
      },
    ],
  };
}

function byMonth<T extends { _id: number }>(items: T[], month: number): T | undefined {
  return items.find((item) => item._id === month);
}

function planNameFor(
  key: string,
  fallback: string,
  currentNames: Map<string, string>
): string {
  return key.startsWith("id:") ? currentNames.get(key.slice(3)) ?? fallback : fallback;
}

export async function getAnnualGymInsights(
  context: InsightsContext,
  year: number
): Promise<ReportsResponse> {
  const gymId = new mongoose.Types.ObjectId(context.gymId);
  const { start, end } = localYearRange(year, context.timeZone);
  const previous = localYearRange(year - 1, context.timeZone);
  const currentLocalYear = Number(todayInTimeZone(context.timeZone, context.asOf).slice(0, 4));
  const isCurrentYear = year === currentLocalYear;
  const periodEnd = isCurrentYear ? context.asOf : end;
  const previousEnd = isCurrentYear
    ? previousYearAsOf(context.asOf, context.timeZone)
    : previous.end;
  const today = todayInTimeZone(context.timeZone, context.asOf);
  const thirtyDaysFromNow = addCalendarDays(today, 30);
  const gymFilter = { gymId };

  const [
    collections,
    refunds,
    previousCollections,
    previousRefunds,
    currentMembers,
    previousMembers,
    membershipFacets,
    memberStateFacets,
  ] = await Promise.all([
    Payment.aggregate<PaymentFacetResult>([
      {
        $match: {
          ...gymFilter,
          status: { $in: ["paid", "refunded"] },
          paidAt: { $gte: start, $lt: periodEnd },
        },
      },
      { $facet: paymentFacets("$paidAt", context.timeZone) },
    ]),
    Payment.aggregate<PaymentFacetResult>([
      {
        $match: {
          ...gymFilter,
          status: "refunded",
          refundedAt: { $gte: start, $lt: periodEnd },
        },
      },
      { $facet: paymentFacets("$refundedAt", context.timeZone) },
    ]),
    Payment.aggregate<{ revenue: number; count: number }>([
      {
        $match: {
          ...gymFilter,
          status: { $in: ["paid", "refunded"] },
          paidAt: { $gte: previous.start, $lt: previousEnd },
        },
      },
      { $group: { _id: null, revenue: { $sum: "$amount" }, count: { $sum: 1 } } },
      { $project: { _id: 0, revenue: 1, count: 1 } },
    ]),
    Payment.aggregate<{ revenue: number }>([
      {
        $match: {
          ...gymFilter,
          status: "refunded",
          refundedAt: { $gte: previous.start, $lt: previousEnd },
        },
      },
      { $group: { _id: null, revenue: { $sum: "$amount" } } },
      { $project: { _id: 0, revenue: 1 } },
    ]),
    Member.aggregate<{ _id: number; count: number }>([
      {
        $match: {
          ...gymFilter,
          isActive: { $ne: false },
          createdAt: { $gte: start, $lt: periodEnd },
        },
      },
      {
        $group: {
          _id: { $month: { date: "$createdAt", timezone: context.timeZone } },
          count: { $sum: 1 },
        },
      },
      { $sort: { _id: 1 } },
    ]),
    Member.countDocuments({
      ...gymFilter,
      isActive: { $ne: false },
      createdAt: { $gte: previous.start, $lt: previousEnd },
    }),
    Membership.aggregate<MembershipFacetResult>([
      { $match: { ...gymFilter, status: { $ne: "reversed" } } },
      {
        $setWindowFields: {
          partitionBy: "$memberId",
          sortBy: { createdAt: 1 },
          output: { purchaseNumber: { $documentNumber: {} } },
        },
      },
      {
        $facet: {
          currentSummary: [
            { $match: { createdAt: { $gte: start, $lt: periodEnd } } },
            {
              $group: {
                _id: null,
                count: { $sum: 1 },
                renewals: { $sum: { $cond: [{ $gt: ["$purchaseNumber", 1] }, 1, 0] } },
              },
            },
            { $project: { _id: 0, count: 1, renewals: 1 } },
          ],
          currentMonthly: [
            { $match: { createdAt: { $gte: start, $lt: periodEnd } } },
            {
              $group: {
                _id: { $month: { date: "$createdAt", timezone: context.timeZone } },
                count: { $sum: 1 },
                renewals: { $sum: { $cond: [{ $gt: ["$purchaseNumber", 1] }, 1, 0] } },
              },
            },
            { $sort: { _id: 1 } },
          ],
          previousSummary: [
            { $match: { createdAt: { $gte: previous.start, $lt: previousEnd } } },
            {
              $group: {
                _id: null,
                count: { $sum: 1 },
                renewals: { $sum: { $cond: [{ $gt: ["$purchaseNumber", 1] }, 1, 0] } },
              },
            },
            { $project: { _id: 0, count: 1, renewals: 1 } },
          ],
          planSales: [
            { $match: { createdAt: { $gte: start, $lt: periodEnd } } },
            { $set: { planKey: planKeyExpression("$planId", "$planName") } },
            {
              $group: {
                _id: "$planKey",
                planId: { $first: "$planId" },
                name: { $last: "$planName" },
                sales: { $sum: 1 },
              },
            },
          ],
        },
      },
    ]),
    Member.aggregate<MemberStateResult>([
      { $match: { ...gymFilter, isActive: { $ne: false } } },
      {
        $facet: {
          activeMembers: [
            { $match: { membershipExpiry: { $gte: today } } },
            { $count: "count" },
          ],
          expiringSoon: [
            { $match: { membershipExpiry: { $gte: today, $lte: thirtyDaysFromNow } } },
            { $count: "count" },
          ],
          expiredMembers: [
            { $match: { membershipExpiry: { $lt: today } } },
            { $count: "count" },
          ],
          dues: [
            { $match: { dueAmount: { $gt: 0 } } },
            { $group: { _id: null, count: { $sum: 1 }, amount: { $sum: "$dueAmount" } } },
            { $project: { _id: 0, count: 1, amount: 1 } },
          ],
          activePlans: [
            { $match: { membershipExpiry: { $gte: today }, planId: { $ne: null } } },
            { $set: { planKey: planKeyExpression("$planId", "$planName") } },
            {
              $group: {
                _id: "$planKey",
                planId: { $first: "$planId" },
                name: { $last: "$planName" },
                count: { $sum: 1 },
              },
            },
          ],
        },
      },
    ]),
  ]);

  const collected = collections[0] ?? { summary: [], monthly: [], methods: [], plans: [] };
  const refunded = refunds[0] ?? { summary: [], monthly: [], methods: [], plans: [] };
  const memberships = membershipFacets[0] ?? {
    currentSummary: [],
    currentMonthly: [],
    previousSummary: [],
    planSales: [],
  };
  const memberState = memberStateFacets[0] ?? {
    activeMembers: [],
    expiringSoon: [],
    expiredMembers: [],
    dues: [],
    activePlans: [],
  };
  const collectionSummary = collected.summary[0] ?? { revenue: 0, count: 0 };
  const refundSummary = refunded.summary[0] ?? { revenue: 0, count: 0 };
  const previousCollectionSummary = previousCollections[0] ?? { revenue: 0, count: 0 };
  const previousRefundSummary = previousRefunds[0]?.revenue ?? 0;
  const membershipSummary = memberships.currentSummary[0] ?? { count: 0, renewals: 0 };
  const previousMembershipSummary = memberships.previousSummary[0] ?? { count: 0, renewals: 0 };
  const currentNewMembers = currentMembers.reduce((sum, month) => sum + month.count, 0);
  const dues = memberState.dues[0] ?? { count: 0, amount: 0 };
  const revenue = collectionSummary.revenue - refundSummary.revenue;

  const series = Array.from({ length: 12 }, (_, index) => {
    const month = index + 1;
    const payment = byMonth(collected.monthly, month);
    const refund = byMonth(refunded.monthly, month);
    const members = byMonth(currentMembers, month);
    const membership = byMonth(memberships.currentMonthly, month);
    return {
      month,
      revenue: (payment?.revenue ?? 0) - (refund?.revenue ?? 0),
      transactions: payment?.count ?? 0,
      newMembers: members?.count ?? 0,
      memberships: membership?.count ?? 0,
      renewals: membership?.renewals ?? 0,
    };
  });

  const planIds = new Set<string>();
  for (const item of [...collected.plans, ...refunded.plans, ...memberships.planSales, ...memberState.activePlans]) {
    if (item.planId) planIds.add(item.planId.toString());
  }
  const currentPlans = await Plan.find({
    gymId,
    _id: { $in: [...planIds].map((id) => new mongoose.Types.ObjectId(id)) },
  }).select("name").lean();
  const currentNames = new Map(currentPlans.map((plan) => [plan._id.toString(), plan.name]));
  const planRows = new Map<string, { planId?: string; name: string; revenue: number; sales: number; activeMembers: number }>();
  const row = (key: string, planId: mongoose.Types.ObjectId | undefined, name: string) => {
    const current = planRows.get(key) ?? {
      planId: planId?.toString(),
      name: planNameFor(key, name, currentNames),
      revenue: 0,
      sales: 0,
      activeMembers: 0,
    };
    planRows.set(key, current);
    return current;
  };
  for (const item of collected.plans) row(item._id, item.planId, item.name).revenue += item.revenue;
  for (const item of refunded.plans) row(item._id, item.planId, item.name).revenue -= item.revenue;
  for (const item of memberships.planSales) row(item._id, item.planId, item.name).sales += item.sales;
  for (const item of memberState.activePlans) row(item._id, item.planId, item.name).activeMembers += item.count;
  const planPerformance = [...planRows.entries()]
    .map(([key, value]) => ({ key, ...value }))
    .sort((a, b) => b.revenue - a.revenue);

  const collectionMethods = new Map(collected.methods.map((method) => [method._id, method]));
  const refundMethods = new Map(refunded.methods.map((method) => [method._id, method.amount]));
  const methodKeys = new Set([...collectionMethods.keys(), ...refundMethods.keys()]);
  const paymentMethods = [...methodKeys].map((methodKey) => {
    const method = collectionMethods.get(methodKey);
    const amount = (method?.amount ?? 0) - (refundMethods.get(methodKey) ?? 0);
    return {
      method: methodKey,
      amount,
      count: method?.count ?? 0,
      percentage: revenue > 0 ? Math.max(0, Math.round((amount / revenue) * 100)) : 0,
    };
  }).sort((a, b) => b.amount - a.amount);
  const bestMonth = series.reduce<(typeof series)[number] | null>(
    (best, point) => (!best || point.revenue > best.revenue ? point : best),
    null
  );

  return {
    year,
    asOf: context.asOf.toISOString(),
    timezone: context.timeZone,
    summary: {
      revenue: metric(revenue, previousCollectionSummary.revenue - previousRefundSummary),
      transactions: metric(collectionSummary.count, previousCollectionSummary.count),
      newMembers: metric(currentNewMembers, previousMembers),
      renewals: metric(membershipSummary.renewals, previousMembershipSummary.renewals),
      activeMembers: memberState.activeMembers[0]?.count ?? 0,
      outstandingDues: dues.amount,
      dueMembers: dues.count,
    },
    series,
    planPerformance,
    paymentMethods,
    insights: {
      expiringSoon: memberState.expiringSoon[0]?.count ?? 0,
      expiredMembers: memberState.expiredMembers[0]?.count ?? 0,
      dueMembers: dues.count,
      outstandingDues: dues.amount,
      bestMonth: bestMonth && bestMonth.revenue > 0
        ? { month: bestMonth.month, revenue: bestMonth.revenue }
        : null,
    },
  };
}

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
