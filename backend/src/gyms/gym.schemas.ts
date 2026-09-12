import { z } from "zod";
import { isValidTimeZone } from "../lib";

const timeZoneSchema = z.string().refine(isValidTimeZone, "Invalid IANA timezone");

export const gymCreateSchema = z.object({
  name: z.string().min(1, "Gym name is required").max(200).trim(),
  logo: z.string().optional(),
  primaryColor: z
    .string()
    .regex(/^#[0-9a-fA-F]{6}$/, "Invalid hex color")
    .default("#6366f1"),
  address: z.string().max(500).optional(),
  phone: z.string().max(20).optional(),
  email: z.string().email().optional(),
  currency: z.string().length(3).default("INR"),
  timezone: timeZoneSchema.default("Asia/Kolkata"),
  expiryReminderDays: z.number().int().min(1).max(90).default(7),
  isActive: z.boolean().default(true),
});

export const gymUpdateSchema = z.object({
  name: z.string().min(1, "Gym name is required").max(200).trim().optional(),
  logo: z.string().optional(),
  primaryColor: z
    .string()
    .regex(/^#[0-9a-fA-F]{6}$/, "Invalid hex color")
    .optional(),
  address: z.string().max(500).optional(),
  phone: z.string().max(20).optional(),
  email: z.string().email().optional(),
  currency: z.string().length(3).optional(),
  timezone: timeZoneSchema.optional(),
  expiryReminderDays: z.number().int().min(1).max(90).optional(),
  isActive: z.boolean().optional(),
});

export type GymCreateInput = z.infer<typeof gymCreateSchema>;
export type GymUpdateInput = z.infer<typeof gymUpdateSchema>;
