import { z } from "zod";
import { isDateOnly } from "@/lib/membershipCalendar";

const membershipDateSchema = z.string().refine(isDateOnly, "Use a valid YYYY-MM-DD date");

export const paymentCreateSchema = z.object({
  requestId: z.string().uuid("Invalid request ID"),
  memberId: z.string().min(1, "Member ID is required"),
  planId: z.string().optional(),
  amount: z.number().min(0, "Amount must be non-negative"),
  method: z.enum(["cash", "card", "upi", "bank_transfer", "other"]),
  // Membership period start (yyyy-MM-dd). Used to set the Member's membership
  // window and the Membership history record — NOT stored on the Payment doc.
  membershipStart: membershipDateSchema.optional(),
  notes: z.string().max(1000).optional(),
}).superRefine((value, context) => {
  if (!value.planId && value.membershipStart) {
    context.addIssue({
      code: z.ZodIssueCode.custom,
      path: ["membershipStart"],
      message: "Membership start is only valid for a Plan purchase",
    });
  }
});

export const paymentActionSchema = z.object({
  requestId: z.string().uuid("Invalid request ID"),
  reason: z.string().max(500).trim().optional(),
});

export type PaymentCreateInput = z.infer<typeof paymentCreateSchema>;
export type PaymentActionInput = z.infer<typeof paymentActionSchema>;
