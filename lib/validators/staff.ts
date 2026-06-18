import { z } from "zod";

export const staffCreateSchema = z.object({
  name: z.string().min(1, "Name is required").max(100).trim(),
  email: z.string().email("Invalid email").min(1, "Email is required"),
  password: z.string().min(6, "Password must be at least 6 characters"),
  role: z.enum(["superadmin", "admin", "receptionist", "trainer"]).default("receptionist"),
  gymIds: z.array(z.string()).optional(),
  isActive: z.boolean().default(true),
});

export const staffUpdateSchema = z.object({
  name: z.string().min(1, "Name is required").max(100).trim().optional(),
  password: z.string().min(6, "Password must be at least 6 characters").optional(),
  role: z.enum(["admin", "receptionist", "trainer"]).optional(),
  gymIds: z.array(z.string()).optional(),
  isActive: z.boolean().optional(),
});

export type StaffCreateInput = z.infer<typeof staffCreateSchema>;
export type StaffUpdateInput = z.infer<typeof staffUpdateSchema>;
