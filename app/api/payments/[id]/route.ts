import { NextResponse } from "next/server";
import { apiHandlerWithParams } from "@/lib/apiHandler";
import { getGymFilter } from "@/lib/withAuth";
import Payment from "@/models/Payment";

export const GET = apiHandlerWithParams<{ id: string }>(
  async (_req, user, { id }) => {
    const payment = await Payment.findOne({ _id: id, ...getGymFilter(user) }).lean();
    if (!payment) return NextResponse.json({ error: "Not found" }, { status: 404 });
    return NextResponse.json(payment);
  }
);

export const DELETE = apiHandlerWithParams<{ id: string }>(
  async () => NextResponse.json(
    { error: "Payments are audit records. Use void payment or reverse plan purchase." },
    { status: 405 }
  )
);
