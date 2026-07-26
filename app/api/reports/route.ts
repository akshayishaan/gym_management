import { NextRequest, NextResponse } from "next/server";
import { apiHandler } from "@/lib/apiHandler";
import { getGymFilter } from "@/lib/withAuth";
import Gym from "@/models/Gym";
import { getAnnualGymInsights } from "@/lib/gymInsights";
import { todayInTimeZone } from "@/lib/membershipCalendar";

export const GET = apiHandler(async (req: NextRequest, user) => {
  const { searchParams } = new URL(req.url);
  const gymFilter = getGymFilter(user);
  const gym = await Gym.findById(gymFilter.gymId).select("timezone").lean();
  if (!gym) return NextResponse.json({ error: "Gym not found" }, { status: 404 });
  const timeZone = gym.timezone || "Asia/Kolkata";
  const asOf = new Date();
  const currentYear = Number(todayInTimeZone(timeZone, asOf).slice(0, 4));
  const parsedYear = Number(searchParams.get("year") || currentYear);
  const year = Number.isInteger(parsedYear) && parsedYear >= 2000 && parsedYear <= 2100
    ? parsedYear
    : currentYear;

  const report = await getAnnualGymInsights({
    gymId: String(gymFilter.gymId),
    timeZone,
    asOf,
  }, year);
  return NextResponse.json(report);
});
