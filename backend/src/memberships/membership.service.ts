import { Injectable } from "@nestjs/common";
import type { Types } from "mongoose";
import { Membership } from "../schemas";
import { MongoConnectionService } from "../database";
import { CacheService } from "../cache";
import type { AuthenticatedUser } from "../auth";
import { reversePlanPurchase } from "../lib";
import { paymentActionSchema } from "../payments/payment.schemas";

/**
 * Membership history listing and plan-purchase reversal with 1:1 parity to the
 * Next.js membership routes. List is NOT paginated (matching the origin) and
 * is tenant-scoped by `gymId`; reversal delegates to `reversePlanPurchase`.
 */
@Injectable()
export class MembershipsService {
  constructor(
    private readonly connection: MongoConnectionService,
    private readonly cache: CacheService,
  ) {}

  async list(gymId: Types.ObjectId, memberId?: string) {
    await this.connection.getConnection();

    const query: Record<string, unknown> = { gymId };
    if (memberId) query.memberId = memberId;

    const memberships = await Membership.find(query).sort({ expiryDate: -1 }).lean();

    return { memberships };
  }

  async reverse(gymId: Types.ObjectId, user: AuthenticatedUser, id: string, body: unknown) {
    await this.connection.getConnection();

    const validated = paymentActionSchema.parse(body);

    const result = await reversePlanPurchase({
      gymId: String(gymId),
      requestId: validated.requestId,
      actor: { id: user.id, name: user.name },
      now: new Date(),
      membershipId: id,
      reason: validated.reason,
    });

    this.cache.scheduleInvalidation(String(gymId));

    return result;
  }
}
