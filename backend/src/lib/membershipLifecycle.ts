import type { ClientSession, HydratedDocument } from "mongoose";
import { ActivityLog } from "../schemas";
import { Gym } from "../schemas";
import { LifecycleMutation, type LifecycleOperation } from "../schemas";
import { Member, type IMember } from "../schemas";
import { Membership } from "../schemas";
import { Payment } from "../schemas";
import { Plan } from "../schemas";
import { DomainError } from "../common";
import {
  addCalendarDays,
  assertDateOnly,
  calculateMembershipExpiry,
  todayInTimeZone,
  type DateOnly,
} from "./membershipCalendar";
import { recomputeMemberAggregates } from "./memberLedger";
import { withMongoTransaction } from "../common";
import { generateInvoiceNumber } from "./utils";

type PaymentMethod = "cash" | "card" | "upi" | "bank_transfer" | "other";

interface Actor {
  id: string;
  name?: string | null;
}

interface MutationContext {
  gymId: string;
  requestId: string;
  actor: Actor;
  now: Date;
}

interface OnboardMemberInput extends MutationContext {
  member: {
    name: string;
    email?: string;
    phone: string;
    address?: string;
    photo?: string;
    dateOfBirth?: string;
    gender?: "male" | "female" | "other";
    notes?: string;
    emergencyContact?: string;
  };
  planId?: string;
  membershipStart?: string;
  amountPaid?: number;
  paymentMethod?: PaymentMethod;
}

interface RecordPaymentInput extends MutationContext {
  memberId: string;
  planId?: string;
  amount: number;
  method: PaymentMethod;
  membershipStart?: string;
  reference?: string;
  notes?: string;
}

interface PaymentActionInput extends MutationContext {
  paymentId: string;
  reason?: string;
}

interface ReversePlanPurchaseInput extends MutationContext {
  membershipId: string;
  reason?: string;
}

export interface LifecycleResult {
  memberId: string;
  paymentId?: string;
  membershipId?: string;
  renewedUntil?: DateOnly;
  dueAmount?: number;
}

function isDuplicateKey(error: unknown): boolean {
  return error instanceof Error
    && "code" in error
    && (error as Error & { code: number }).code === 11000;
}

async function runIdempotent(
  context: MutationContext,
  operation: LifecycleOperation,
  work: (session: ClientSession) => Promise<LifecycleResult>
): Promise<LifecycleResult> {
  const existing = await LifecycleMutation.findOne({
    gymId: context.gymId,
    requestId: context.requestId,
  }).lean();
  if (existing) {
    if (existing.operation !== operation) {
      throw new DomainError("This request ID was already used for another operation", 409);
    }
    return existing.result as unknown as LifecycleResult;
  }

  try {
    return await withMongoTransaction(async (session) => {
      await LifecycleMutation.create([{
        gymId: context.gymId,
        requestId: context.requestId,
        operation,
        result: {},
      }], { session });

      const result = await work(session);
      await LifecycleMutation.updateOne(
        { gymId: context.gymId, requestId: context.requestId },
        { result },
        { session }
      );
      return result;
    });
  } catch (error) {
    if (!isDuplicateKey(error)) throw error;
    const replay = await LifecycleMutation.findOne({
      gymId: context.gymId,
      requestId: context.requestId,
    }).lean();
    if (!replay || replay.operation !== operation) throw error;
    return replay.result as unknown as LifecycleResult;
  }
}

async function getGymTimeZone(gymId: string, session: ClientSession): Promise<string> {
  const gym = await Gym.findById(gymId).select("timezone").session(session).lean();
  if (!gym) throw new DomainError("Gym not found", 404);
  return gym.timezone || "Asia/Kolkata";
}

async function resolveActivePlan(gymId: string, planId: string, session: ClientSession) {
  const plan = await Plan.findOne({
    _id: planId,
    gymId,
    isActive: { $ne: false },
  }).session(session);
  if (!plan) throw new DomainError("Active plan not found", 404);
  return plan;
}

async function ensureNoMembershipOverlap(
  gymId: string,
  memberId: string,
  startDate: DateOnly,
  expiryDate: DateOnly,
  session: ClientSession
) {
  const overlap = await Membership.exists({
    gymId,
    memberId,
    status: { $ne: "reversed" },
    startDate: { $lte: expiryDate },
    expiryDate: { $gte: startDate },
  }).session(session);
  if (overlap) throw new DomainError("Membership periods cannot overlap", 409);
}

