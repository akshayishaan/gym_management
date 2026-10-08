import { Injectable } from "@nestjs/common";
import type { Types } from "mongoose";
import { Gym, Member, Membership, Payment } from "../schemas";
import { MongoConnectionService } from "../database";
import { CacheService, CACHE_TTL_SECONDS } from "../cache";
import {
  addCalendarDays,
  calendarDaysBetween,
  localDateTimeToInstant,
  sameDayPreviousMonth,
  todayInTimeZone,
} from "../lib";

/**
 * Attaches the server-computed days-until-expiry (ADR-0005) to each expiring
 * list row. The expiringList query filters on `membershipExpiry`, so every
 * returned document carries one.
 */
function withDaysUntilExpiry<T extends { membershipExpiry?: string }>(
  member: T,
  today: string,
): T & { daysUntilExpiry: number } {
  return {
    ...member,
    daysUntilExpiry: calendarDaysBetween(today, member.membershipExpiry!),
  };
}

/**
 * Gym dashboard summary. 1:1 parity with the Next.js `app/api/dashboard` route:
 * member-state counts, month-to-date net revenue, recent payments, and the list
 * of members expiring within the next week. All queries are tenant-scoped on
 * `gymId` (the `req.gymId` resolved by `RequireGymGuard`).
 *
 * `previous` holds the same three figures (total members, active members,
 * month revenue) as they stood at this point last month, so clients can show
 * a like-for-like change: "today" becomes the same day-of-month one month
 * earlier, and revenue covers the first of that month through the end of that
 * day. Members removed since then are not counted back in, and members with
 * no Membership record cannot be counted as active last month.
 *
 * Those figures are history, so they are cached separately for an hour per
 * gym-local day (see `previousFigures`) instead of being recomputed with the
 * 30-second live numbers.
 */
@Injectable()
export class DashboardService {
  constructor(
    private readonly connection: MongoConnectionService,
    private readonly cache: CacheService,
  ) {}

  /** Net cash collected in [start, end): paid-in minus refunds, by event time. */
  private async netRevenue(gymId: Types.ObjectId, start: Date, end?: Date): Promise<number> {
    const window = end ? { $gte: start, $lt: end } : { $gte: start };
    const [collections, refunds] = await Promise.all([
      Payment.aggregate([
        { $match: { gymId: { $eq: gymId }, paidAt: window, status: { $in: ["paid", "refunded"] } } },
        { $group: { _id: null, total: { $sum: "$amount" } } },
      ]),
      Payment.aggregate([
        { $match: { gymId: { $eq: gymId }, refundedAt: window, status: "refunded" } },
        { $group: { _id: null, total: { $sum: "$amount" } } },
      ]),
    ]);
    return (collections[0]?.total || 0) - (refunds[0]?.total || 0);
  }

  /**
   * Members with a surviving Membership period covering `date`, still active
   * today. One aggregation, so no member-ID list travels to the app server and
   * back; the join uses the Member `_id` index.
   */
  private async activeMembersOn(gymId: Types.ObjectId, date: string): Promise<number> {
    const [row] = await Membership.aggregate<{ n: number }>([
      {
        $match: {
          gymId: { $eq: gymId },
          status: { $ne: "reversed" },
          startDate: { $lte: date },
          expiryDate: { $gte: date },
        },
      },
      { $group: { _id: "$memberId" } },
      { $lookup: { from: Member.collection.name, localField: "_id", foreignField: "_id", as: "member" } },
      { $unwind: "$member" },
      { $match: { "member.gymId": { $eq: gymId }, "member.isActive": { $ne: false } } },
      { $count: "n" },
    ]);
    return row?.n ?? 0;
  }

  /** Last month's total members, active members and net revenue at this point in the month. */
  private previousFigures(gymId: Types.ObjectId, today: string, timeZone: string) {
    return this.cache.getOrCompute(
      `cache:dashboard-previous:${String(gymId)}:${today}`,
      CACHE_TTL_SECONDS.dashboardPrevious,
      async () => {
        const lastMonthToday = sameDayPreviousMonth(today);
        const previousMonthStart = localDateTimeToInstant(`${lastMonthToday.slice(0, 7)}-01`, timeZone);
        const throughEndOfDay = localDateTimeToInstant(addCalendarDays(lastMonthToday, 1), timeZone);
        const [totalMembers, activeMembers, monthRevenue] = await Promise.all([
          Member.countDocuments({ gymId, isActive: { $ne: false }, createdAt: { $lt: throughEndOfDay } }),
          this.activeMembersOn(gymId, lastMonthToday),
          this.netRevenue(gymId, previousMonthStart, throughEndOfDay),
        ]);
        return { totalMembers, activeMembers, monthRevenue };
      },
    );
  }

  async getDashboard(gymId: Types.ObjectId) {
    await this.connection.getConnection();

    return this.cache.getOrCompute(
      `cache:dashboard:${String(gymId)}`,
      CACHE_TTL_SECONDS.dashboard,
      async () => {
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
          monthRevenue,
          recentPayments,
          expiringList,
          previous,
        ] = await Promise.all([
          Member.countDocuments({ gymId, isActive: { $ne: false } }),
          Member.countDocuments({ gymId, isActive: { $ne: false }, membershipExpiry: { $gte: today } }),
          Member.countDocuments({ gymId, isActive: { $ne: false }, membershipExpiry: { $lt: today } }),
          Member.countDocuments({ gymId, isActive: { $ne: false }, membershipExpiry: { $gte: today, $lte: weekLater } }),
          this.netRevenue(gymId, startOfMonth),
          Payment.find({ gymId, status: "paid" }).sort({ paidAt: -1 }).limit(5).lean(),
          Member.find({ gymId, isActive: { $ne: false }, membershipExpiry: { $gte: today, $lte: weekLater } })
            .sort({ membershipExpiry: 1 })
            .limit(10)
            .select("name phone membershipExpiry planName")
            .lean(),
          this.previousFigures(gymId, today, timeZone),
        ]);

        const expiringWithDays = expiringList.map((m) => withDaysUntilExpiry(m, today));

        return {
          totalMembers,
          activeMembers,
          expiredMembers,
          expiringMembers,
          monthRevenue,
          previous,
          recentPayments,
          expiringList: expiringWithDays,
        };
      },
    );
  }
}
