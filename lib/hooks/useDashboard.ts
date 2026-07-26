"use client";

import { useQuery, useQueryClient } from "@tanstack/react-query";
import { gymQueryKeys } from "@/lib/queryKeys";
import { useGymSettings } from "@/lib/useGymSettings";

export interface DashboardData {
  totalMembers: number;
  activeMembers: number;
  expiredMembers: number;
  expiringMembers: number;
  monthRevenue: number;
  recentPayments: Array<{
    _id: string;
    memberName: string;
    amount: number;
    paidAt: string;
    method: string;
  }>;
  expiringList: Array<{
    _id: string;
    name: string;
    phone: string;
    membershipExpiry: string;
    planName?: string;
  }>;
}

export function useDashboard() {
  const { selectedGymId } = useGymSettings();
  return useQuery({
    queryKey: gymQueryKeys.dashboard(selectedGymId),
    enabled: !!selectedGymId,
    queryFn: async ({ signal }): Promise<DashboardData> => {
      const response = await fetch("/api/dashboard", { signal });
      const data = await response.json();
      if (!response.ok) throw new Error(data.error || "Failed to load dashboard");
      return data;
    },
  });
}

export function useInvalidateDashboard() {
  const { selectedGymId } = useGymSettings();
  const queryClient = useQueryClient();
  return () => queryClient.invalidateQueries({
    queryKey: gymQueryKeys.dashboard(selectedGymId),
  });
}
