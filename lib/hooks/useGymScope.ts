"use client";

import { useQueryClient } from "@tanstack/react-query";
import { gymQueryKeys } from "@/lib/queryKeys";
import { useGymSettings } from "@/lib/useGymSettings";

export function useInvalidateGymScope() {
  const queryClient = useQueryClient();
  const { selectedGymId } = useGymSettings();
  return () => queryClient.invalidateQueries({
    queryKey: gymQueryKeys.root(selectedGymId),
  });
}
