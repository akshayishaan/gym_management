import { NextResponse } from "next/server";
import { apiHandlerWithParams } from "@/lib/apiHandler";
import { getGymFilter } from "@/lib/withAuth";
import Member from "@/models/Member";
import ActivityLog from "@/models/ActivityLog";
import { memberUpdateSchema } from "@/lib/validators/member";

export const GET = apiHandlerWithParams<{ id: string }>(
  async (_req, user, { id }) => {
    const member = await Member.findOne({ _id: id, ...getGymFilter(user) }).lean();
    if (!member) return NextResponse.json({ error: "Not found" }, { status: 404 });
    return NextResponse.json(member);
  }
);

export const PUT = apiHandlerWithParams<{ id: string }>(
  async (req, user, { id }) => {
    const gymId = getGymFilter(user).gymId;
    const body = await req.json();
    const validated = memberUpdateSchema.parse(body);

    const member = await Member.findOneAndUpdate(
      { _id: id, gymId },
      validated,
      { new: true }
    );
    if (!member) return NextResponse.json({ error: "Not found" }, { status: 404 });

    await ActivityLog.create({
      gymId,
      staffId: user.id,
      staffName: user.name || "Unknown",
      action: "updated",
      entity: "member",
      entityId: id,
      details: `Updated member: ${member.name}`,
    });

    return NextResponse.json(member);
  }
);

export const DELETE = apiHandlerWithParams<{ id: string }>(
  async (_req, user, { id }) => {
    const gymId = getGymFilter(user).gymId;
    // Soft delete: members are never removed from the DB (preserves revenue /
    // payment history). Setting isActive=false hides them from lists, counts,
    // reports, and the payment member-picker. Restore via PUT { isActive: true }.
    const member = await Member.findOneAndUpdate(
      { _id: id, gymId },
      { isActive: false },
      { new: true }
    );
    if (!member) return NextResponse.json({ error: "Not found" }, { status: 404 });

    await ActivityLog.create({
      gymId,
      staffId: user.id,
      staffName: user.name || "Unknown",
      action: "deleted",
      entity: "member",
      entityId: id,
      details: `Deleted member: ${member.name}`,
    });

    return NextResponse.json({ success: true });
  }
);
