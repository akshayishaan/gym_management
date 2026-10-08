import { extendZodWithOpenApi } from "@asteasolutions/zod-to-openapi";
import { z } from "zod";

// The refId'd copies below call `.openapi(...)` at module-evaluation time, so
// the zod extension must exist before any schema is built. The export script
// (`scripts/export-openapi.ts`) loads this module without `zod-openapi.setup.ts`,
// hence the defensive call here (idempotent — a no-op if already extended).
extendZodWithOpenApi(z);

/**
 * Response-body Zod schemas for the OpenAPI document.
 *
 * These describe what the API serializes back to the client (JSON) so the
 * generated Dart client is fully typed. They are contract/documentation only —
 * they do NOT participate in runtime validation (NestJS serializes controller
 * return values directly; the `HttpExceptionFilter` handles error bodies).
 *
 * Field conventions, mirroring how Mongoose `.lean()` / documents + `JSON.stringify` behave:
 * - Mongo ObjectIds (`_id`, `gymId`, `memberId`, …) → `z.string()`
 * - `Date` fields (`createdAt`, `paidAt`, `dateOfBirth`, …) → ISO 8601 `z.string()`
 * - Calendar-only strings (`membershipStart`, `membershipExpiry`, `renewedUntil`,
 *   `startDate`, `expiryDate`) → `YYYY-MM-DD` `z.string()`
 * - Unset optional fields are omitted from JSON (not null) → `.optional()`
 * - Explicitly-nullable fields (`payment` on create) → `.nullable()`
 */

const objectId = z.string().describe("Mongo ObjectId serialized as a string");
const isoDate = z.string().describe("ISO 8601 date-time string");
const dateOnly = z.string().describe("Calendar date in YYYY-MM-DD format");

const genderEnum = z.enum(["male", "female", "other"]);
const paymentMethodEnum = z.enum(["cash", "card", "upi", "bank_transfer", "other"]);
const paymentKindEnum = z.enum(["plan_purchase", "dues"]);
const paymentStatusEnum = z.enum(["paid", "voided", "refunded"]);
const membershipStatusEnum = z.enum(["active", "reversed"]);
const memberDisplayStatusEnum = z.enum(["active", "expiring", "expired"]);
const memberDisplayStatusRef = memberDisplayStatusEnum.openapi("MemberDisplayStatus");

// --- Common ---

export const errorResponseSchema = z.object({
  error: z.string(),
  details: z.unknown().optional(),
});

export const successResponseSchema = z.object({
  success: z.boolean(),
});

// --- Auth ---

export const authSessionResponseSchema = z.object({
  accessToken: z.string(),
  refreshToken: z.string(),
  user: z.object({
    id: z.string(),
    name: z.string(),
    email: z.string(),
    role: z.string(),
    gymIds: z.array(z.string()),
  }),
});

export const signupResponseSchema = z.object({
  message: z.string(),
});

// --- Gym ---

export const gymResponseSchema = z.object({
  _id: objectId,
  name: z.string(),
  logo: z.string().optional(),
  primaryColor: z.string(),
  address: z.string().optional(),
  phone: z.string().optional(),
  email: z.string().optional(),
  currency: z.string(),
  timezone: z.string(),
  expiryReminderDays: z.number(),
  isActive: z.boolean(),
  ownerId: objectId.optional(),
  createdAt: isoDate,
  updatedAt: isoDate,
});

// --- Member ---

export const memberResponseSchema = z.object({
  _id: objectId,
  gymId: objectId,
  name: z.string(),
  email: z.string().optional(),
  phone: z.string(),
  address: z.string().optional(),
  photo: z.string().optional(),
  dateOfBirth: isoDate.optional(),
  gender: genderEnum.optional(),
  planId: objectId.optional(),
  planName: z.string().optional(),
  membershipStart: dateOnly.optional(),
  membershipExpiry: dateOnly.optional(),
  notes: z.string().optional(),
  emergencyContact: z.string().optional(),
  dueAmount: z.number(),
  isActive: z.boolean(),
  status: memberDisplayStatusRef.optional(),
  daysUntilExpiry: z.number().int().optional(),
  createdAt: isoDate,
  updatedAt: isoDate,
});

