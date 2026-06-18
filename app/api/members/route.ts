import { NextRequest, NextResponse } from "next/server";
import { apiHandler } from "@/lib/apiHandler";
import { requireNotSuperAdmin, getGymFilter } from "@/lib/withAuth";
import { SessionUser } from "@/lib/session";
import Member from "@/models/Member";
import ActivityLog from "@/models/ActivityLog";
import { memberCreateSchema } from "@/lib/validators/member";

export const GET = apiHandler(async (req: NextRequest, user: SessionUser) => {
  const { searchParams } = new URL(req.url);
  const search = searchParams.get("search") || "";
  const status = searchParams.get("status") || "";
  const page = parseInt(searchParams.get("page") || "1");
  const limit = parseInt(searchParams.get("limit") || "20");
  const gymIdParam = searchParams.get("gymId");

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const query: any = { ...getGymFilter(user, gymIdParam) };

  if (search) {
    query.$or = [
      { name: { $regex: search, $options: "i" } },
      { phone: { $regex: search, $options: "i" } },
      { email: { $regex: search, $options: "i" } },
    ];
  }

  const today = new Date();
  if (status === "active") {
    query.membershipExpiry = { $gte: today };
  } else if (status === "expired") {
    query.membershipExpiry = { $lt: today };
  } else if (status === "expiring") {
    const week = new Date();
    week.setDate(week.getDate() + 7);
    query.membershipExpiry = { $gte: today, $lte: week };
  }

  const total = await Member.countDocuments(query);
  const members = await Member.find(query)
    .sort({ createdAt: -1 })
    .skip((page - 1) * limit)
    .limit(limit)
    .lean();

  return NextResponse.json({ members, total, page, limit });
});

export const POST = apiHandler(async (req: NextRequest, user: SessionUser) => {
  requireNotSuperAdmin(user);

  const gymId = user.selectedGymId!;
  const body = await req.json();
  const validated = memberCreateSchema.parse(body);

  const member = await Member.create({ ...validated, gymId });

  await ActivityLog.create({
    gymId,
    staffId: user.id,
    staffName: user.name || "Unknown",
    action: "created",
    entity: "member",
    entityId: member._id.toString(),
    details: `Created member: ${member.name}`,
  });

  return NextResponse.json(member, { status: 201 });
});
