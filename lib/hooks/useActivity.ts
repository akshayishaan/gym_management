"use client";

import { useInfiniteQuery } from "@tanstack/react-query";
import { gymQueryKeys } from "@/lib/queryKeys";
import { useGymSettings } from "@/lib/useGymSettings";

export interface ActivityItem {
  _id: string;
  staffName: string;
  action: string;
  entity: string;
  details?: string;
  createdAt: string;
}

interface ActivityResponse {
  logs: ActivityItem[];
  total: number;
  page: number;
  limit: number;
}

export function useActivity(limit = 20) {
  const { selectedGymId } = useGymSettings();
  return useInfiniteQuery({
    queryKey: gymQueryKeys.activity(selectedGymId),
    enabled: !!selectedGymId,
    initialPageParam: 1,
    queryFn: async ({ pageParam, signal }): Promise<ActivityResponse> => {
      const response = await fetch(`/api/activity?page=${pageParam}&limit=${limit}`, { signal });
      const data = await response.json();
      if (!response.ok) throw new Error(data.error || "Failed to load activity");
      return data;
    },
    getNextPageParam: (lastPage, pages) => {
      const loaded = pages.reduce((total, page) => total + page.logs.length, 0);
      return loaded < lastPage.total ? pages.length + 1 : undefined;
    },
  });
}
