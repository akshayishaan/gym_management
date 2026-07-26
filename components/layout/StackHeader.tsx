"use client";

import { useRouter } from "next/navigation";
import { ChevronLeft } from "lucide-react";
import { cn } from "@/lib/utils";

interface StackHeaderProps {
  title: string;
  onBack?: () => void;
  actions?: React.ReactNode;
  className?: string;
}

/**
 * Header for drill-in / full-screen pages (member detail, add/edit forms) —
 * back arrow + title, no bottom tab bar. Falls back to router.back() when
 * no explicit onBack is given.
 */
export function StackHeader({ title, onBack, actions, className }: StackHeaderProps) {
  const router = useRouter();

  return (
    <header
      className={cn(
        "sticky top-0 z-30 flex shrink-0 items-center gap-2 border-b border-border/50 bg-background/85 px-3 pb-2 backdrop-blur-xl",
        className
      )}
      style={{ paddingTop: "calc(0.5rem + env(safe-area-inset-top))" }}
    >
      <button
        type="button"
        onClick={onBack ?? (() => router.back())}
        aria-label="Back"
        className="flex h-11 w-11 shrink-0 items-center justify-center rounded-2xl bg-card shadow-card transition-all active:scale-95 active:bg-muted"
      >
        <ChevronLeft className="h-5 w-5" strokeWidth={2.5} />
      </button>
      <h1 className="flex-1 truncate font-display text-lg font-bold tracking-tight">{title}</h1>
      {actions && <div className="flex shrink-0 items-center gap-1">{actions}</div>}
    </header>
  );
}
