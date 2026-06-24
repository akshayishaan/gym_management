import Member from "@/models/Member";
import Membership from "@/models/Membership";
import Payment from "@/models/Payment";

/**
 * Recompute a member's cached aggregates from their surviving records.
 *
 * This is the SINGLE writer of `Member.dueAmount` and the current membership
 * window (`planId`/`planName`/`membershipStart`/`membershipExpiry`). Call it
 * after any payment create/delete and after member onboarding — never patch
 * those fields by hand. Because it derives state from the surviving records
 * it is self-healing: deleting a payment (and its Membership) and recomputing
 * always lands the member in a correct state.
 *
 * Ledger:   dueAmount = max(0, Σ Membership.planPrice − Σ Payment.amount)
 * Window:   the surviving Membership with the latest expiryDate (or cleared).
 */
export async function recomputeMemberAggregates(memberId: string | object) {
  const [memberships, payments] = await Promise.all([
    Membership.find({ memberId }).lean(),
    Payment.find({ memberId }).lean(),
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
    await Member.findByIdAndUpdate(memberId, {
      dueAmount,
      planId: latest.planId,
      planName: latest.planName,
      membershipStart: latest.startDate,
      membershipExpiry: latest.expiryDate,
    });
  } else {
    await Member.findByIdAndUpdate(memberId, {
      $set: { dueAmount },
      $unset: { planId: "", planName: "", membershipStart: "", membershipExpiry: "" },
    });
  }
}
