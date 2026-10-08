import { Injectable } from "@nestjs/common";
import {
  ActivityLog,
  Gym,
  LifecycleMutation,
  Member,
  Membership,
  Payment,
  Plan,
  Staff,
} from "../schemas";
import { DomainError, ForbiddenError, withMongoTransaction } from "../common";
import { MongoConnectionService } from "../database";
import type { AuthenticatedUser } from "../auth";
import {
  gymCreateSchema,
  gymDeleteSchema,
  gymUpdateSchema,
  type GymCreateInput,
  type GymDeleteInput,
  type GymUpdateInput,
} from "./gym.schemas";

/**
 * Gym CRUD with 1:1 parity to the Next.js gym routes. Ownership is enforced by
 * checking the caller's `gymIds` (not a selected-gym context), because a
 * freshly-signed-up admin has an empty `gymIds` list and must be able to create
 * their first gym.
 */
@Injectable()
export class GymsService {
  constructor(private readonly connection: MongoConnectionService) {}

  async list(gymIds: string[]) {
    await this.connection.getConnection();
    return Gym.find({ _id: { $in: gymIds } }).sort({ createdAt: -1 }).lean();
  }

  async create(input: GymCreateInput, user: AuthenticatedUser) {
    await this.connection.getConnection();
    const validated = gymCreateSchema.parse(input);

    const gym = await Gym.create({ ...validated, ownerId: user.id });

    await Staff.findByIdAndUpdate(user.id, { $push: { gymIds: gym._id } });

    await ActivityLog.create({
      gymId: gym._id,
      staffId: user.id,
      staffName: user.name || "Admin",
      action: "created",
      entity: "gym",
      entityId: gym._id.toString(),
      details: `Created gym: ${gym.name}`,
    });

    return gym;
  }

  async getOne(id: string, gymIds: string[]) {
    await this.connection.getConnection();

    if (!gymIds.includes(id)) {
      throw new ForbiddenError("You can only view your own gyms");
    }

    const gym = await Gym.findById(id).lean();
    if (!gym) throw new DomainError("Not found", 404);

    return gym;
  }

  async update(
    id: string,
    input: GymUpdateInput,
    user: AuthenticatedUser,
    gymIds: string[],
  ) {
    await this.connection.getConnection();

    if (!gymIds.includes(id)) {
      throw new ForbiddenError("You can only update your own gyms");
    }

    const validated = gymUpdateSchema.parse(input);
    const gym = await Gym.findByIdAndUpdate(id, validated, { new: true });
    if (!gym) throw new DomainError("Not found", 404);

    await ActivityLog.create({
      gymId: id,
      staffId: user.id,
      staffName: user.name || "Unknown",
      action: "updated",
      entity: "gym",
      entityId: id,
      details: `Updated gym: ${gym.name}`,
    });

    return gym;
  }

  /** What deleting the Gym would erase, for the confirmation screen. */
  async deletionSummary(id: string, user: AuthenticatedUser) {
    await this.connection.getConnection();
    this.assertCanDelete(id, user);

    const gym = await Gym.findById(id).lean();
    if (!gym) throw new DomainError("Not found", 404);

    const [members, payments, plans, memberships, activity, staff] =
      await Promise.all([
        Member.countDocuments({ gymId: id }),
        Payment.countDocuments({ gymId: id }),
        Plan.countDocuments({ gymId: id }),
        Membership.countDocuments({ gymId: id }),
        ActivityLog.countDocuments({ gymId: id }),
        Staff.countDocuments({ gymIds: id }),
      ]);

    return {
      name: gym.name,
      members,
      payments,
      plans,
      memberships,
      activity,
      // Staff with access to this Gym, including the caller.
      staff,
    };
  }

  /**
   * Hard-deletes the Gym and everything scoped to it. Requires the Gym's
   * exact name and the caller's password, and runs as one transaction so the
   * cascade is all-or-nothing.
   */
  async remove(
    id: string,
    input: GymDeleteInput,
    user: AuthenticatedUser,
  ): Promise<{ success: boolean }> {
    await this.connection.getConnection();
    this.assertCanDelete(id, user);
    const { confirmName, password } = gymDeleteSchema.parse(input);

    const gym = await Gym.findById(id);
    if (!gym) throw new DomainError("Not found", 404);

    if (confirmName.trim() !== gym.name) {
      throw new DomainError("The name you typed does not match this gym");
    }

    const staff = await Staff.findById(user.id);
    if (!staff || !(await staff.comparePassword(password))) {
      // 400, not 401/403: the client treats those as an expired session.
      throw new DomainError("Incorrect password");
    }

    await withMongoTransaction(async (session) => {
      await Staff.updateMany(
        { gymIds: id },
        { $pull: { gymIds: id } },
        { session },
      );
      await Member.deleteMany({ gymId: id }, { session });
      await Payment.deleteMany({ gymId: id }, { session });
      await Plan.deleteMany({ gymId: id }, { session });
      await Membership.deleteMany({ gymId: id }, { session });
      await LifecycleMutation.deleteMany({ gymId: id }, { session });
      await ActivityLog.deleteMany({ gymId: id }, { session });
      await Gym.findByIdAndDelete(id, { session });
      return true;
    });

    return { success: true };
  }

  private assertCanDelete(id: string, user: AuthenticatedUser) {
    if (!user.gymIds.includes(id)) {
      throw new ForbiddenError("You can only delete your own gyms");
    }
    if (user.role !== "admin") {
      throw new ForbiddenError("Only admins can delete a gym");
    }
  }
}
