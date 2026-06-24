import { NextRequest, NextResponse } from "next/server";
import { apiHandler } from "@/lib/apiHandler";
import { getGymFilter } from "@/lib/withAuth";
import { SessionUser } from "@/lib/session";
import Member from "@/models/Member";
import Plan, { IPlan } from "@/models/Plan";
import Payment from "@/models/Payment";
import Membership from "@/models/Membership";
import ActivityLog from "@/models/ActivityLog";
import { memberCreateSchema } from "@/lib/validators/member";
import { generateInvoiceNumber } from "@/lib/utils";
import { recomputeMemberAggregates } from "@/lib/memberLedger";

export const GET = apiHandler(async (req: NextRequest, user: SessionUser) => {
  const { searchParams } = new URL(req.url);
  const search = searchParams.get("search") || "";
  const status = searchParams.get("status") || "";
  const page = parseInt(searchParams.get("page") || "1");
  const limit = parseInt(searchParams.get("limit") || "20");
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  // isActive: { $ne: false } treats legacy members (no flag) as active and only
  // hides the explicitly soft-deleted ones.
  const query: any = { ...getGymFilter(user), isActive: { $ne: false } };

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
  const gymId = user.selectedGymId!;
  const body = await req.json();

  // Strip onboarding payment fields before schema parse so they flow through
  const { amountPaid, paymentMethod, ...rest } = body;
  const validated = memberCreateSchema.parse({ ...rest, amountPaid, paymentMethod });

  // ── Build member document ──────────────────────────────────────────────────
  // membershipExpiry is ALWAYS server-computed from plan.durationDays.
  // The client may supply membershipStart; we fall back to today.
  let memberDoc: Record<string, unknown> = {
    name: validated.name,
    email: validated.email,
    phone: validated.phone,
    address: validated.address,
    photo: validated.photo,
    dateOfBirth: validated.dateOfBirth,
    gender: validated.gender,
    notes: validated.notes,
    emergencyContact: validated.emergencyContact,
    gymId,
    dueAmount: 0,
  };

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  let createdPayment: any = null;
  let membershipStart: Date | null = null;
  let membershipExpiry: Date | null = null;
  let planDoc: (IPlan & { _id: unknown }) | null = null;

  if (validated.planId) {
    planDoc = await Plan.findById(validated.planId).lean() as (IPlan & { _id: unknown }) | null;

    if (planDoc) {
      // Compute dates server-side — never trust client-supplied membershipExpiry
      membershipStart = validated.membershipStart
        ? new Date(validated.membershipStart)
        : new Date();
      membershipExpiry = new Date(membershipStart);
      membershipExpiry.setDate(membershipExpiry.getDate() + planDoc.durationDays);

      const paid = typeof validated.amountPaid === "number" ? validated.amountPaid : 0;
      const dueAmount = Math.max(0, planDoc.price - paid);

      memberDoc = {
        ...memberDoc,
        planId: planDoc._id,
        planName: planDoc.name,
        membershipStart,
        membershipExpiry,
        dueAmount,
      };
    }
  }

  const member = await Member.create(memberDoc);

  // ── Create Payment + Membership records when a plan is assigned ───────────
  if (planDoc && membershipStart && membershipExpiry) {
    const paid = typeof validated.amountPaid === "number" ? validated.amountPaid : 0;

    if (paid > 0) {
      const invoiceNumber = await generateInvoiceNumber();
      const payment = await Payment.create({
        gymId,
        memberId: member._id,
        memberName: member.name,
        planId: planDoc._id,
        planName: planDoc.name,
        amount: paid,
        method: validated.paymentMethod ?? "cash",
        status: "paid",
        paidAt: membershipStart,
        invoiceNumber,
        createdBy: user.id,
      });
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      createdPayment = payment.toObject() as any;
    }

    // Membership history record — always created when a plan is assigned,
    // even if no payment was made (allows comp/zero-cost onboarding).
    try {
      await Membership.create({
        gymId,
        memberId: member._id,
        planId: planDoc._id,
        planName: planDoc.name,
        startDate: membershipStart,
        expiryDate: membershipExpiry,
        paymentId: createdPayment ? (createdPayment._id as string) : undefined,
        planPrice: planDoc.price,
        amount: typeof validated.amountPaid === "number" ? validated.amountPaid : undefined,
        grantedBy: user.id,
      });
    } catch (err) {
      console.error("[members] Failed to create Membership record:", err);
    }

    // Single writer of dueAmount + membership window.
    await recomputeMemberAggregates(member._id);
  }

  // ── Activity log ──────────────────────────────────────────────────────────
  const details = planDoc
    ? `Created member: ${member.name}` +
      ` — Plan: ${planDoc.name}` +
      (membershipExpiry ? `, expires ${membershipExpiry.toDateString()}` : "") +
      (member.dueAmount > 0 ? `, due: ${member.dueAmount}` : "")
    : `Created member: ${member.name}`;

  await ActivityLog.create({
    gymId,
    staffId: user.id,
    staffName: user.name || "Unknown",
    action: "created",
    entity: "member",
    entityId: member._id.toString(),
    details,
  });

  return NextResponse.json(
    { member: member.toObject(), payment: createdPayment },
    { status: 201 }
  );
});
