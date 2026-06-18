import { z } from "zod";

export const memberCreateSchema = z.object({
  name: z.string().min(1, "Name is required").max(100).trim(),
  email: z.string().email("Invalid email").optional().or(z.literal("")),
  phone: z.string().min(1, "Phone is required").max(20).trim(),
  address: z.string().max(500).optional(),
  photo: z.string().url().optional(),
  dateOfBirth: z.string().optional(),
  gender: z.enum(["male", "female", "other"]).optional(),
  planId: z.string().optional(),
  planName: z.string().max(100).optional(),
  membershipStart: z.string().optional(),
  membershipExpiry: z.string().optional(),
  notes: z.string().max(1000).optional(),
  emergencyContact: z.string().max(20).optional(),
});

export const memberUpdateSchema = z.object({
  name: z.string().min(1, "Name is required").max(100).trim().optional(),
  email: z.string().email("Invalid email").optional().or(z.literal("")).optional(),
  phone: z.string().min(1, "Phone is required").max(20).trim().optional(),
  address: z.string().max(500).optional(),
  photo: z.string().url().optional(),
  dateOfBirth: z.string().optional(),
  gender: z.enum(["male", "female", "other"]).optional(),
  planId: z.string().optional(),
  planName: z.string().max(100).optional(),
  membershipStart: z.string().optional(),
  membershipExpiry: z.string().optional(),
  notes: z.string().max(1000).optional(),
  emergencyContact: z.string().max(20).optional(),
});

export type MemberCreateInput = z.infer<typeof memberCreateSchema>;
export type MemberUpdateInput = z.infer<typeof memberUpdateSchema>;
