"use client";

import { useId, useState } from "react";
import { Area, AreaChart, CartesianGrid, ResponsiveContainer, Tooltip, XAxis } from "recharts";
import type { ReportSeriesPoint } from "@/lib/reportTypes";
import { formatCurrency } from "@/lib/utils";
import { cn } from "@/lib/utils";

const MONTHS = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];

type TrendMetric = "revenue" | "newMembers" | "renewals";

const METRICS: Array<{
  key: TrendMetric;
  label: string;
  color: string;
}> = [
  { key: "revenue", label: "Revenue", color: "hsl(var(--primary))" },
  { key: "newMembers", label: "Members", color: "hsl(var(--accent-foreground))" },
  { key: "renewals", label: "Renewals", color: "hsl(var(--success))" },
];

interface TrendTooltipProps {
  active?: boolean;
  label?: string;
  payload?: Array<{ value?: number }>;
  metric: TrendMetric;
  currency: string;
}

function TrendTooltip({ active, label, payload, metric, currency }: TrendTooltipProps) {
  if (!active || !payload?.length) return null;
  const value = payload[0]?.value ?? 0;

  return (
    <div className="rounded-2xl border border-border/60 bg-card px-3 py-2 shadow-xl">
      <p className="text-[10px] font-bold uppercase tracking-wider text-muted-foreground">{label}</p>
      <p className="mt-0.5 text-sm font-extrabold text-foreground">
        {metric === "revenue" ? formatCurrency(value, currency) : value.toLocaleString()}
      </p>
    </div>
  );
}

export function ReportTrendChart({
  series,
  currency,
}: {
  series: ReportSeriesPoint[];
  currency: string;
}) {
  const [metric, setMetric] = useState<TrendMetric>("revenue");
  const gradientId = `report-trend-${useId().replace(/:/g, "")}`;
  const selectedMetric = METRICS.find((item) => item.key === metric) ?? METRICS[0];
  const data = series.map((point) => ({ ...point, label: MONTHS[point.month - 1] }));

  return (
    <div>
      <div className="mb-5 grid grid-cols-3 gap-1 rounded-2xl bg-muted/70 p-1.5">
        {METRICS.map((item) => (
          <button
            key={item.key}
            type="button"
            onClick={() => setMetric(item.key)}
            className={cn(
              "h-9 rounded-xl text-xs font-bold transition-all active:scale-[0.98]",
              metric === item.key
                ? "bg-card text-foreground shadow-sm"
                : "text-muted-foreground"
            )}
          >
            {item.label}
          </button>
        ))}
      </div>

      <div className="h-52 w-full">
        <ResponsiveContainer width="100%" height="100%">
          <AreaChart data={data} margin={{ top: 8, right: 4, left: 4, bottom: 0 }}>
            <defs>
              <linearGradient id={gradientId} x1="0" y1="0" x2="0" y2="1">
                <stop offset="0%" stopColor={selectedMetric.color} stopOpacity={0.28} />
                <stop offset="100%" stopColor={selectedMetric.color} stopOpacity={0} />
              </linearGradient>
            </defs>
            <CartesianGrid vertical={false} stroke="hsl(var(--border))" strokeDasharray="3 5" />
            <XAxis
              dataKey="label"
              axisLine={false}
              tickLine={false}
              interval={1}
              tick={{ fontSize: 10, fontWeight: 700, fill: "hsl(var(--muted-foreground))" }}
              dy={8}
            />
            <Tooltip
              cursor={{ stroke: selectedMetric.color, strokeOpacity: 0.25 }}
              content={<TrendTooltip metric={metric} currency={currency} />}
            />
            <Area
              key={metric}
              type="monotone"
              dataKey={metric}
              stroke={selectedMetric.color}
              strokeWidth={3}
              fill={`url(#${gradientId})`}
              dot={false}
              activeDot={{ r: 5, fill: selectedMetric.color, stroke: "hsl(var(--card))", strokeWidth: 3 }}
              animationDuration={450}
            />
          </AreaChart>
        </ResponsiveContainer>
      </div>
    </div>
  );
}
