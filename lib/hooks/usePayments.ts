"use client";

import { useQuery, useQueryClient } from "@tanstack/react-query";
import { useGymSettings } from "@/lib/useGymSettings";
import { gymQueryKeys } from "@/lib/queryKeys";

export interface PaymentListItem {
  _id: string;
  memberName: string;
  memberId: string;
  amount: number;
  kind: "plan_purchase" | "dues";
  method: string;
  status: "paid" | "voided" | "refunded";
  invoiceNumber: string;
  paidAt: string;
  planName?: string;
  voidedAt?: string;
  refundedAt?: string;
  membershipId?: string;
  membershipStatus?: "active" | "reversed";
}

interface PaymentsResponse {
  payments: PaymentListItem[];
  total: number;
  page: number;
  limit: number;
  summary: { netAmount: number };
}

export function usePayments(filters: {
  memberId?: string;
  month?: string;
  page?: number;
  limit?: number;
} = {}) {
  const { selectedGymId } = useGymSettings();
  const normalized = {
    memberId: filters.memberId || "",
    month: filters.month || "",
    page: filters.page || 1,
    limit: filters.limit || 50,
  };
  return useQuery({
    queryKey: gymQueryKeys.payments(selectedGymId, normalized),
    enabled: !!selectedGymId,
    queryFn: async ({ signal }): Promise<PaymentsResponse> => {
      const params = new URLSearchParams({
        page: String(normalized.page),
        limit: String(normalized.limit),
      });
      if (normalized.memberId) params.set("memberId", normalized.memberId);
      if (normalized.month) params.set("month", normalized.month);
      const response = await fetch(`/api/payments?${params}`, { signal });
      const data = await response.json();
      if (!response.ok) throw new Error(data.error || "Failed to load payments");
      return data;
    },
  });
}

export function useInvalidatePayments() {
  const { selectedGymId } = useGymSettings();
  const queryClient = useQueryClient();
  return () => queryClient.invalidateQueries({
    queryKey: ["gym", selectedGymId, "payments"],
  });
}
