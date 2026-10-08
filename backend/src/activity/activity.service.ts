import { Injectable } from "@nestjs/common";
import type { Types } from "mongoose";
import { ActivityLog, Gym } from "../schemas";
import { MongoConnectionService } from "../database";
import { DomainError } from "../common/errors";
import {
  addCalendarDays,
  isDateOnly,
  localDateTimeToInstant,
  toDateOnly,
  todayInTimeZone,
} from "../lib";

/**
 * Optional filters for the activity list. All are in the Gym's own calendar
 * (ADR-0002): `range=today|week` is resolved on the server, and `from`/`to`
 * are inclusive `YYYY-MM-DD` dates in the Gym's timezone.
 */
export interface ActivityListQuery {
  range?: string;
  from?: string;
  to?: string;
  /** Comma-separated action names, e.g. `created,voided`. */
  actions?: string;
}

export interface ActivityListResult {
  logs: Array<Record<string, unknown>>;
  total: number;
  page: number;
  limit: number;
  /** The Gym's current calendar date, `YYYY-MM-DD`. */
  today: string;
  timezone: string;
  /** The Gym-local date range applied, or null when unfiltered. */
  range: { from: string; to: string } | null;
}

const DEFAULT_TIME_ZONE = "Asia/Kolkata";
const ACTION_PATTERN = /^[a-z_]{1,30}$/;

/**
 * Tenant-scoped activity log listing. The response key is `logs` (parity with
 * the Next.js `app/api/activity` route). Unlike the members/plans lists, the
 * page/limit params are coarsed with a bare `parseInt` (no finite/clamp checks).
 *
 * Besides page/limit, the list can be narrowed by Gym-local date range and by
 * action. `total` is the count for the same filter, so a client can show
 * "Showing X of total" truthfully. Each log carries `day` and `time` in the
 * Gym's timezone, and the response carries the Gym's `today`, so clients do
 * not need to trust the device clock or timezone.
 */
@Injectable()
export class ActivityService {
  constructor(private readonly connection: MongoConnectionService) {}

  async list(
    gymId: Types.ObjectId,
    pageRaw?: string,
    limitRaw?: string,
    filters: ActivityListQuery = {},
  ): Promise<ActivityListResult> {
    await this.connection.getConnection();

    const page = parseInt(pageRaw || "1", 10);
    const limit = parseInt(limitRaw || "50", 10);

    const gym = await Gym.findById(gymId).select("timezone").lean();
    const timeZone = gym?.timezone || DEFAULT_TIME_ZONE;
    const today = todayInTimeZone(timeZone);

    const query: Record<string, unknown> = { gymId };

    const range = this.resolveRange(filters, today);
    if (range) {
      query.createdAt = {
        $gte: localDateTimeToInstant(range.from, timeZone),
        $lt: localDateTimeToInstant(addCalendarDays(range.to, 1), timeZone),
      };
    }

    const actions = (filters.actions ?? "")
      .split(",")
      .map((action) => action.trim())
      .filter((action) => ACTION_PATTERN.test(action));
    if (actions.length > 0) query.action = { $in: actions };

    const total = await ActivityLog.countDocuments(query);
    const rows = await ActivityLog.find(query)
      .sort({ createdAt: -1 })
      .skip((page - 1) * limit)
      .limit(limit)
      .lean();

    const logs: Array<Record<string, unknown>> = rows.map((log) => ({
      ...log,
      day: toDateOnly(log.createdAt, timeZone),
      time: this.timeInZone(log.createdAt, timeZone),
    }));

    return { logs, total, page, limit, today, timezone: timeZone, range };
  }

  private resolveRange(filters: ActivityListQuery, today: string) {
    const { range, from, to } = filters;
    if (range === "today") return { from: today, to: today };
    if (range === "week") return { from: addCalendarDays(today, -6), to: today };
    if (from || to) {
      if ((from && !isDateOnly(from)) || (to && !isDateOnly(to))) {
        throw new DomainError("from and to must be YYYY-MM-DD dates");
      }
      const start = from ?? to!;
      const end = to ?? from!;
      if (start > end) throw new DomainError("from must not be after to");
      return { from: start, to: end };
    }
    if (range && range !== "all") {
      throw new DomainError("range must be today, week or all");
    }
    return null;
  }

  private timeInZone(value: Date, timeZone: string): string {
    return new Intl.DateTimeFormat("en-GB", {
      timeZone,
      hour: "2-digit",
      minute: "2-digit",
      hourCycle: "h23",
    }).format(value);
  }
}
