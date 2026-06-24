import { NextRequest, NextResponse } from "next/server";
import { apiHandlerWithParams } from "@/lib/apiHandler";
import { ForbiddenError } from "@/lib/withAuth";
import { SessionUser } from "@/lib/session";
import Payment from "@/models/Payment";
import Membership from "@/models/Membership";
import ActivityLog from "@/models/ActivityLog";
import { recomputeMemberAggregates } from "@/lib/memberLedger";

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
    const payment = await Payment.findOne({ _id: id, gymId });
    if (!payment) return NextResponse.json({ error: "Not found" }, { status: 404 });

    // Block non-latest: payments stack, so only the member's most recent
    // payment can be deleted (keeps the membership history contiguous and
    // makes the reversal exact).
    const latest = await Payment.findOne({ gymId, memberId: payment.memberId })
      .sort({ createdAt: -1 })
      .select("_id")
      .lean();
    if (latest && String(latest._id) !== String(payment._id)) {
      return NextResponse.json(
        { error: "Only the most recent payment for this member can be deleted. Delete newer payments first." },
        { status: 400 }
      );
    }

    // Remove the membership period this payment created (if any), then the
    // payment, then recompute the member's ledger + window from what survives.
    await Membership.deleteMany({ paymentId: payment._id });
    await Payment.deleteOne({ _id: payment._id });
    await recomputeMemberAggregates(payment.memberId);

    await ActivityLog.create({
      gymId,
      staffId: user.id,
      staffName: user.name || "Unknown",
      action: "deleted",
      entity: "payment",
      entityId: id,
      details: `Deleted payment ${payment.invoiceNumber} for ${payment.memberName} (membership & dues reversed).`,
    });

    return NextResponse.json({ success: true });
  }
);
