"use client";

import { useQuery } from "@tanstack/react-query";
import type { ReportsResponse } from "@/lib/reportTypes";
import { gymQueryKeys } from "@/lib/queryKeys";
import { useGymSettings } from "@/lib/useGymSettings";

export function useReports(year: number) {
  const { selectedGymId } = useGymSettings();
  return useQuery({
    queryKey: gymQueryKeys.reports(selectedGymId, year),
    enabled: !!selectedGymId,
    queryFn: async ({ signal }): Promise<ReportsResponse> => {
      const response = await fetch(`/api/reports?year=${year}`, { signal });
      const data = await response.json();
      if (!response.ok) throw new Error(data.error || "Failed to load reports");
      return data;
    },
  });
}
