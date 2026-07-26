import { NextRequest, NextResponse } from "next/server";
import { apiHandler } from "@/lib/apiHandler";
import { getGymFilter } from "@/lib/withAuth";
import { SessionUser } from "@/lib/session";
import Payment from "@/models/Payment";
import Membership from "@/models/Membership";
import Gym from "@/models/Gym";
import { paymentCreateSchema } from "@/lib/validators/payment";
import { recordPayment } from "@/lib/membershipLifecycle";
import { localDateTimeToInstant } from "@/lib/membershipCalendar";

export const GET = apiHandler(async (req: NextRequest, user: SessionUser) => {
  const { searchParams } = new URL(req.url);
  const memberId = searchParams.get("memberId") || "";
  const parsedPage = Number.parseInt(searchParams.get("page") || "1", 10);
  const parsedLimit = Number.parseInt(searchParams.get("limit") || "20", 10);
  const page = Number.isFinite(parsedPage) ? Math.max(1, parsedPage) : 1;
  const limit = Number.isFinite(parsedLimit) ? Math.min(100, Math.max(1, parsedLimit)) : 20;
  const month = searchParams.get("month") || "";
  const gymFilter = getGymFilter(user);
  const gym = await Gym.findById(gymFilter.gymId).select("timezone").lean();
  const timeZone = gym?.timezone || "Asia/Kolkata";
  const query: Record<string, unknown> = { ...gymFilter };
  const summaryFilter: Record<string, unknown> = { ...gymFilter };

  if (memberId) {
    query.memberId = memberId;
    summaryFilter.memberId = memberId;
  }
  if (month) {
    const [year, monthNumber] = month.split("-").map(Number);
    if (Number.isInteger(year) && monthNumber >= 1 && monthNumber <= 12) {
      const nextYear = monthNumber === 12 ? year + 1 : year;
      const nextMonth = monthNumber === 12 ? 1 : monthNumber + 1;
      const range = {
        $gte: localDateTimeToInstant(`${year}-${String(monthNumber).padStart(2, "0")}-01`, timeZone),
        $lt: localDateTimeToInstant(`${nextYear}-${String(nextMonth).padStart(2, "0")}-01`, timeZone),
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
    Payment.aggregate<{ total: number }>([
      {
        $match: {
          ...summaryFilter,
          status: "paid",
          ...(period && { paidAt: period }),
        },
      },
      { $group: { _id: null, total: { $sum: "$amount" } } },
    ]),
  ]);
  const memberships = await Membership.find({
    ...gymFilter,
    paymentId: { $in: payments.map((payment) => payment._id) },
  }).select("paymentId status").lean();
  const membershipByPayment = new Map(
    memberships.map((membership) => [membership.paymentId?.toString(), membership])
  );
  const items = payments.map((payment) => ({
    ...payment,
    membershipId: membershipByPayment.get(payment._id.toString())?._id.toString(),
    membershipStatus: membershipByPayment.get(payment._id.toString())?.status,
  }));

  return NextResponse.json({
    payments: items,
    total,
    page,
    limit,
    summary: { netAmount: collected[0]?.total || 0 },
  });
});

export const POST = apiHandler(async (req: NextRequest, user: SessionUser) => {
  const gymFilter = getGymFilter(user);
  const validated = paymentCreateSchema.parse(await req.json());
  const { requestId, memberId, planId, amount, method, membershipStart, notes } = validated;
  const result = await recordPayment({
    gymId: String(gymFilter.gymId),
    requestId,
    actor: { id: user.id, name: user.name },
    now: new Date(),
    memberId,
    planId,
    amount,
    method,
    membershipStart,
    notes,
  });
  const payment = result.paymentId
    ? await Payment.findOne({ _id: result.paymentId, ...gymFilter }).lean()
    : null;

  return NextResponse.json({ payment, ...result }, { status: 201 });
});
