"use client";

import { useQuery, useQueryClient } from "@tanstack/react-query";
import { useSession } from "next-auth/react";

export interface Gym {
  _id: string;
  name: string;
  logo?: string;
  primaryColor?: string;
  address?: string;
  phone?: string;
  email?: string;
  currency: string;
  isActive: boolean;
  createdAt: string;
}

export const GYMS_KEY = ["gyms"] as const;

async function fetchGyms(): Promise<Gym[]> {
  const res = await fetch("/api/gyms");
  if (!res.ok) throw new Error("Failed to fetch gyms");
  const data = await res.json();
  return Array.isArray(data) ? data : [];
}

/**
 * Shared query hook for the current user's gyms.
 * All components that call this hook share a single cache entry under ["gyms"].
 * Data is considered fresh for 5 minutes — navigating between pages won't
 * trigger a re-fetch while the cache is warm.
 */
export function useGyms() {
  const { data: session } = useSession();
  const isSuperAdmin = (session?.user as { role?: string })?.role === "superadmin";

  return useQuery({
    queryKey: GYMS_KEY,
    queryFn: fetchGyms,
    // Superadmins see all gyms via their own admin interface, not this list
    enabled: !!session && !isSuperAdmin,
  });
}

/**
 * Returns a stable function that invalidates the ["gyms"] cache.
 * Call after create, edit, or delete so all components (GymSwitcher,
 * GymGuard, gyms page) re-fetch in sync with one network request.
 */
export function useInvalidateGyms() {
  const qc = useQueryClient();
  return () => qc.invalidateQueries({ queryKey: GYMS_KEY });
}
