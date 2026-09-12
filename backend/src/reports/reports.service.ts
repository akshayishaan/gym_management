import { Injectable } from "@nestjs/common";
import type { Types } from "mongoose";
import { Gym } from "../schemas";
import { DomainError } from "../common";
import { MongoConnectionService } from "../database";
import { getAnnualGymInsights, todayInTimeZone } from "../lib";

/**
 * Annual reports with 1:1 parity to the Next.js `app/api/reports` route. The
 * heavy lifting lives in `getAnnualGymInsights` (lib); this service resolves the
 * gym timezone, coerces the requested year, and delegates.
 */
@Injectable()
export class ReportsService {
  constructor(private readonly connection: MongoConnectionService) {}

  async getReport(gymId: Types.ObjectId, yearParam?: string) {
    await this.connection.getConnection();

    const gym = await Gym.findById(gymId).select("timezone").lean();
    if (!gym) throw new DomainError("Gym not found", 404);
    const timeZone = gym.timezone || "Asia/Kolkata";
    const asOf = new Date();
    const currentYear = Number(todayInTimeZone(timeZone, asOf).slice(0, 4));
    const parsedYear = Number(yearParam || currentYear);
    const year = Number.isInteger(parsedYear) && parsedYear >= 2000 && parsedYear <= 2100
      ? parsedYear
      : currentYear;

    return getAnnualGymInsights({
      gymId: String(gymId),
      timeZone,
      asOf,
    }, year);
  }
}
