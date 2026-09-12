import { Member } from "../schemas";
import { Membership } from "../schemas";
import { Payment } from "../schemas";
import type { ClientSession } from "mongoose";

/**
 * Recompute a member's cached aggregates from their surviving records.
 *
 * This is the SINGLE writer of `Member.dueAmount` and the current membership
 * window (`planId`/`planName`/`membershipStart`/`membershipExpiry`). Call it
 * after any payment create/delete and after member onboarding — never patch
 * those fields by hand. Because it derives state from the surviving records
 * it is self-healing: voiding/refunding a Payment or reversing a Membership
 * and recomputing always lands the member in a correct state.
 *
 * Ledger:   dueAmount = max(0, Σ Membership.planPrice − Σ Payment.amount)
 * Window:   the surviving Membership with the latest expiryDate (or cleared).
 */
export async function recomputeMemberAggregates(
  gymId: string | object,
  memberId: string | object,
  session?: ClientSession
) {
  const [memberships, payments] = await Promise.all([
    Membership.find({ gymId, memberId, status: { $ne: "reversed" } }).session(session ?? null).lean(),
    Payment.find({ gymId, memberId, status: "paid" }).session(session ?? null).lean(),
  ]);

  const owed = memberships.reduce(
    (sum, m) => sum + (m.planPrice ?? m.amount ?? 0),
    0
  );
  const paid = payments.reduce((sum, p) => sum + (p.amount ?? 0), 0);
  const dueAmount = Math.max(0, owed - paid);

  // Current membership = the surviving period with the latest expiry.
  const latest = memberships.reduce<(typeof memberships)[number] | null>(
    (best, m) => (!best || m.expiryDate > best.expiryDate ? m : best),
    null
  );

  if (latest) {
    await Member.findOneAndUpdate(
      { _id: memberId, gymId },
      {
        dueAmount,
        planId: latest.planId,
        planName: latest.planName,
        membershipStart: latest.startDate,
        membershipExpiry: latest.expiryDate,
      },
      { session }
    );
  } else {
    await Member.findOneAndUpdate(
      { _id: memberId, gymId },
      {
        $set: { dueAmount },
        $unset: { planId: "", planName: "", membershipStart: "", membershipExpiry: "" },
      },
      { session }
    );
  }

  return { dueAmount, latestMembership: latest };
}
