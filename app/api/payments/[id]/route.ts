import { NextRequest, NextResponse } from "next/server";
import { apiHandlerWithParams } from "@/lib/apiHandler";
import { ForbiddenError } from "@/lib/withAuth";
import { SessionUser } from "@/lib/session";
import Payment from "@/models/Payment";
import ActivityLog from "@/models/ActivityLog";

export const GET = apiHandlerWithParams<{ id: string }>(
  async (_req, user, { id }) => {
    const payment = await Payment.findById(id).lean();
    if (!payment) return NextResponse.json({ error: "Not found" }, { status: 404 });

    if (String((payment as { gymId?: unknown }).gymId) !== user.selectedGymId) {
      throw new ForbiddenError("You can only access payments in your gym");
    }

    return NextResponse.json(payment);
  }
);

export const DELETE = apiHandlerWithParams<{ id: string }>(
  async (_req, user, { id }) => {
    const gymId = user.selectedGymId!;
    const payment = await Payment.findOneAndDelete({ _id: id, gymId });
    if (!payment) return NextResponse.json({ error: "Not found" }, { status: 404 });

    await ActivityLog.create({
      gymId,
      staffId: user.id,
      staffName: user.name || "Unknown",
      action: "deleted",
      entity: "payment",
      entityId: id,
      details: `Deleted payment: ${payment.invoiceNumber}`,
    });

    return NextResponse.json({ success: true });
  }
);
