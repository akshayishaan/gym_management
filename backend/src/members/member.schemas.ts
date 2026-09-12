import { z } from "zod";
import { isDateOnly } from "../lib";

const membershipDateSchema = z.string().refine(isDateOnly, "Use a valid YYYY-MM-DD date");

export const memberCreateSchema = z.object({
  requestId: z.string().uuid("Invalid request ID"),
  name: z.string().min(1, "Name is required").max(100).trim(),
  email: z.string().email("Invalid email").optional().or(z.literal("")),
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
  email: z.string().email("Invalid email").optional().or(z.literal("")).optional(),
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
