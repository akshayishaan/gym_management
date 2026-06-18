/**
 * Shared TypeScript types for API request/response.
 * These are derived from the Zod validation schemas to ensure
 * frontend and backend stay in sync.
 */

// Member types
export type { MemberCreateInput, MemberUpdateInput } from "./member";

// Payment types
export type { PaymentCreateInput } from "./payment";

// Plan types
export type { PlanCreateInput, PlanUpdateInput } from "./plan";

// Staff types
export type { StaffCreateInput, StaffUpdateInput } from "./staff";

// Gym types
export type { GymCreateInput, GymUpdateInput } from "./gym";

/**
 * API response types for paginated lists.
 */
export interface PaginatedResponse<T> {
  data: T[];
  total: number;
  page: number;
  limit: number;
}

/**
 * API error response shape.
 */
export interface ApiErrorResponse {
  error: string;
  details?: unknown;
}

/**
 * Member shape as returned from API (lean Mongoose doc).
 */
export interface MemberResponse {
  _id: string;
  gymId: string;
  name: string;
  email?: string;
  phone: string;
  address?: string;
  photo?: string;
  dateOfBirth?: string;
  gender?: "male" | "female" | "other";
  planId?: string;
  planName?: string;
  membershipStart?: string;
  membershipExpiry?: string;
  notes?: string;
  emergencyContact?: string;
  createdAt: string;
  updatedAt: string;
}

/**
 * Payment shape as returned from API.
 */
export interface PaymentResponse {
  _id: string;
  gymId: string;
  memberId: string;
  memberName: string;
  planId?: string;
  planName?: string;
  amount: number;
  method: "cash" | "card" | "upi" | "bank_transfer" | "other";
  status: "paid" | "pending" | "refunded";
  invoiceNumber: string;
  notes?: string;
  paidAt: string;
  createdBy?: string;
  createdAt: string;
  updatedAt: string;
}

/**
 * Plan shape as returned from API.
 */
export interface PlanResponse {
  _id: string;
  gymId: string;
  name: string;
  description?: string;
  durationDays: number;
  price: number;
  features?: string[];
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
}

/**
 * Staff shape as returned from API (password excluded).
 */
export interface StaffResponse {
  _id: string;
  gymId?: string;
  name: string;
  email: string;
  role: "superadmin" | "admin" | "receptionist" | "trainer";
  isActive: boolean;
  lastLogin?: string;
  createdAt: string;
  updatedAt: string;
}

/**
 * Gym shape as returned from API.
 */
export interface GymResponse {
  _id: string;
  name: string;
  logo?: string;
  primaryColor: string;
  address?: string;
  phone?: string;
  email?: string;
  currency: string;
  expiryReminderDays: number;
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
}

/**
 * Activity log shape as returned from API.
 */
export interface ActivityLogResponse {
  _id: string;
  gymId?: string;
  staffId?: string;
  staffName: string;
  action: string;
  entity: string;
  entityId?: string;
  details?: string;
  createdAt: string;
}
