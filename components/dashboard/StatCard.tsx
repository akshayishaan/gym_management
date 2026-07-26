"use client";

import { useEffect, useState } from "react";
import { Card, CardContent } from "@/components/ui/card";
import { cn } from "@/lib/utils";
import { SparklineStat } from "@/components/dashboard/SparklineStat";

interface StatCardProps {
  title: string;
  value: string | number;
  icon: React.ElementType;
  gradient?: "blue" | "emerald" | "amber" | "orange";
  /** Illustrative trend line, oldest to newest. Omit to hide the sparkline. */
  trendData?: number[];
  /** Used by the not-yet-mobile-rewritten Reports page; kept for backward
   *  compatibility until that page's own phase. New usage should prefer
   *  trendData over a static caption. */
  description?: string;
}

const iconStyleMap: Record<NonNullable<StatCardProps["gradient"]>, string> = {
  blue: "bg-primary/10 text-primary",
  emerald: "bg-success/10 text-success",
  amber: "bg-warning/10 text-warning",
  orange: "bg-primary/10 text-primary",
};

const strokeColorMap: Record<NonNullable<StatCardProps["gradient"]>, string> = {
  blue: "hsl(var(--primary))",
  emerald: "hsl(var(--success))",
  amber: "hsl(var(--warning))",
  orange: "hsl(var(--primary))",
};

function CountUp({ target, duration = 800 }: { target: number; duration?: number }) {
  const [count, setCount] = useState(0);

  useEffect(() => {
    if (target === 0) {
      setCount(0);
      return;
    }
    const startTime = performance.now();
    let frame: number;
    const animate = (now: number) => {
      const progress = Math.min((now - startTime) / duration, 1);
      const eased = 1 - Math.pow(1 - progress, 3);
      setCount(Math.floor(target * eased));
      if (progress < 1) frame = requestAnimationFrame(animate);
      else setCount(target);
    };
    frame = requestAnimationFrame(animate);
    return () => cancelAnimationFrame(frame);
  }, [target, duration]);

  return <>{count.toLocaleString()}</>;
}

export function StatCard({
  title,
  value,
  icon: Icon,
  gradient = "orange",
  trendData,
  description,
}: StatCardProps) {
  return (
    <Card className="relative overflow-hidden border-0 shadow-card">
      <CardContent className="space-y-3 p-4">
        <span className={cn("flex h-10 w-10 items-center justify-center rounded-2xl", iconStyleMap[gradient])}>
          <Icon className="h-4 w-4" />
        </span>
        <div className="space-y-0.5">
          <p className="truncate font-display text-xl font-extrabold tracking-[-0.04em]">
            {typeof value === "number" ? <CountUp target={value} /> : value}
          </p>
          <p className="truncate text-xs font-bold text-muted-foreground">{title}</p>
          {description && <p className="truncate text-[11px] text-muted-foreground">{description}</p>}
        </div>
        {trendData && trendData.length > 1 && (
          <SparklineStat data={trendData} color={strokeColorMap[gradient]} />
        )}
      </CardContent>
    </Card>
  );
}
