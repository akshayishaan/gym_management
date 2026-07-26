import mongoose from "mongoose";
import type { AnyBulkWriteOperation, Document, ObjectId } from "mongodb";
import ActivityLog from "../models/ActivityLog";
import { isDateOnly, isValidTimeZone, toDateOnly } from "../lib/membershipCalendar";
import { recomputeMemberAggregates } from "../lib/memberLedger";

const DEFAULT_TIMEZONE = "Asia/Kolkata";
const MONGODB_URI = process.env.MONGODB_URI
  || "mongodb://localhost:27017/gym_management?replicaSet=rs0&directConnection=true";
const shouldApply = process.argv.includes("--apply");
const migrationStartedAt = new Date();

interface RawGym extends Document {
  _id: ObjectId;
  timezone?: unknown;
}

interface RawMembership extends Document {
  _id: ObjectId;
  gymId?: ObjectId;
  paymentId?: ObjectId;
  startDate?: unknown;
  expiryDate?: unknown;
  status?: unknown;
}

interface RawMember extends Document {
  _id: ObjectId;
  gymId?: ObjectId;
  membershipStart?: unknown;
  membershipExpiry?: unknown;
}

interface RawPayment extends Document {
  _id: ObjectId;
  gymId?: ObjectId;
  planId?: ObjectId;
  planName?: unknown;
  kind?: unknown;
  status?: unknown;
  paidAt?: unknown;
  voidedAt?: unknown;
  voidReason?: unknown;
  refundedAt?: unknown;
  createdAt?: unknown;
  updatedAt?: unknown;
}

interface MigrationCounts {
  gyms: number;
  memberships: number;
  members: number;
  payments: number;
  ledgers: number;
  skippedDates: number;
}

function incrementGymCount(counts: Map<string, number>, gymId?: ObjectId) {
  if (!gymId) return;
  const key = gymId.toString();
  counts.set(key, (counts.get(key) || 0) + 1);
}

function fallbackTimestamp(payment: RawPayment): Date {
  for (const value of [payment.updatedAt, payment.paidAt, payment.createdAt]) {
    if (value instanceof Date && !Number.isNaN(value.getTime())) return value;
    if (typeof value === "string") {
      const parsed = new Date(value);
      if (!Number.isNaN(parsed.getTime())) return parsed;
    }
  }
  return migrationStartedAt;
}

function migrateDateValue(value: unknown, timeZone: string): string | null {
  if (typeof value === "string" && isDateOnly(value)) return value;
  if (!(value instanceof Date) && typeof value !== "string") return null;

  try {
    return toDateOnly(value, timeZone);
  } catch {
    return null;
  }
}

