"use client";

import { useEffect, useState } from "react";
import { motion } from "framer-motion";
import { Card, CardContent } from "@/components/ui/card";
import { cn } from "@/lib/utils";
import { TrendingUp, TrendingDown, Minus } from "lucide-react";

interface StatCardProps {
  title: string;
  value: string | number;
  icon: React.ElementType;
  description?: string;
  trend?: number; // positive = up, negative = down, 0 = neutral
  gradient?: "blue" | "emerald" | "amber" | "rose" | "orange" | "violet";
  delay?: number;
}

const gradientMap = {
  blue: "bg-gradient-to-br from-blue-500 to-indigo-600 shadow-blue-500/20",
  emerald: "bg-gradient-to-br from-emerald-500 to-teal-600 shadow-emerald-500/20",
  amber: "bg-gradient-to-br from-amber-500 to-orange-500 shadow-amber-500/20",
  rose: "bg-gradient-to-br from-rose-500 to-pink-600 shadow-rose-500/20",
  orange: "bg-gradient-to-br from-orange-500 to-red-500 shadow-orange-500/20",
  violet: "bg-gradient-to-br from-violet-500 to-purple-600 shadow-violet-500/20",
};

function CountUp({ target, duration = 1200 }: { target: number; duration?: number }) {
  const [count, setCount] = useState(0);

  useEffect(() => {
    let start = 0;
    const end = target;
    if (end === 0) { setCount(0); return; }
    const startTime = performance.now();
    const animate = (now: number) => {
      const elapsed = now - startTime;
      const progress = Math.min(elapsed / duration, 1);
      const eased = 1 - Math.pow(1 - progress, 3);
      setCount(Math.floor(start + (end - start) * eased));
      if (progress < 1) requestAnimationFrame(animate);
      else setCount(end);
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
        isPositive ? "bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400" : "bg-rose-100 text-rose-700 dark:bg-rose-900/30 dark:text-rose-400"
      )}
    >
      <Icon className="h-3 w-3" />
      {Math.abs(value)}%
    </span>
  );
}

export function StatCard({ title, value, icon: Icon, description, trend, gradient = "orange", delay = 0 }: StatCardProps) {
  const numericValue = typeof value === "string" ? parseFloat(value.replace(/[^0-9.-]+/g, "")) : value;
  const isCurrency = typeof value === "string" && (value.includes("$") || value.includes("₹") || value.includes("€"));
  const displayValue = typeof value === "number" ? <CountUp target={value} /> : value;

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.4, delay, type: "spring", stiffness: 300, damping: 24 }}
    >
      <Card className="relative overflow-hidden group hover:shadow-card-hover transition-shadow duration-300 border-0 shadow-card">
        <CardContent className="p-6">
          <div className="flex items-start justify-between">
            <div className="space-y-2">
              <p className="text-sm font-medium text-muted-foreground">{title}</p>
              <div className="flex items-baseline gap-2">
                <span className="text-3xl font-bold tracking-tight">
                  {isCurrency && typeof value === "string" ? value.replace(/[\d,.]+/, "") : ""}
                  {typeof value === "number" ? displayValue : !isCurrency ? displayValue : null}
                  {isCurrency && typeof value === "string" ? value.match(/[\d,.]+/)?.[0] : null}
                </span>
                {trend !== undefined && <TrendBadge value={trend} />}
              </div>
              {description && (
                <p className="text-xs text-muted-foreground">{description}</p>
              )}
            </div>
            <div
              className={cn(
                "p-3 rounded-2xl text-white shadow-lg",
                gradientMap[gradient]
              )}
            >
              <Icon className="h-5 w-5" />
            </div>
          </div>
        </CardContent>
      </Card>
    </motion.div>
  );
}
