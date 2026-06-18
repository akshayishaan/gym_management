"use client";

import useSWR, { mutate as globalMutate } from "swr";

/**
 * Generic fetcher for SWR — parses JSON and throws on non-ok responses.
 */
async function fetcher(url: string) {
  const res = await fetch(url);
  if (!res.ok) {
    const error = new Error("API request failed");
    (error as Error & { status: number }).status = res.status;
    try {
      const body = await res.json();
      (error as Error & { info: unknown }).info = body;
    } catch {
      // ignore JSON parse errors
    }
    throw error;
  }
  return res.json();
}

/**
 * Reusable SWR-based data fetching hook.
 *
 * Usage:
 * ```tsx
 * const { data, error, isLoading, mutate } = useApi("/api/members?status=active");
 * ```
 */
export function useApi<T = unknown>(url: string | null) {
  const { data, error, isLoading, mutate } = useSWR<T>(url, fetcher, {
    revalidateOnFocus: false,
    dedupingInterval: 5000,
  });

  return {
    data,
    error,
    isLoading,
    mutate,
  };
}

/**
 * Revalidates all SWR cache entries matching a URL prefix.
 * Useful after a mutation (POST/PUT/DELETE) to refresh related lists.
 *
 * Usage:
 * ```tsx
 * await fetch("/api/members", { method: "POST", ... });
 * refreshApi("/api/members"); // revalidate all member-related SWR caches
 * ```
 */
export function refreshApi(prefix: string) {
  return globalMutate(
    (key: unknown) => typeof key === "string" && key.startsWith(prefix),
    undefined,
    { revalidate: true }
  );
}