async function createPlanPurchase(
  input: {
    gymId: string;
    member: HydratedDocument<IMember>;
    planId: string;
    amount: number;
    method: PaymentMethod;
    membershipStart?: string;
    reference?: string;
    notes?: string;
    actor: Actor;
    now: Date;
  },
  session: ClientSession
): Promise<LifecycleResult> {
  const [plan, timeZone] = await Promise.all([
    resolveActivePlan(input.gymId, input.planId, session),
    getGymTimeZone(input.gymId, session),
  ]);

  if (input.amount < 0 || input.amount > plan.price) {
    throw new DomainError("Plan payments must be between zero and the plan price");
  }

  const today = todayInTimeZone(timeZone, input.now);
  const latest = await Membership.findOne({
    gymId: input.gymId,
    memberId: input.member._id,
    status: { $ne: "reversed" },
  }).sort({ expiryDate: -1 }).session(session).lean();
  const startDate = input.membershipStart
    ? assertDateOnly(input.membershipStart)
    : latest && latest.expiryDate >= today
      ? addCalendarDays(latest.expiryDate, 1)
      : today;
  const expiryDate = calculateMembershipExpiry(startDate, plan.durationDays);
  await ensureNoMembershipOverlap(
    input.gymId,
    input.member._id.toString(),
    startDate,
    expiryDate,
    session
  );

  let paymentId: string | undefined;
  if (input.amount > 0) {
    const invoiceNumber = await generateInvoiceNumber(session);
    const [payment] = await Payment.create([{
      gymId: input.gymId,
      memberId: input.member._id,
      memberName: input.member.name,
      planId: plan._id,
      planName: plan.name,
      planFeatures: plan.features,
      planDurationDays: plan.durationDays,
      amount: input.amount,
      kind: "plan_purchase",
      method: input.method,
      status: "paid",
      invoiceNumber,
      reference: input.reference,
      notes: input.notes,
      paidAt: input.now,
      createdBy: input.actor.id,
    }], { session });
    paymentId = payment._id.toString();
  }

  const [membership] = await Membership.create([{
    gymId: input.gymId,
    memberId: input.member._id,
    planId: plan._id,
    planName: plan.name,
    startDate,
    expiryDate,
    paymentId,
    planPrice: plan.price,
    amount: input.amount,
    grantedBy: input.actor.id,
    notes: input.notes,
    status: "active",
  }], { session });

  const aggregates = await recomputeMemberAggregates(
    input.gymId,
    input.member._id,
    session
  );
  return {
    memberId: input.member._id.toString(),
    paymentId,
    membershipId: membership._id.toString(),
    renewedUntil: expiryDate,
    dueAmount: aggregates.dueAmount,
  };
}

export async function onboardMember(input: OnboardMemberInput): Promise<LifecycleResult> {
  return runIdempotent(input, "member_onboarding", async (session) => {
    const [member] = await Member.create([{
      ...input.member,
      gymId: input.gymId,
      dueAmount: 0,
      isActive: true,
    }], { session });

    const purchase = input.planId
      ? await createPlanPurchase({
          gymId: input.gymId,
          member,
          planId: input.planId,
          amount: input.amountPaid ?? 0,
          method: input.paymentMethod ?? "cash",
          membershipStart: input.membershipStart,
          actor: input.actor,
          now: input.now,
        }, session)
      : { memberId: member._id.toString(), dueAmount: 0 };

    await ActivityLog.create([{
      gymId: input.gymId,
      staffId: input.actor.id,
      staffName: input.actor.name || "Unknown",
      action: "created",
      entity: "member",
      entityId: member._id.toString(),
      details: input.planId
        ? `Created member ${member.name} with an initial plan purchase.`
        : `Created member: ${member.name}`,
    }], { session });

    return purchase;
  });
}

export async function recordPayment(input: RecordPaymentInput): Promise<LifecycleResult> {
  return runIdempotent(input, "record_payment", async (session) => {
    const member = await Member.findOne({
      _id: input.memberId,
      gymId: input.gymId,
      isActive: { $ne: false },
    }).session(session);
    if (!member) throw new DomainError("Member not found", 404);

    let result: LifecycleResult;
    if (input.planId) {
      result = await createPlanPurchase({
        gymId: input.gymId,
        member,
        planId: input.planId,
        amount: input.amount,
        method: input.method,
        membershipStart: input.membershipStart,
        reference: input.reference,
        notes: input.notes,
        actor: input.actor,
        now: input.now,
      }, session);
    } else {
      if (input.amount <= 0) throw new DomainError("Dues payments must be greater than zero");
      if ((member.dueAmount ?? 0) <= 0) {
        throw new DomainError("No outstanding dues. Select a plan to record a purchase.");
      }
      if (input.amount > member.dueAmount) {
        throw new DomainError("Amount exceeds outstanding dues");
      }

      const invoiceNumber = await generateInvoiceNumber(session);
      const [payment] = await Payment.create([{
        gymId: input.gymId,
        memberId: member._id,
        memberName: member.name,
        amount: input.amount,
        kind: "dues",
        method: input.method,
        status: "paid",
        invoiceNumber,
        reference: input.reference,
        notes: input.notes,
        paidAt: input.now,
        createdBy: input.actor.id,
      }], { session });
      const aggregates = await recomputeMemberAggregates(input.gymId, member._id, session);
      result = {
        memberId: member._id.toString(),
        paymentId: payment._id.toString(),
        dueAmount: aggregates.dueAmount,
      };
    }

    await ActivityLog.create([{
      gymId: input.gymId,
      staffId: input.actor.id,
      staffName: input.actor.name || "Unknown",
      action: "created",
      entity: input.planId ? "membership" : "payment",
      entityId: result.membershipId || result.paymentId,
      details: input.planId
        ? `Recorded a plan purchase for ${member.name}${result.renewedUntil ? ` through ${result.renewedUntil}` : ""}.`
        : `Recorded a dues payment for ${member.name}.`,
    }], { session });

    return result;
  });
}

