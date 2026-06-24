import { NextRequest, NextResponse } from "next/server";
import { apiHandler } from "@/lib/apiHandler";
import { getGymFilter } from "@/lib/withAuth";
import { SessionUser } from "@/lib/session";
import Payment from "@/models/Payment";
import Member from "@/models/Member";
import Plan from "@/models/Plan";
import Membership from "@/models/Membership";
import ActivityLog from "@/models/ActivityLog";
import { paymentCreateSchema } from "@/lib/validators/payment";
import { generateInvoiceNumber } from "@/lib/utils";

export const GET = apiHandler(async (req: NextRequest, user: SessionUser) => {
  const { searchParams } = new URL(req.url);
  const memberId = searchParams.get("memberId") || "";
  const page = parseInt(searchParams.get("page") || "1");
  const limit = parseInt(searchParams.get("limit") || "20");
  const month = searchParams.get("month") || "";
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const query: any = { ...getGymFilter(user) };

  if (memberId) query.memberId = memberId;
  if (month) {
    const [y, m] = month.split("-").map(Number);
    const start = new Date(y, m - 1, 1);
    const end = new Date(y, m, 1);
    query.paidAt = { $gte: start, $lt: end };
  }

  const total = await Payment.countDocuments(query);
  const payments = await Payment.find(query)
    .sort({ paidAt: -1 })
    .skip((page - 1) * limit)
    .limit(limit)
    .lean();

  return NextResponse.json({ payments, total, page, limit });
});

export const POST = apiHandler(async (req: NextRequest, user: SessionUser) => {
  const gymId = user.selectedGymId!;
  const body = await req.json();
  const validated = paymentCreateSchema.parse(body);
  const invoiceNumber = await generateInvoiceNumber();

  const payment = await Payment.create({
    ...validated,
    gymId,
    invoiceNumber,
    createdBy: user.id,
  });

  // Always fetch the member upfront so we can update dueAmount regardless
  // of whether a plan was selected.
  const member = await Member.findById(validated.memberId);

  let renewedUntil: Date | null = null;
  let planCost = 0;

  // ── Renew membership when a plan is selected ───────────────────────────────
  if (validated.planId && member) {
    const plan = await Plan.findById(validated.planId);

    if (plan) {
      planCost = plan.price;
      const paymentDate = validated.paidAt ? new Date(validated.paidAt) : new Date();
      const now = new Date();

      // Stack from current expiry if still active; otherwise start fresh.
      const isActive = member.membershipExpiry && member.membershipExpiry > now;
      const renewFrom: Date = isActive ? member.membershipExpiry! : paymentDate;

      renewedUntil = new Date(renewFrom);
      renewedUntil.setDate(renewedUntil.getDate() + plan.durationDays);

      // Compute new dueAmount: add plan cost, subtract what was paid.
      const newDue = Math.max(0, (member.dueAmount ?? 0) + planCost - validated.amount);

      await Member.findByIdAndUpdate(validated.memberId, {
        planId: plan._id,
        planName: plan.name,
        membershipStart: renewFrom,
        membershipExpiry: renewedUntil,
        dueAmount: newDue,
      });

      // Append to Membership history.
      try {
        await Membership.create({
          gymId,
          memberId: validated.memberId,
          planId: plan._id,
          planName: plan.name,
          startDate: renewFrom,
          expiryDate: renewedUntil,
          paymentId: payment._id,
          amount: validated.amount,
          grantedBy: user.id,
        });
      } catch (membershipErr) {
        console.error("[payments] Failed to create Membership record:", membershipErr);
      }
    }
  } else if (member) {
    // ── Partial / non-plan payment: only reduce dueAmount ─────────────────
    const newDue = Math.max(0, (member.dueAmount ?? 0) - validated.amount);
    await Member.findByIdAndUpdate(validated.memberId, { dueAmount: newDue });
  }

  await ActivityLog.create({
    gymId,
    staffId: user.id,
    staffName: user.name || "Unknown",
    action: "created",
    entity: "payment",
    entityId: payment._id.toString(),
    details: renewedUntil
      ? `Recorded payment of ${payment.amount} for ${payment.memberName} (${invoiceNumber}). Membership renewed until ${renewedUntil.toDateString()}.`
      : `Recorded payment of ${payment.amount} for ${payment.memberName} (${invoiceNumber}).`,
  });

  return NextResponse.json({ ...payment.toObject(), renewedUntil }, { status: 201 });
});
