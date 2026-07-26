"use client";

import { useQuery, useQueryClient } from "@tanstack/react-query";
import type { PlansResponse } from "@/lib/planTypes";
import { gymQueryKeys } from "@/lib/queryKeys";
import { useGymSettings } from "@/lib/useGymSettings";

export function usePlans(filters: {
  status?: "active" | "inactive" | "all";
  includeStats?: boolean;
  limit?: number;
  enabled?: boolean;
} = {}) {
  const { selectedGymId } = useGymSettings();
  const normalized = {
    status: filters.status || "all",
    includeStats: filters.includeStats !== false,
    limit: filters.limit || 100,
  };
  return useQuery({
    queryKey: gymQueryKeys.plans(selectedGymId, normalized),
    enabled: !!selectedGymId && filters.enabled !== false,
    queryFn: async ({ signal }): Promise<PlansResponse> => {
      const params = new URLSearchParams({
        status: normalized.status,
        includeStats: String(normalized.includeStats),
        limit: String(normalized.limit),
      });
      const response = await fetch(`/api/plans?${params}`, { signal });
      const data = await response.json();
      if (!response.ok) throw new Error(data.error || "Failed to load plans");
      return data;
    },
  });
}

export function useInvalidatePlans() {
  const { selectedGymId } = useGymSettings();
  const queryClient = useQueryClient();
  return () => queryClient.invalidateQueries({
    queryKey: ["gym", selectedGymId, "plans"],
  });
}