// Registered (refId'd) copy of the member shape. Referencing this — rather
// than the raw `memberResponseSchema` — makes the generator emit a `$ref` to
// `#/components/schemas/MemberResponse` instead of inlining a duplicate class.
const memberResponseRef = memberResponseSchema.openapi("MemberResponse");

export const memberListResponseSchema = z.object({
  members: z.array(memberResponseRef),
  total: z.number(),
  page: z.number(),
  limit: z.number(),
});

// --- Payment (defined before member-create, which embeds a nullable payment) ---

export const paymentResponseSchema = z.object({
  _id: objectId,
  gymId: objectId,
  memberId: objectId,
  memberName: z.string(),
  planId: objectId.optional(),
  planName: z.string().optional(),
  planFeatures: z.array(z.string()).optional(),
  planDurationDays: z.number().optional(),
  amount: z.number(),
  kind: paymentKindEnum,
  method: paymentMethodEnum,
  status: paymentStatusEnum,
  invoiceNumber: z.string(),
  reference: z.string().optional(),
  notes: z.string().optional(),
  paidAt: isoDate,
  createdBy: objectId.optional(),
  voidedAt: isoDate.optional(),
  voidedBy: objectId.optional(),
  voidReason: z.string().optional(),
  refundedAt: isoDate.optional(),
  refundedBy: objectId.optional(),
  refundReason: z.string().optional(),
  createdAt: isoDate,
  updatedAt: isoDate,
});

// Registered (refId'd) copy of the payment shape, so embedded `payment` fields
// emit a `$ref` to `#/components/schemas/PaymentResponse` rather than an inline
// duplicate (e.g. `MemberCreateResponsePayment`).
const paymentResponseRef = paymentResponseSchema.openapi("PaymentResponse");

export const memberCreateResponseSchema = z.object({
  member: memberResponseRef,
  payment: z.nullable(paymentResponseRef),
  membershipId: objectId.optional(),
});

// --- Lifecycle result (shared mutation shape) ---

export const lifecycleResultResponseSchema = z.object({
  memberId: objectId,
  paymentId: objectId.optional(),
  membershipId: objectId.optional(),
  renewedUntil: dateOnly.optional(),
  dueAmount: z.number().optional(),
});

export const paymentCreateResponseSchema = lifecycleResultResponseSchema.extend({
  payment: z.nullable(paymentResponseRef),
});

// --- Plan ---

export const planResponseSchema = z.object({
  _id: objectId,
  gymId: objectId,
  name: z.string(),
  description: z.string().optional(),
  durationDays: z.number(),
  price: z.number(),
  features: z.array(z.string()).optional(),
  isActive: z.boolean(),
  createdAt: isoDate,
  updatedAt: isoDate,
});

const planStatsSchema = z.object({
  activeMembers: z.number(),
  salesYtd: z.number(),
  revenueAtSaleYtd: z.number(),
  totalMemberships: z.number(),
});

const planSummarySchema = z.object({
  activePlans: z.number(),
  activeMembers: z.number(),
  salesYtd: z.number(),
  revenueAtSaleYtd: z.number(),
});

export const planListItemResponseSchema = planResponseSchema.extend({
  stats: planStatsSchema.optional(),
});

export const planListResponseSchema = z.object({
  plans: z.array(planListItemResponseSchema),
  total: z.number(),
  page: z.number(),
  limit: z.number(),
  summary: planSummarySchema.optional(),
});

// --- Payment list ---

export const paymentListItemResponseSchema = paymentResponseSchema.extend({
  membershipId: objectId.optional(),
  membershipStatus: membershipStatusEnum.optional(),
});

export const paymentListResponseSchema = z.object({
  payments: z.array(paymentListItemResponseSchema),
  total: z.number(),
  page: z.number(),
  limit: z.number(),
  summary: z.object({
    netAmount: z.number(),
  }),
});

