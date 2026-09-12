import { z } from "zod";
import { isDateOnly } from "../lib";

const membershipDateSchema = z.string().refine(isDateOnly, "Use a valid YYYY-MM-DD date");

// Same regex zod's `.email()` uses internally. Kept as a `.refine()` on a
// single string so OpenAPI emits `type: string` (optional) rather than the
// `anyOf: [string(email), string(enum:[""])]` a union-of-literal produces —
// which the Dart generator collapses into an unmodelable empty class.
const emailRegex = /^(?!\.)(?!.*\.\.)([A-Z0-9_'+\-\.]*)[A-Z0-9_+-]@([A-Z0-9][A-Z0-9\-]*\.)+[A-Z]{2,}$/i;

// Optional email: absent, empty string, or a valid address are all accepted.
const optionalEmailSchema = z
  .string()
  .refine((value) => value === "" || emailRegex.test(value), "Invalid email")
  .optional();

export const memberCreateSchema = z.object({
  requestId: z.string().uuid("Invalid request ID"),
  name: z.string().min(1, "Name is required").max(100).trim(),
  email: optionalEmailSchema,
  phone: z.string().min(1, "Phone is required").max(20).trim(),
  address: z.string().max(500).optional(),
  photo: z.string().url().optional(),
  dateOfBirth: z.string().optional(),
  gender: z.enum(["male", "female", "other"]).optional(),
  planId: z.string().optional(),
  membershipStart: membershipDateSchema.optional(),
  notes: z.string().max(1000).optional(),
  emergencyContact: z.string().max(20).optional(),
  amountPaid: z.number().min(0).optional(),
  paymentMethod: z.enum(["cash", "card", "upi", "bank_transfer", "other"]).optional(),
}).superRefine((value, context) => {
  if (!value.planId && (value.membershipStart || value.amountPaid !== undefined || value.paymentMethod)) {
    context.addIssue({
      code: z.ZodIssueCode.custom,
      path: ["planId"],
      message: "Select a plan before setting Membership or Payment details",
    });
  }
});

export const memberUpdateSchema = z.object({
  name: z.string().min(1, "Name is required").max(100).trim().optional(),
  email: optionalEmailSchema,
  phone: z.string().min(1, "Phone is required").max(20).trim().optional(),
  address: z.string().max(500).optional(),
  photo: z.string().url().optional(),
  dateOfBirth: z.string().optional(),
  gender: z.enum(["male", "female", "other"]).optional(),
  notes: z.string().max(1000).optional(),
  emergencyContact: z.string().max(20).optional(),
  isActive: z.boolean().optional(), // restore a soft-deleted member
});

export type MemberCreateInput = z.infer<typeof memberCreateSchema>;
export type MemberUpdateInput = z.infer<typeof memberUpdateSchema>;
