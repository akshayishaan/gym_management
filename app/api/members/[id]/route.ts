import { NextRequest, NextResponse } from "next/server";
import { apiHandlerWithParams } from "@/lib/apiHandler";
import { ForbiddenError } from "@/lib/withAuth";
import { SessionUser } from "@/lib/session";
import Member from "@/models/Member";
import ActivityLog from "@/models/ActivityLog";
import { memberUpdateSchema } from "@/lib/validators/member";

export const GET = apiHandlerWithParams<{ id: string }>(
  async (_req, user, { id }) => {
    const member = await Member.findById(id).lean();
    if (!member) return NextResponse.json({ error: "Not found" }, { status: 404 });

    if (String((member as { gymId?: unknown }).gymId) !== user.selectedGymId) {
      throw new ForbiddenError("You can only access members in your gym");
    }

    return NextResponse.json(member);
  }
);

export const PUT = apiHandlerWithParams<{ id: string }>(
  async (req, user, { id }) => {
    const gymId = user.selectedGymId!;
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
    const gymId = user.selectedGymId!;
    const member = await Member.findOneAndDelete({ _id: id, gymId });
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