// --- Membership ---

export const membershipResponseSchema = z.object({
  _id: objectId,
  gymId: objectId,
  memberId: objectId,
  planId: objectId.optional(),
  planName: z.string(),
  startDate: dateOnly,
  expiryDate: dateOnly,
  paymentId: objectId.optional(),
  planPrice: z.number().optional(),
  amount: z.number().optional(),
  grantedBy: objectId,
  notes: z.string().optional(),
  status: membershipStatusEnum,
  expiryStatus: memberDisplayStatusRef.optional(),
  durationDays: z.number().int().optional(),
  reversedAt: isoDate.optional(),
  reversedBy: objectId.optional(),
  reversalReason: z.string().optional(),
  createdAt: isoDate,
  updatedAt: isoDate,
});

export const membershipListResponseSchema = z.object({
  memberships: z.array(membershipResponseSchema),
});

// --- Dashboard ---

export const dashboardResponseSchema = z.object({
  totalMembers: z.number(),
  activeMembers: z.number(),
  expiredMembers: z.number(),
  expiringMembers: z.number(),
  monthRevenue: z.number(),
  recentPayments: z.array(
    z.object({
      _id: objectId,
      memberName: z.string(),
      amount: z.number(),
      paidAt: isoDate,
      method: paymentMethodEnum,
    }),
  ),
  expiringList: z.array(
    z.object({
      _id: objectId,
      name: z.string(),
      phone: z.string(),
      membershipExpiry: dateOnly,
      planName: z.string().optional(),
      daysUntilExpiry: z.number().int(),
    }),
  ),
});

// --- Reports ---

const reportComparisonMetricSchema = z.object({
  value: z.number(),
  previous: z.number(),
  changePercent: z.number().nullable(),
});

const reportSeriesPointSchema = z.object({
  month: z.number(),
  revenue: z.number(),
  transactions: z.number(),
  newMembers: z.number(),
  memberships: z.number(),
  renewals: z.number(),
});

const reportPlanPerformanceSchema = z.object({
  key: z.string(),
  planId: z.string().optional(),
  name: z.string(),
  revenue: z.number(),
  sales: z.number(),
  activeMembers: z.number(),
});

const reportPaymentMethodSchema = z.object({
  method: z.string(),
  amount: z.number(),
  count: z.number(),
  percentage: z.number(),
});

const reportInsightsSchema = z.object({
  expiringSoon: z.number(),
  expiredMembers: z.number(),
  dueMembers: z.number(),
  outstandingDues: z.number(),
  bestMonth: z
    .object({
      month: z.number(),
      revenue: z.number(),
    })
    .nullable(),
});

export const reportsResponseSchema = z.object({
  year: z.number(),
  asOf: isoDate,
  timezone: z.string(),
  summary: z.object({
    revenue: reportComparisonMetricSchema,
    transactions: reportComparisonMetricSchema,
    newMembers: reportComparisonMetricSchema,
    renewals: reportComparisonMetricSchema,
    activeMembers: z.number(),
    outstandingDues: z.number(),
    dueMembers: z.number(),
  }),
  series: z.array(reportSeriesPointSchema),
  planPerformance: z.array(reportPlanPerformanceSchema),
  paymentMethods: z.array(reportPaymentMethodSchema),
  insights: reportInsightsSchema,
});

// --- Activity ---

export const activityLogResponseSchema = z.object({
  _id: objectId,
  gymId: objectId.optional(),
  staffId: objectId.optional(),
  staffName: z.string(),
  action: z.string(),
  entity: z.string(),
  entityId: z.string().optional(),
  details: z.string().optional(),
  createdAt: isoDate,
});

export const activityListResponseSchema = z.object({
  logs: z.array(activityLogResponseSchema),
  total: z.number(),
  page: z.number(),
  limit: z.number(),
});

// --- Health ---

export const healthResponseSchema = z.object({
  status: z.string(),
});
