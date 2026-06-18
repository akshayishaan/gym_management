import { NextRequest, NextResponse } from "next/server";
import { apiHandler } from "@/lib/apiHandler";
import { requireSuperAdminOrRole, getGymFilter } from "@/lib/withAuth";
import { SessionUser } from "@/lib/session";
import ActivityLog from "@/models/ActivityLog";

export const GET = apiHandler(async (req: NextRequest, user: SessionUser) => {
  requireSuperAdminOrRole(user, "admin");

  const { searchParams } = new URL(req.url);
  const page = parseInt(searchParams.get("page") || "1");
  const limit = parseInt(searchParams.get("limit") || "50");
  const gymIdParam = searchParams.get("gymId");

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const query: any = { ...getGymFilter(user, gymIdParam) };

  const total = await ActivityLog.countDocuments(query);
  const logs = await ActivityLog.find(query)
    .sort({ createdAt: -1 })
    .skip((page - 1) * limit)
    .limit(limit)
    .lean();

  return NextResponse.json({ logs, total, page, limit });
});