async function migrate() {
  await mongoose.connect(MONGODB_URI, { bufferCommands: false });
  const db = mongoose.connection.db;
  if (!db) throw new Error("MongoDB connection did not expose a database");

  const counts: MigrationCounts = {
    gyms: 0,
    memberships: 0,
    members: 0,
    payments: 0,
    ledgers: 0,
    skippedDates: 0,
  };
  const changesByGym = new Map<string, number>();
  const gymTimezones = new Map<string, string>();

  const gyms = db.collection<RawGym>("gyms");
  const gymOperations: AnyBulkWriteOperation<RawGym>[] = [];
  for await (const gym of gyms.find({})) {
    const timezone = typeof gym.timezone === "string" && isValidTimeZone(gym.timezone)
      ? gym.timezone
      : DEFAULT_TIMEZONE;
    gymTimezones.set(gym._id.toString(), timezone);
    if (gym.timezone !== timezone) {
      gymOperations.push({
        updateOne: { filter: { _id: gym._id }, update: { $set: { timezone } } },
      });
      counts.gyms += 1;
      incrementGymCount(changesByGym, gym._id);
    }
  }
  if (shouldApply && gymOperations.length > 0) await gyms.bulkWrite(gymOperations);

  const memberships = db.collection<RawMembership>("memberships");
  const membershipOperations: AnyBulkWriteOperation<RawMembership>[] = [];
  const planPurchasePaymentIds = new Set<string>();
  for await (const membership of memberships.find({})) {
    if (membership.paymentId) planPurchasePaymentIds.add(membership.paymentId.toString());

    const timezone = membership.gymId
      ? gymTimezones.get(membership.gymId.toString()) || DEFAULT_TIMEZONE
      : DEFAULT_TIMEZONE;
    const set: Record<string, unknown> = {};

    for (const field of ["startDate", "expiryDate"] as const) {
      const current = membership[field];
      if (current == null || (typeof current === "string" && isDateOnly(current))) continue;
      const migrated = migrateDateValue(current, timezone);
      if (migrated) set[field] = migrated;
      else {
        counts.skippedDates += 1;
        console.warn(`Skipped invalid memberships.${field} on ${membership._id.toString()}`);
      }
    }
    if (membership.status !== "active" && membership.status !== "reversed") {
      set.status = "active";
    }

    if (Object.keys(set).length > 0) {
      membershipOperations.push({
        updateOne: { filter: { _id: membership._id }, update: { $set: set } },
      });
      counts.memberships += 1;
      incrementGymCount(changesByGym, membership.gymId);
    }
  }
  if (shouldApply && membershipOperations.length > 0) {
    await memberships.bulkWrite(membershipOperations);
  }

  const members = db.collection<RawMember>("members");
  const memberOperations: AnyBulkWriteOperation<RawMember>[] = [];
  for await (const member of members.find({})) {
    const timezone = member.gymId
      ? gymTimezones.get(member.gymId.toString()) || DEFAULT_TIMEZONE
      : DEFAULT_TIMEZONE;
    const set: Record<string, unknown> = {};

    for (const field of ["membershipStart", "membershipExpiry"] as const) {
      const current = member[field];
      if (current == null || (typeof current === "string" && isDateOnly(current))) continue;
      const migrated = migrateDateValue(current, timezone);
      if (migrated) set[field] = migrated;
      else {
        counts.skippedDates += 1;
        console.warn(`Skipped invalid members.${field} on ${member._id.toString()}`);
      }
    }

    if (Object.keys(set).length > 0) {
      memberOperations.push({
        updateOne: { filter: { _id: member._id }, update: { $set: set } },
      });
      counts.members += 1;
      incrementGymCount(changesByGym, member.gymId);
    }
  }
  if (shouldApply && memberOperations.length > 0) await members.bulkWrite(memberOperations);

  const payments = db.collection<RawPayment>("payments");
  const paymentOperations: AnyBulkWriteOperation<RawPayment>[] = [];
  for await (const payment of payments.find({})) {
    const set: Record<string, unknown> = {};

    if (payment.kind !== "plan_purchase" && payment.kind !== "dues") {
      set.kind = planPurchasePaymentIds.has(payment._id.toString())
        || !!payment.planId
        || (typeof payment.planName === "string" && payment.planName.trim() !== "")
        ? "plan_purchase"
        : "dues";
    }

    if (payment.status === "pending") {
      set.status = "voided";
      if (!(payment.voidedAt instanceof Date)) set.voidedAt = fallbackTimestamp(payment);
      if (typeof payment.voidReason !== "string" || payment.voidReason.trim() === "") {
        set.voidReason = "Legacy pending payment migrated to voided";
      }
    } else if (payment.status !== "paid"
      && payment.status !== "voided"
      && payment.status !== "refunded") {
      set.status = "paid";
    }

    const finalStatus = set.status || payment.status;
    if (finalStatus === "voided" && !(payment.voidedAt instanceof Date) && !set.voidedAt) {
      set.voidedAt = fallbackTimestamp(payment);
    }
    if (finalStatus === "refunded" && !(payment.refundedAt instanceof Date)) {
      set.refundedAt = fallbackTimestamp(payment);
    }

    if (Object.keys(set).length > 0) {
      paymentOperations.push({
        updateOne: { filter: { _id: payment._id }, update: { $set: set } },
      });
      counts.payments += 1;
      incrementGymCount(changesByGym, payment.gymId);
    }
  }
  if (shouldApply && paymentOperations.length > 0) await payments.bulkWrite(paymentOperations);

  if (shouldApply) {
    const ledgerBatch: Array<Promise<unknown>> = [];
    for await (const member of members.find({ gymId: { $exists: true } }, { projection: { gymId: 1 } })) {
      if (!member.gymId) continue;
      ledgerBatch.push(recomputeMemberAggregates(member.gymId, member._id));
      counts.ledgers += 1;
      if (ledgerBatch.length === 20) {
        await Promise.all(ledgerBatch);
        ledgerBatch.length = 0;
      }
    }
    if (ledgerBatch.length > 0) await Promise.all(ledgerBatch);

    const activityEntries = Array.from(changesByGym.entries()).map(([gymId, changed]) => ({
      gymId,
      staffName: "System migration",
      action: "migrated",
      entity: "gym",
      entityId: gymId,
      details: `Migrated ${changed} lifecycle record${changed === 1 ? "" : "s"} to calendar dates and auditable payment states.`,
    }));
    if (activityEntries.length > 0) await ActivityLog.insertMany(activityEntries);
  }

  console.log(shouldApply ? "Lifecycle migration applied." : "Lifecycle migration dry run complete.");
  console.table(counts);
  if (!shouldApply) {
    console.log("Run `npm run migrate:lifecycle -- --apply` to apply these changes.");
  }
}

migrate()
  .catch((error) => {
    console.error("Lifecycle migration failed:", error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await mongoose.disconnect();
  });
