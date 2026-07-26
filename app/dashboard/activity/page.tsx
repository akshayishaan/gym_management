"use client";

import { Button } from "@/components/ui/button";
import { StackHeader } from "@/components/layout/StackHeader";
import { ActivityRow } from "@/components/dashboard/ActivityRow";
import { ClipboardList } from "lucide-react";
import { useActivity } from "@/lib/hooks/useActivity";

const LIMIT = 20;

export default function ActivityPage() {
  const activity = useActivity(LIMIT);
  const logs = activity.data?.pages.flatMap((page) => page.logs) ?? [];
  const total = activity.data?.pages[0]?.total ?? 0;

  return (
    <div className="app-canvas flex min-h-svh flex-col">
      <StackHeader title="Activity Log" />
      <div
        className="app-screen flex-1 space-y-4 px-5 py-5"
        style={{ paddingBottom: "calc(1.5rem + env(safe-area-inset-bottom))" }}
      >
        <div className="flex items-center justify-between px-1">
          <p className="app-section-label">Team timeline</p>
          <p className="text-xs font-semibold text-muted-foreground">{total} events</p>
        </div>

        {activity.isLoading ? (
          <div className="space-y-2">
            {[...Array(6)].map((_, index) => (
              <div key={index} className="h-20 animate-pulse rounded-[1.5rem] bg-card" />
            ))}
          </div>
        ) : logs.length === 0 ? (
          <div className="app-surface flex flex-col items-center gap-3 rounded-[2rem] px-6 py-16 text-center">
            <div className="inline-flex h-16 w-16 items-center justify-center rounded-[1.4rem] bg-muted text-muted-foreground">
              <ClipboardList className="h-6 w-6" />
            </div>
            <div>
              <p className="text-sm font-medium text-muted-foreground">No activity yet</p>
              <p className="mt-1 text-xs text-muted-foreground">Actions will appear here as they happen</p>
            </div>
          </div>
        ) : (
          <>
            <div className="app-surface divide-y divide-border/60 overflow-hidden rounded-[1.75rem] px-3">
              {logs.map((log) => <ActivityRow key={log._id} log={log} />)}
            </div>
            {activity.hasNextPage && (
              <Button
                variant="outline"
                className="w-full"
                onClick={() => void activity.fetchNextPage()}
                disabled={activity.isFetchingNextPage}
              >
                {activity.isFetchingNextPage ? "Loading…" : "Load more"}
              </Button>
            )}
          </>
        )}
      </div>
    </div>
  );
}
