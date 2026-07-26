"use client";

import { useQuery, useQueryClient } from "@tanstack/react-query";
import { useGymSettings } from "@/lib/useGymSettings";
import { gymQueryKeys } from "@/lib/queryKeys";

export interface MemberListItem {
  _id: string;
  name: string;
  phone: string;
  email?: string;
  address?: string;
  gender?: string;
  dateOfBirth?: string;
  planId?: string;
  planName?: string;
  membershipExpiry?: string;
  membershipStart?: string;
  dueAmount?: number;
  notes?: string;
  emergencyContact?: string;
  isActive?: boolean;
}

interface MembersResponse {
  members: MemberListItem[];
  total: number;
  page: number;
  limit: number;
}

export function useMembers(filters: {
  search?: string;
  status?: string;
  page?: number;
  limit?: number;
  enabled?: boolean;
} = {}) {
  const { selectedGymId } = useGymSettings();
  const normalized = {
    search: filters.search || "",
    status: filters.status || "",
    page: filters.page || 1,
    limit: filters.limit || 20,
  };

  return useQuery({
    queryKey: gymQueryKeys.members(selectedGymId, normalized),
    enabled: !!selectedGymId && filters.enabled !== false,
    queryFn: async ({ signal }): Promise<MembersResponse> => {
      const params = new URLSearchParams({
        page: String(normalized.page),
        limit: String(normalized.limit),
      });
      if (normalized.search) params.set("search", normalized.search);
      if (normalized.status && normalized.status !== "all") params.set("status", normalized.status);
      const response = await fetch(`/api/members?${params}`, { signal });
      const data = await response.json();
      if (!response.ok) throw new Error(data.error || "Failed to load members");
      return data;
    },
  });
}

export function useInvalidateMembers() {
  const { selectedGymId } = useGymSettings();
  const queryClient = useQueryClient();
  return () => queryClient.invalidateQueries({
    queryKey: ["gym", selectedGymId, "members"],
  });
}

export function useMember(memberId: string, enabled = true) {
  const { selectedGymId } = useGymSettings();
  return useQuery({
    queryKey: gymQueryKeys.member(selectedGymId, memberId),
    enabled: !!selectedGymId && !!memberId && enabled,
    queryFn: async ({ signal }): Promise<MemberListItem> => {
      const response = await fetch(`/api/members/${memberId}`, { signal });
      const data = await response.json();
      if (!response.ok) throw new Error(data.error || "Failed to load member");
      return data;
    },
  });
}
