"use client";

import { useQuery } from "@tanstack/react-query";
import { gymQueryKeys } from "@/lib/queryKeys";
import { useGymSettings } from "@/lib/useGymSettings";

export interface MembershipListItem {
  _id: string;
  planName: string;
  startDate: string;
  expiryDate: string;
  planPrice?: number;
  amount?: number;
  paymentId?: string;
  status: "active" | "reversed";
  createdAt?: string;
}

interface MembershipsResponse {
  memberships: MembershipListItem[];
}

export function useMemberships(memberId: string) {
  const { selectedGymId } = useGymSettings();
  return useQuery({
    queryKey: gymQueryKeys.memberships(selectedGymId, memberId),
    enabled: !!selectedGymId && !!memberId,
    queryFn: async ({ signal }): Promise<MembershipsResponse> => {
      const response = await fetch(`/api/memberships?memberId=${memberId}`, { signal });
      const data = await response.json();
      if (!response.ok) throw new Error(data.error || "Failed to load membership history");
      return data;
    },
  });
}
