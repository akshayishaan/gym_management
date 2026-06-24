"use client";

import { useEffect, useState } from "react";
import { motion } from "framer-motion";
import { Card, CardContent } from "@/components/ui/card";
import { cn } from "@/lib/utils";
import { TrendingUp, TrendingDown } from "lucide-react";

interface StatCardProps {
  title: string;
  value: string | number;
  icon: React.ElementType;
  description?: string;
  trend?: number;
  gradient?: "blue" | "emerald" | "amber" | "rose" | "orange" | "violet";
  delay?: number;
}

// Maps the old gradient names to flat, theme-aware icon styles
const iconStyleMap: Record<NonNullable<StatCardProps["gradient"]>, string> = {
  blue:    "bg-primary/10 text-primary",
  emerald: "bg-success/10 text-success",
  amber:   "bg-warning/10 text-warning",
  rose:    "bg-destructive/10 text-destructive",
  orange:  "bg-primary/10 text-primary",
  violet:  "bg-primary/10 text-primary",
};

function CountUp({ target, duration = 1200 }: { target: number; duration?: number }) {
  const [count, setCount] = useState(0);

  useEffect(() => {
    if (target === 0) { setCount(0); return; }
    const startTime = performance.now();
    const animate = (now: number) => {
      const elapsed = now - startTime;
      const progress = Math.min(elapsed / duration, 1);
      const eased = 1 - Math.pow(1 - progress, 3);
      setCount(Math.floor(target * eased));
      if (progress < 1) requestAnimationFrame(animate);
      else setCount(target);
    };
    requestAnimationFrame(animate);
  }, [target, duration]);

  return <>{count.toLocaleString()}</>;
}

function TrendBadge({ value }: { value: number }) {
  if (value === 0) return null;
  const isPositive = value > 0;
  const Icon = isPositive ? TrendingUp : TrendingDown;
  return (
    <span
      className={cn(
        "inline-flex items-center gap-0.5 text-xs font-medium px-1.5 py-0.5 rounded-full",
        isPositive
          ? "bg-success/10 text-success"
          : "bg-destructive/10 text-destructive"
      )}
    >
      <Icon className="h-3 w-3" />
      {Math.abs(value)}%
    </span>
  );
}

export function StatCard({
  title,
  value,
  icon: Icon,
  description,
  trend,
  gradient = "orange",
  delay = 0,
}: StatCardProps) {
  const isCurrency =
    typeof value === "string" &&
    (value.includes("$") || value.includes("₹") || value.includes("€") || value.includes("£"));

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.4, delay, type: "spring", stiffness: 300, damping: 24 }}
    >
      <Card className="border-0 shadow-card hover:shadow-card-hover transition-shadow duration-300">
        <CardContent className="p-6">
          <div className="flex items-start justify-between gap-4">
            <div className="space-y-1 min-w-0">
              <p className="text-sm font-medium text-muted-foreground">{title}</p>
              <div className="flex items-baseline gap-2 flex-wrap">
                <span className="text-3xl font-bold tracking-tight">
                  {isCurrency && typeof value === "string"
                    ? value
                    : typeof value === "number"
                    ? <CountUp target={value} />
                    : value}
                </span>
                {trend !== undefined && <TrendBadge value={trend} />}
              </div>
              {description && (
                <p className="text-xs text-muted-foreground">{description}</p>
              )}
            </div>
            <div className={cn("p-2.5 rounded-xl shrink-0", iconStyleMap[gradient])}>
              <Icon className="h-5 w-5" />
            </div>
          </div>
        </CardContent>
      </Card>
    </motion.div>
  );
}
