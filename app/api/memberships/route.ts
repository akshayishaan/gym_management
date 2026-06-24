import { NextRequest, NextResponse } from "next/server";
import { apiHandler } from "@/lib/apiHandler";
import { getGymFilter } from "@/lib/withAuth";
import { SessionUser } from "@/lib/session";
import Membership from "@/models/Membership";

/**
 * GET /api/memberships?memberId=<id>
 *
 * Returns membership history for a member, newest period first.
 * Memberships are created server-side when a payment with a plan is recorded;
 * there is no client-facing POST.
 */
export const GET = apiHandler(async (req: NextRequest, user: SessionUser) => {
  const { searchParams } = new URL(req.url);
  const memberId = searchParams.get("memberId") || "";

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const query: any = { ...getGymFilter(user) };
  if (memberId) query.memberId = memberId;

  const memberships = await Membership.find(query)
    .sort({ expiryDate: -1 })
    .lean();

  return NextResponse.json({ memberships });
});
