import { NextResponse } from "next/server";
import { apiHandlerWithParams } from "@/lib/apiHandler";
import { getGymFilter } from "@/lib/withAuth";
import { paymentActionSchema } from "@/lib/validators/payment";
import { reversePlanPurchase } from "@/lib/membershipLifecycle";

export const POST = apiHandlerWithParams<{ id: string }>(async (req, user, { id }) => {
  const validated = paymentActionSchema.parse(await req.json());
  const result = await reversePlanPurchase({
    gymId: String(getGymFilter(user).gymId),
    requestId: validated.requestId,
    actor: { id: user.id, name: user.name },
    now: new Date(),
    membershipId: id,
    reason: validated.reason,
  });
  return NextResponse.json(result);
});
