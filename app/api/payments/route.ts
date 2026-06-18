import { NextRequest, NextResponse } from "next/server";
import { apiHandler } from "@/lib/apiHandler";
import { requireNotSuperAdmin, getGymFilter } from "@/lib/withAuth";
import { SessionUser } from "@/lib/session";
import Payment from "@/models/Payment";
import ActivityLog from "@/models/ActivityLog";
import { paymentCreateSchema } from "@/lib/validators/payment";
import { generateInvoiceNumber } from "@/lib/utils";

export const GET = apiHandler(async (req: NextRequest, user: SessionUser) => {
  const { searchParams } = new URL(req.url);
  const memberId = searchParams.get("memberId") || "";
  const page = parseInt(searchParams.get("page") || "1");
  const limit = parseInt(searchParams.get("limit") || "20");
  const month = searchParams.get("month") || "";
  const gymIdParam = searchParams.get("gymId");

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const query: any = { ...getGymFilter(user, gymIdParam) };

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
  requireNotSuperAdmin(user);

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

  await ActivityLog.create({
    gymId,
    staffId: user.id,
    staffName: user.name || "Unknown",
    action: "created",
    entity: "payment",
    entityId: payment._id.toString(),
    details: `Recorded payment of ₹${payment.amount} for ${payment.memberName} (${invoiceNumber})`,
  });

  return NextResponse.json(payment, { status: 201 });
});
