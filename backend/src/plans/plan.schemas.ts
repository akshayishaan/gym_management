import { z } from "zod";

export const planCreateSchema = z.object({
  name: z.string().min(1, "Name is required").max(100).trim(),
  description: z.string().max(500).optional(),
  durationDays: z.number().int().min(1, "Duration must be at least 1 day"),
  price: z.number().min(0, "Price must be non-negative"),
  features: z.array(z.string().max(200)).max(20).optional(),
  isActive: z.boolean().default(true),
});

export const planUpdateSchema = z.object({
  name: z.string().min(1, "Name is required").max(100).trim().optional(),
  description: z.string().max(500).optional(),
  durationDays: z.number().int().min(1, "Duration must be at least 1 day").optional(),
  price: z.number().min(0, "Price must be non-negative").optional(),
  features: z.array(z.string().max(200)).max(20).optional(),
  isActive: z.boolean().optional(),
});

export type PlanCreateInput = z.infer<typeof planCreateSchema>;
export type PlanUpdateInput = z.infer<typeof planUpdateSchema>;
