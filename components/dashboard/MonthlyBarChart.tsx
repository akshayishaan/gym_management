"use client";

import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  Tooltip,
  ResponsiveContainer,
  CartesianGrid,
} from "recharts";

interface TooltipPayloadEntry {
  name: string;
  value: number;
  color: string;
}

function ChartTooltip({
  active,
  payload,
  label,
  valueFormatter,
}: {
  active?: boolean;
  payload?: TooltipPayloadEntry[];
  label?: string;
  valueFormatter: (v: number) => string;
}) {
  if (active && payload && payload.length) {
    return (
      <div className="rounded-2xl border border-border/60 bg-card px-3 py-2 text-sm shadow-lg">
        <p className="font-medium text-foreground">{label}</p>
        {payload.map((entry) => (
          <p key={entry.name} className="mt-0.5 text-xs" style={{ color: entry.color }}>
            {entry.name}: {valueFormatter(entry.value)}
          </p>
        ))}
      </div>
    );
  }
  return null;
}

interface MonthlyBarChartProps {
  data: Array<{ month: string; value: number }>;
  name: string;
  color: string;
  valueFormatter?: (v: number) => string;
}

/**
 * Horizontally-scrollable bar chart — fixed per-bar width so all 12 months
 * stay readable (swipe instead of squeezing every label into 340px).
 */
export function MonthlyBarChart({ data, name, color, valueFormatter = (v) => String(v) }: MonthlyBarChartProps) {
  const barWidth = 44;
  const chartWidth = Math.max(data.length * barWidth, 320);

  return (
    <div className="hide-scrollbar -mx-1 overflow-x-auto px-1">
      <div style={{ width: chartWidth, height: 220 }}>
        <ResponsiveContainer width="100%" height="100%">
          <BarChart data={data} margin={{ top: 10, right: 8, left: 0, bottom: 0 }}>
            <CartesianGrid strokeDasharray="3 3" stroke="hsl(var(--border))" vertical={false} />
            <XAxis
              dataKey="month"
              tick={{ fontSize: 11, fill: "hsl(var(--muted-foreground))" }}
              axisLine={false}
              tickLine={false}
            />
            <YAxis
              tickFormatter={valueFormatter}
              tick={{ fontSize: 11, fill: "hsl(var(--muted-foreground))" }}
              axisLine={false}
              tickLine={false}
              width={40}
            />
            <Tooltip content={<ChartTooltip valueFormatter={valueFormatter} />} />
            <Bar dataKey="value" name={name} fill={color} radius={[6, 6, 0, 0]} isAnimationActive={false} />
          </BarChart>
        </ResponsiveContainer>
      </div>
    </div>
  );
}
