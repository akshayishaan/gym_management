import { Injectable } from "@nestjs/common";
import type { FilterQuery, Types } from "mongoose";
import { ActivityLog, Gym, Plan, type IPlan } from "../schemas";
import { DomainError } from "../common";
import { MongoConnectionService } from "../database";
import { CacheService, CACHE_TTL_SECONDS } from "../cache";
import type { AuthenticatedUser } from "../auth";
import {
  exactPlanNamePattern,
  getPlanPortfolioInsights,
  normalizePlanFeatures,
  partialPlanNamePattern,
} from "../lib";
import type { PlansResponse } from "../lib";
import { planCreateSchema, planUpdateSchema } from "./plan.schemas";

interface ListParams {
  search?: string;
  status?: string;
  page?: string;
  limit?: string;
  includeStats?: string;
}

/**
 * Plan CRUD with 1:1 parity to the Next.js plan routes. Every method
 * establishes the Mongo connection first (matching the gyms/members modules),
 * then runs tenant-scoped queries keyed on `gymId` (the `req.gymId` resolved
 * by `RequireGymGuard`).
 */
@Injectable()
export class PlansService {
  constructor(
    private readonly connection: MongoConnectionService,
    private readonly cache: CacheService,
  ) {}

  async list(gymId: Types.ObjectId, params: ListParams): Promise<PlansResponse> {
    await this.connection.getConnection();

    const parsedPage = Number.parseInt(params.page || "1", 10);
    const parsedLimit = Number.parseInt(params.limit || "50", 10);
    const page = Number.isFinite(parsedPage) ? Math.max(1, parsedPage) : 1;
    const limit = Number.isFinite(parsedLimit) ? Math.min(100, Math.max(1, parsedLimit)) : 50;
    const status = params.status || "all";
    const search = params.search?.trim() || "";
    const includeStats = params.includeStats !== "false";

    const query: FilterQuery<IPlan> = { gymId };
    if (status === "active") query.isActive = { $ne: false };
    if (status === "inactive") query.isActive = false;
    if (search) query.name = partialPlanNamePattern(search);

    const [total, activeCount, inactiveCount, plans] = await Promise.all([
      Plan.countDocuments(query),
      // Gym-wide counts for the list filter pills; unaffected by the
      // status/search filters above.
      Plan.countDocuments({ gymId, isActive: { $ne: false } }),
      Plan.countDocuments({ gymId, isActive: false }),
      Plan.find(query)
        .sort({ isActive: -1, price: 1 })
        .skip((page - 1) * limit)
        .limit(limit)
        .lean(),
    ]);

    const counts = {
      all: activeCount + inactiveCount,
      active: activeCount,
      inactive: inactiveCount,
    };

    const serializedPlans = plans.map((plan) => ({
      ...plan,
      _id: plan._id.toString(),
    }));

    if (!includeStats) {
      return { plans: serializedPlans, total, page, limit, counts };
    }

    const gym = await Gym.findById(gymId).select("timezone").lean();
    if (!gym) throw new DomainError("Gym not found", 404);

    const insights = await this.cache.getOrCompute(
      `cache:plans:${String(gymId)}`,
      CACHE_TTL_SECONDS.plans,
      () =>
        getPlanPortfolioInsights({
          gymId: String(gymId),
          timeZone: gym.timezone || "Asia/Kolkata",
          asOf: new Date(),
        }),
    );

    const enrichedPlans = serializedPlans.map((plan) => ({
      ...plan,
      stats: insights.byPlan[plan._id] ?? {
        activeMembers: 0,
        salesYtd: 0,
        revenueAtSaleYtd: 0,
        totalMemberships: 0,
      },
    }));

    return { plans: enrichedPlans, total, page, limit, counts, summary: insights.summary };
  }

  async create(user: AuthenticatedUser, gymId: Types.ObjectId, body: unknown): Promise<IPlan> {
    await this.connection.getConnection();

    const validated = planCreateSchema.parse(body);

    const duplicate = await Plan.exists({
      gymId,
      name: exactPlanNamePattern(validated.name),
    });
    if (duplicate) {
      throw new DomainError("A plan with this name already exists", 409);
    }

    const plan = await Plan.create({
      ...validated,
      features: normalizePlanFeatures(validated.features),
      gymId,
    });

    await ActivityLog.create({
      gymId,
      staffId: user.id,
      staffName: user.name || "Unknown",
      action: "created",
      entity: "plan",
      entityId: plan._id.toString(),
      details: `Created plan: ${plan.name}`,
    });

    this.cache.scheduleInvalidation(String(gymId));

    return plan;
  }

  async update(user: AuthenticatedUser, gymId: Types.ObjectId, id: string, body: unknown): Promise<IPlan> {
    await this.connection.getConnection();

    const validated = planUpdateSchema.parse(body);

    if (validated.name) {
      const duplicate = await Plan.exists({
        gymId,
        _id: { $ne: id },
        name: exactPlanNamePattern(validated.name),
      });
      if (duplicate) {
        throw new DomainError("A plan with this name already exists", 409);
      }
    }

    const update = {
      ...validated,
      ...(validated.features && { features: normalizePlanFeatures(validated.features) }),
    };

    const plan = await Plan.findOneAndUpdate({ _id: id, gymId }, update, { new: true });
    if (!plan) throw new DomainError("Not found", 404);

    await ActivityLog.create({
      gymId,
      staffId: user.id,
      staffName: user.name || "Unknown",
      action: "updated",
      entity: "plan",
      entityId: id,
      details: validated.isActive === false
        ? `Deactivated plan: ${plan.name}`
        : validated.isActive === true
        ? `Activated plan: ${plan.name}`
        : `Updated plan: ${plan.name}`,
    });

    this.cache.scheduleInvalidation(String(gymId));

    return plan;
  }
}
