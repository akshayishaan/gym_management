"use client";

import { usePathname } from "next/navigation";
import { cn } from "@/lib/utils";
import { TopAppBar } from "@/components/layout/TopAppBar";
import { BottomTabBar } from "@/components/layout/BottomTabBar";

const TAB_ROOT_TITLES: Record<string, string> = {
  "/dashboard": "Today",
  "/dashboard/members": "Members",
  "/dashboard/payments": "Payments",
  "/dashboard/more": "More",
};

/**
 * Top-level chrome for every /dashboard/* route. Tab-root screens
 * (Dashboard/Members/Payments/More) get the TopAppBar + BottomTabBar;
 * drill-in pages (member detail, full-screen forms) render edge-to-edge
 * and provide their own StackHeader instead.
 */
export function MobileShell({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const title = TAB_ROOT_TITLES[pathname];
  const isTabRoot = !!title;

  return (
    <div className="app-canvas flex h-svh flex-col overflow-hidden">
      {isTabRoot && <TopAppBar title={title} />}
      <main className={cn("hide-scrollbar min-h-0 flex-1 overscroll-contain overflow-y-auto", isTabRoot && "pb-28")}>
        {isTabRoot ? (
          <div className="mx-auto w-full max-w-md px-5 pb-6 pt-2">{children}</div>
        ) : (
          children
        )}
      </main>
      {isTabRoot && <BottomTabBar />}
    </div>
  );
}
