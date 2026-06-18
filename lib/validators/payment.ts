import { z } from "zod";

export const paymentCreateSchema = z.object({
  memberId: z.string().min(1, "Member ID is required"),
  memberName: z.string().min(1, "Member name is required").max(100).trim(),
  planId: z.string().optional(),
  planName: z.string().max(100).optional(),
  amount: z.number().min(0, "Amount must be non-negative"),
  method: z.enum(["cash", "card", "upi", "bank_transfer", "other"]),
  status: z.enum(["paid", "pending", "refunded"]).default("paid"),
  paidAt: z.string().optional(),
  notes: z.string().max(1000).optional(),
});

export type PaymentCreateInput = z.infer<typeof paymentCreateSchema>;
