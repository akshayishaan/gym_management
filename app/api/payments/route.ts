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

  // membershipStart is used to set the membership window — never stored on Payment.
  const { membershipStart, ...paymentFields } = validated;

  const member = await Member.findById(validated.memberId);
  if (!member) {
    return NextResponse.json({ error: "Member not found" }, { status: 404 });
  }

  const oldDue = member.dueAmount ?? 0;
  const now = new Date();

  // ── Resolve the plan (if any) and validate the amount against what's owed ──
  let plan = null;
  if (validated.planId) {
    plan = await Plan.findById(validated.planId);
    if (!plan) {
      return NextResponse.json({ error: "Plan not found" }, { status: 404 });
    }
    // Cap: a plan payment can settle the plan price + any pre-existing dues.
    if (validated.amount > plan.price + oldDue) {
      return NextResponse.json(
        { error: "Amount exceeds total owed (plan price + outstanding dues)." },
        { status: 400 }
      );
    }
  } else {
    // No plan = clearing dues. Block meaningless advance payments.
    if (oldDue <= 0) {
      return NextResponse.json(
        { error: "No outstanding dues. Select a plan to record a payment." },
        { status: 400 }
      );
    }
    if (validated.amount > oldDue) {
      return NextResponse.json(
        { error: "Amount exceeds outstanding dues." },
        { status: 400 }
      );
    }
  }

  const invoiceNumber = await generateInvoiceNumber();
  const payment = await Payment.create({
    ...paymentFields,
    gymId,
    invoiceNumber,
    createdBy: user.id,
  });

  let renewedUntil: Date | null = null;

  if (plan) {
    // ── Buy / renew a membership ────────────────────────────────────────────
    // Start from the explicit date if provided; otherwise stack from the
    // current expiry while the member is still active, else start today.
    const isActive = member.membershipExpiry && member.membershipExpiry > now;
    const renewFrom: Date = membershipStart
      ? new Date(membershipStart)
      : isActive
      ? member.membershipExpiry!
      : now;

    renewedUntil = new Date(renewFrom);
    renewedUntil.setDate(renewedUntil.getDate() + plan.durationDays);

    // New ledger balance: add the plan price, subtract what was just paid.
    const newDue = Math.max(0, oldDue + plan.price - validated.amount);

    await Member.findByIdAndUpdate(validated.memberId, {
      planId: plan._id,
      planName: plan.name,
      membershipStart: renewFrom,
      membershipExpiry: renewedUntil,
      dueAmount: newDue,
    });

    // Append to membership history.
    try {
      await Membership.create({
        gymId,
        memberId: validated.memberId,
        planId: plan._id,
        planName: plan.name,
        startDate: renewFrom,
        expiryDate: renewedUntil,
        paymentId: payment._id,
        planPrice: plan.price,
        amount: validated.amount,
        grantedBy: user.id,
      });
    } catch (membershipErr) {
      console.error("[payments] Failed to create Membership record:", membershipErr);
    }
  } else {
    // ── Clear dues only ─────────────────────────────────────────────────────
    const newDue = Math.max(0, oldDue - validated.amount);
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
      ? `Recorded payment of ${payment.amount} for ${payment.memberName} (${invoiceNumber}). Membership active until ${renewedUntil.toDateString()}.`
      : `Recorded payment of ${payment.amount} for ${payment.memberName} (${invoiceNumber}).`,
  });

  return NextResponse.json({ ...payment.toObject(), renewedUntil }, { status: 201 });
});
