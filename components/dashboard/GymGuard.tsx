"use client";

import { ReactNode } from "react";
import { usePathname } from "next/navigation";
import { Dumbbell } from "lucide-react";
import { NoGymState } from "@/components/dashboard/NoGymState";
import { useGyms } from "@/lib/hooks/useGyms";

// The gyms page itself should always render so users can create their first
// gym. More/Settings must stay reachable too — they're the only place to
// sign out, and with zero gyms there'd otherwise be no way out of the
// NoGymState screen.
const UNGUARDED_PATHS = ["/dashboard/gyms", "/dashboard/more", "/dashboard/settings"];

export function GymGuard({ children }: { children: ReactNode }) {
  const pathname = usePathname();
  const isUnguarded = UNGUARDED_PATHS.some((p) => pathname.startsWith(p));
  const { data: gyms, isLoading } = useGyms();

  if (isUnguarded) return <>{children}</>;

  if (isLoading) {
    return (
      <div className="flex min-h-[60svh] flex-col items-center justify-center gap-4 text-center">
        <div className="relative flex h-16 w-16 items-center justify-center rounded-[1.5rem] bg-primary/10 text-primary">
          <div className="absolute inset-0 animate-ping rounded-[1.5rem] bg-primary/10" />
          <Dumbbell className="relative h-6 w-6" />
        </div>
        <div>
          <p className="font-display text-sm font-bold">Getting the floor ready</p>
          <p className="mt-1 text-xs text-muted-foreground">Loading your gym workspace…</p>
        </div>
      </div>
    );
  }

  if (!gyms || gyms.length === 0) return <NoGymState />;

  return <>{children}</>;
}
