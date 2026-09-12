import { Injectable } from "@nestjs/common";
import type { Types } from "mongoose";
import { ActivityLog } from "../schemas";
import { MongoConnectionService } from "../database";

/**
 * Tenant-scoped activity log listing. The response key is `logs` (parity with
 * the Next.js `app/api/activity` route). Unlike the members/plans lists, the
 * page/limit params are coarsed with a bare `parseInt` (no finite/clamp checks).
 */
@Injectable()
export class ActivityService {
  constructor(private readonly connection: MongoConnectionService) {}

  async list(gymId: Types.ObjectId, pageRaw?: string, limitRaw?: string) {
    await this.connection.getConnection();

    const page = parseInt(pageRaw || "1", 10);
    const limit = parseInt(limitRaw || "50", 10);

    const query = { gymId };

    const total = await ActivityLog.countDocuments(query);
    const logs = await ActivityLog.find(query)
      .sort({ createdAt: -1 })
      .skip((page - 1) * limit)
      .limit(limit)
      .lean();

    return { logs, total, page, limit };
  }
}