export async function voidPayment(input: PaymentActionInput): Promise<LifecycleResult> {
  return runIdempotent(input, "void_payment", async (session) => {
    const payment = await Payment.findOne({
      _id: input.paymentId,
      gymId: input.gymId,
    }).session(session);
    if (!payment) throw new DomainError("Payment not found", 404);
    if (payment.status !== "paid") throw new DomainError("Only paid payments can be voided", 409);

    payment.set({
      status: "voided",
      voidedAt: input.now,
      voidedBy: input.actor.id,
      voidReason: input.reason,
    });
    await payment.save({ session });
    const aggregates = await recomputeMemberAggregates(input.gymId, payment.memberId, session);

    await ActivityLog.create([{
      gymId: input.gymId,
      staffId: input.actor.id,
      staffName: input.actor.name || "Unknown",
      action: "voided",
      entity: "payment",
      entityId: payment._id.toString(),
      details: `Voided payment ${payment.invoiceNumber} for ${payment.memberName}.`,
    }], { session });

    return {
      memberId: payment.memberId.toString(),
      paymentId: payment._id.toString(),
      dueAmount: aggregates.dueAmount,
    };
  });
}

export async function refundPayment(input: PaymentActionInput): Promise<LifecycleResult> {
  return runIdempotent(input, "refund_payment", async (session) => {
    const payment = await Payment.findOne({
      _id: input.paymentId,
      gymId: input.gymId,
    }).session(session);
    if (!payment) throw new DomainError("Payment not found", 404);
    if (payment.status !== "paid") throw new DomainError("Only paid payments can be refunded", 409);

    payment.set({
      status: "refunded",
      refundedAt: input.now,
      refundedBy: input.actor.id,
      refundReason: input.reason,
    });
    await payment.save({ session });
    const aggregates = await recomputeMemberAggregates(input.gymId, payment.memberId, session);

    await ActivityLog.create([{
      gymId: input.gymId,
      staffId: input.actor.id,
      staffName: input.actor.name || "Unknown",
      action: "refunded",
      entity: "payment",
      entityId: payment._id.toString(),
      details: `Refunded payment ${payment.invoiceNumber} for ${payment.memberName}.`,
    }], { session });

    return {
      memberId: payment.memberId.toString(),
      paymentId: payment._id.toString(),
      dueAmount: aggregates.dueAmount,
    };
  });
}

export async function reversePlanPurchase(
  input: ReversePlanPurchaseInput
): Promise<LifecycleResult> {
  return runIdempotent(input, "reverse_plan_purchase", async (session) => {
    const membership = await Membership.findOne({
      _id: input.membershipId,
      gymId: input.gymId,
      status: { $ne: "reversed" },
    }).session(session);
    if (!membership) throw new DomainError("Active membership purchase not found", 404);

    const [laterMembership, laterDuesPayment] = await Promise.all([
      Membership.exists({
        gymId: input.gymId,
        memberId: membership.memberId,
        status: { $ne: "reversed" },
        $or: [
          { createdAt: { $gt: membership.createdAt } },
          { createdAt: membership.createdAt, _id: { $gt: membership._id } },
        ],
      }).session(session),
      Payment.exists({
        gymId: input.gymId,
        memberId: membership.memberId,
        kind: "dues",
        status: "paid",
        $or: [
          { createdAt: { $gt: membership.createdAt } },
          { createdAt: membership.createdAt, _id: { $gt: membership._id } },
        ],
      }).session(session),
    ]);
    if (laterMembership || laterDuesPayment) {
      throw new DomainError("Reverse newer membership transactions first", 409);
    }

    membership.set({
      status: "reversed",
      reversedAt: input.now,
      reversedBy: input.actor.id,
      reversalReason: input.reason,
    });
    await membership.save({ session });

    if (membership.paymentId) {
      const payment = await Payment.findOne({
        _id: membership.paymentId,
        gymId: input.gymId,
        memberId: membership.memberId,
        kind: "plan_purchase",
      }).session(session);
      if (!payment) {
        throw new DomainError("Associated plan purchase payment was not found", 409);
      }
      if (payment.status === "paid") {
        payment.set({
          status: "voided",
          voidedAt: input.now,
          voidedBy: input.actor.id,
          voidReason: input.reason || "Associated plan purchase was reversed",
        });
        await payment.save({ session });
      }
    }

    const aggregates = await recomputeMemberAggregates(
      input.gymId,
      membership.memberId,
      session
    );
    await ActivityLog.create([{
      gymId: input.gymId,
      staffId: input.actor.id,
      staffName: input.actor.name || "Unknown",
      action: "reversed",
      entity: "membership",
      entityId: membership._id.toString(),
      details: `Reversed ${membership.planName} plan purchase.`,
    }], { session });

    return {
      memberId: membership.memberId.toString(),
      membershipId: membership._id.toString(),
      paymentId: membership.paymentId?.toString(),
      dueAmount: aggregates.dueAmount,
    };
  });
}
