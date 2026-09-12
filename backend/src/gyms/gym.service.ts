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
import { DomainError, ForbiddenError } from "../common";
import { MongoConnectionService } from "../database";
import type { AuthenticatedUser } from "../auth";
import {
  gymCreateSchema,
  gymUpdateSchema,
  type GymCreateInput,
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

  async remove(id: string, gymIds: string[]): Promise<{ success: boolean }> {
    await this.connection.getConnection();

    if (!gymIds.includes(id)) {
      throw new ForbiddenError("You can only delete your own gyms");
    }

    const gym = await Gym.findById(id);
    if (!gym) throw new DomainError("Not found", 404);

    await Staff.updateMany({ gymIds: id }, { $pull: { gymIds: id } });
    await Member.deleteMany({ gymId: id });
    await Payment.deleteMany({ gymId: id });
    await Plan.deleteMany({ gymId: id });
    await Membership.deleteMany({ gymId: id });
    await LifecycleMutation.deleteMany({ gymId: id });
    await ActivityLog.deleteMany({ gymId: id });
    await Gym.findByIdAndDelete(id);

    return { success: true };
  }
}
