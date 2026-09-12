import { Injectable } from "@nestjs/common";
import type { Types } from "mongoose";
import { Gym, Member, Payment } from "../schemas";
import { MongoConnectionService } from "../database";
import { CacheService, CACHE_TTL_SECONDS } from "../cache";
import { addCalendarDays, localDateTimeToInstant, todayInTimeZone } from "../lib";

/**
 * Gym dashboard summary. 1:1 parity with the Next.js `app/api/dashboard` route:
 * member-state counts, month-to-date net revenue, recent payments, and the list
 * of members expiring within the next week. All queries are tenant-scoped on
 * `gymId` (the `req.gymId` resolved by `RequireGymGuard`).
 */
@Injectable()
export class DashboardService {
  constructor(
    private readonly connection: MongoConnectionService,
    private readonly cache: CacheService,
  ) {}

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

        return {
          totalMembers,
          activeMembers,
          expiredMembers,
          expiringMembers,
          monthRevenue: (monthCollections[0]?.total || 0) - (monthRefunds[0]?.total || 0),
          recentPayments,
          expiringList,
        };
      },
    );
  }
}
