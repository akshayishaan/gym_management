"use client";

import { ReactNode } from "react";
import { usePathname } from "next/navigation";
import { NoGymState } from "@/components/dashboard/NoGymState";
import { useGyms } from "@/lib/hooks/useGyms";

// The gyms page itself should always render so users can create their first gym
const UNGUARDED_PATHS = ["/dashboard/gyms"];

export function GymGuard({ children }: { children: ReactNode }) {
  const pathname = usePathname();
  const isUnguarded = UNGUARDED_PATHS.some((p) => pathname.startsWith(p));
  const { data: gyms, isLoading } = useGyms();

  if (isUnguarded) return <>{children}</>;

  if (isLoading) {
    return (
      <div className="space-y-6">
        <div className="h-10 w-48 bg-muted rounded-lg animate-pulse" />
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
          {[...Array(4)].map((_, i) => (
            <div key={i} className="h-32 bg-card rounded-2xl border animate-pulse" />
          ))}
        </div>
      </div>
    );
  }

  if (!gyms || gyms.length === 0) return <NoGymState />;

  return <>{children}</>;
}
