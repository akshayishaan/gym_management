import { Injectable } from "@nestjs/common";
import type { Types } from "mongoose";
import { Gym, Membership, Payment } from "../schemas";
import { DomainError } from "../common";
import { MongoConnectionService } from "../database";
import { CacheService } from "../cache";
import type { AuthenticatedUser } from "../auth";
import { localDateTimeToInstant, recordPayment, refundPayment, voidPayment } from "../lib";
import { paymentActionSchema, paymentCreateSchema } from "./payment.schemas";

interface ListParams {
  memberId?: string;
  month?: string;
  page?: string;
  limit?: string;
}

/**
 * Payment listing and lifecycle recording with 1:1 parity to the Next.js
 * payment routes. Read/list endpoints are tenant-scoped queries keyed on
 * `gymId`; mutations delegate to the centralized `lib/membershipLifecycle.ts`
 * so accounting effects are idempotent and transactional.
 */
@Injectable()
export class PaymentsService {
  constructor(
    private readonly connection: MongoConnectionService,
    private readonly cache: CacheService,
  ) {}

  async list(gymId: Types.ObjectId, params: ListParams): Promise<Record<string, unknown>> {
    await this.connection.getConnection();

    const memberId = (params.memberId || "").trim();
    const parsedPage = Number.parseInt(params.page || "1", 10);
    const parsedLimit = Number.parseInt(params.limit || "20", 10);
    const page = Number.isFinite(parsedPage) ? Math.max(1, parsedPage) : 1;
    const limit = Number.isFinite(parsedLimit) ? Math.min(100, Math.max(1, parsedLimit)) : 20;
    const month = params.month || "";

    const gym = await Gym.findById(gymId).select("timezone").lean();
    const timeZone = gym?.timezone || "Asia/Kolkata";

    const query: Record<string, unknown> = { gymId };
    const summaryFilter: Record<string, unknown> = { gymId };

    if (memberId) {
      query.memberId = memberId;
      summaryFilter.memberId = memberId;
    }

    if (month) {
      const [year, monthNumber] = month.split("-").map(Number);
      if (Number.isInteger(year) && monthNumber >= 1 && monthNumber <= 12) {
        const nextYear = monthNumber === 12 ? year + 1 : year;
        const nextMonth = monthNumber === 12 ? 1 : monthNumber + 1;
        const pad = (n: number) => String(n).padStart(2, "0");
        const range = {
          $gte: localDateTimeToInstant(`${year}-${pad(monthNumber)}-01`, timeZone),
          $lt: localDateTimeToInstant(`${nextYear}-${pad(nextMonth)}-01`, timeZone),
        };
        query.paidAt = range;
        summaryFilter.period = range;
      }
    }

    const period = summaryFilter.period as { $gte: Date; $lt: Date } | undefined;
    delete summaryFilter.period;

    const [total, payments, collected] = await Promise.all([
      Payment.countDocuments(query),
      Payment.find(query)
        .sort({ paidAt: -1 })
        .skip((page - 1) * limit)
        .limit(limit)
        .lean(),
      Payment.aggregate([
        {
          $match: {
            ...summaryFilter,
            status: "paid",
            ...(period ? { paidAt: period } : {}),
          },
        },
        { $group: { _id: null, total: { $sum: "$amount" } } },
      ]),
    ]);

    const memberships = await Membership.find({
      gymId,
      paymentId: { $in: payments.map((payment) => payment._id) },
    })
      .select("paymentId status")
      .lean();

    const membershipByPayment = new Map(
      memberships.map((membership) => [membership.paymentId?.toString(), membership]),
    );

    const items = payments.map((payment) => {
      const membership = membershipByPayment.get(payment._id.toString());
      return {
        ...payment,
        membershipId: membership?._id.toString(),
        membershipStatus: membership?.status,
      };
    });

    return {
      payments: items,
      total,
      page,
      limit,
      summary: { netAmount: collected[0]?.total || 0 },
    };
  }

  async create(user: AuthenticatedUser, gymId: Types.ObjectId, body: unknown) {
    await this.connection.getConnection();

    const validated = paymentCreateSchema.parse(body);
    const { requestId, memberId, planId, amount, method, membershipStart, reference, notes } =
      validated;

    const result = await recordPayment({
      gymId: String(gymId),
      requestId,
      actor: { id: user.id, name: user.name },
      now: new Date(),
      memberId,
      planId,
      amount,
      method,
      membershipStart,
      reference,
      notes,
    });

    const payment = result.paymentId
      ? await Payment.findOne({ _id: result.paymentId, gymId }).lean()
      : null;

    this.cache.scheduleInvalidation(String(gymId));

    return { payment, ...result };
  }

  async getOne(gymId: Types.ObjectId, id: string) {
    await this.connection.getConnection();

    const payment = await Payment.findOne({ _id: id, gymId }).lean();
    if (!payment) throw new DomainError("Not found", 404);

    return payment;
  }

  deleteOne(): never {
    throw new DomainError("Payments are audit records. Use void payment or reverse plan purchase.", 405);
  }

  async void(gymId: Types.ObjectId, user: AuthenticatedUser, id: string, body: unknown) {
    await this.connection.getConnection();

    const validated = paymentActionSchema.parse(body);

    const result = await voidPayment({
      gymId: String(gymId),
      requestId: validated.requestId,
      actor: { id: user.id, name: user.name },
      now: new Date(),
      paymentId: id,
      reason: validated.reason,
    });

    this.cache.scheduleInvalidation(String(gymId));

    return result;
  }

  async refund(gymId: Types.ObjectId, user: AuthenticatedUser, id: string, body: unknown) {
    await this.connection.getConnection();

    const validated = paymentActionSchema.parse(body);

    const result = await refundPayment({
      gymId: String(gymId),
      requestId: validated.requestId,
      actor: { id: user.id, name: user.name },
      now: new Date(),
      paymentId: id,
      reason: validated.reason,
    });

    this.cache.scheduleInvalidation(String(gymId));

    return result;
  }
}
