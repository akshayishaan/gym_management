"use client";

import { useEffect, useState } from "react";
import { motion } from "framer-motion";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { PageHeader } from "@/components/layout/PageHeader";
import { StatCard } from "@/components/dashboard/StatCard";
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  Tooltip,
  ResponsiveContainer,
  PieChart,
  Pie,
  Cell,
  CartesianGrid,
} from "recharts";
import { formatCurrency } from "@/lib/utils";
import { useGymSettings } from "@/lib/useGymSettings";
import { ChevronLeft, ChevronRight, TrendingUp, Users, CreditCard, Dumbbell } from "lucide-react";

const MONTHS = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"];
const COLORS = ["hsl(var(--primary))","#8b5cf6","#ec4899","#f59e0b","#10b981","#3b82f6","#14b8a6","#f97316"];

interface ReportData {
  monthlyRevenue: { _id: number; revenue: number; count: number }[];
  monthlyMembers: { _id: number; count: number }[];
  planDistribution: { _id: string; count: number }[];
  totalRevenue: number;
  year: number;
}

function CustomTooltip({ active, payload, label }: any) {
  if (active && payload && payload.length) {
    return (
      <div className="bg-card border rounded-lg shadow-lg px-3 py-2 text-sm">
        <p className="font-medium text-foreground">{label}</p>
        {payload.map((entry: any) => (
          <p key={entry.name} className="text-xs mt-0.5" style={{ color: entry.color }}>
            {entry.name}: {typeof entry.value === "number" && entry.value > 1000
              ? formatCurrency(entry.value)
              : entry.value}
          </p>
        ))}
      </div>
    );
  }
  return null;
}

export default function ReportsPage() {
  const { selectedGymId } = useGymSettings();
  const [data, setData] = useState<ReportData | null>(null);
  const [year, setYear] = useState(new Date().getFullYear());

  useEffect(() => {
    fetch(`/api/reports?year=${year}`).then(r => r.json()).then(setData);
  }, [year, selectedGymId]);

  if (!data) {
    return (
      <div className="space-y-6">
        <div className="h-10 w-48 bg-muted rounded-lg animate-pulse" />
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          {[...Array(3)].map((_, i) => (
            <div key={i} className="h-32 bg-card rounded-2xl border animate-pulse" />
          ))}
        </div>
        <div className="h-80 bg-card rounded-2xl border animate-pulse" />
      </div>
    );
  }

  const revenueChartData = MONTHS.map((m, i) => {
    const found = data.monthlyRevenue.find(r => r._id === i + 1);
    return { month: m, revenue: found?.revenue || 0, payments: found?.count || 0 };
  });

  const membersChartData = MONTHS.map((m, i) => {
    const found = data.monthlyMembers.find(r => r._id === i + 1);
    return { month: m, members: found?.count || 0 };
  });

  const totalMembers = data.monthlyMembers.reduce((s, m) => s + m.count, 0);
  const totalPayments = data.monthlyRevenue.reduce((s, m) => s + m.count, 0);
  const avgRevenue = data.monthlyRevenue.length > 0
    ? data.monthlyRevenue.reduce((s, m) => s + m.revenue, 0) / data.monthlyRevenue.length
    : 0;

  return (
    <div className="space-y-6">
      <PageHeader
        title="Reports"
        description={`Year ${year} overview`}
        actions={
          <div className="flex items-center gap-2">
            <Button
              variant="outline"
              size="sm"
              onClick={() => setYear(y => y - 1)}
              className="gap-1"
            >
              <ChevronLeft className="h-4 w-4" />
              {year - 1}
            </Button>
            <span className="text-sm font-medium px-2">{year}</span>
            <Button
              variant="outline"
              size="sm"
              onClick={() => setYear(y => y + 1)}
              className="gap-1"
            >
              {year + 1}
              <ChevronRight className="h-4 w-4" />
            </Button>
          </div>
        }
      />

      {/* Stats */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <StatCard
          title="Total Revenue"
          value={formatCurrency(data.totalRevenue)}
          icon={TrendingUp}
          gradient="orange"
          description={`Average ${formatCurrency(avgRevenue)}/month`}
        />
        <StatCard
          title="New Members"
          value={totalMembers}
          icon={Users}
          gradient="blue"
          description={`${Math.round(totalMembers / 12)} avg/month`}
        />
        <StatCard
          title="Total Payments"
          value={totalPayments}
          icon={CreditCard}
          gradient="emerald"
          description="Transactions processed"
        />
      </div>

      {/* Revenue Chart */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5 }}
      >
        <Card className="border-0 shadow-card hover:shadow-card-hover transition-shadow duration-300">
          <CardHeader className="pb-2">
            <div className="flex items-center gap-2">
              <div className="p-1.5 rounded-lg bg-primary/10">
                <TrendingUp className="h-4 w-4 text-primary" />
              </div>
              <CardTitle className="text-base font-semibold">Monthly Revenue ({year})</CardTitle>
            </div>
          </CardHeader>
          <CardContent>
            <div className="h-72">
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={revenueChartData} margin={{ top: 10, right: 10, left: 0, bottom: 0 }}>
                  <CartesianGrid strokeDasharray="3 3" stroke="hsl(var(--border))" vertical={false} />
                  <XAxis
                    dataKey="month"
                    tick={{ fontSize: 12, fill: "hsl(var(--muted-foreground))" }}
                    axisLine={false}
                    tickLine={false}
                  />
                  <YAxis
                    tickFormatter={(v) => `₹${(v/1000).toFixed(0)}k`}
                    tick={{ fontSize: 12, fill: "hsl(var(--muted-foreground))" }}
                    axisLine={false}
                    tickLine={false}
                  />
                  <Tooltip content={<CustomTooltip />} />
                  <Bar
                    dataKey="revenue"
                    name="Revenue"
                    fill="hsl(var(--primary))"
                    radius={[6, 6, 0, 0]}
                    animationDuration={1500}
                  />
                </BarChart>
              </ResponsiveContainer>
            </div>
          </CardContent>
        </Card>
      </motion.div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Members Chart */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, delay: 0.1 }}
        >
          <Card className="border-0 shadow-card hover:shadow-card-hover transition-shadow duration-300">
            <CardHeader className="pb-2">
              <div className="flex items-center gap-2">
                <div className="p-1.5 rounded-lg bg-blue-500/10">
                  <Users className="h-4 w-4 text-blue-500" />
                </div>
                <CardTitle className="text-base font-semibold">New Members per Month</CardTitle>
              </div>
            </CardHeader>
            <CardContent>
              <div className="h-64">
                <ResponsiveContainer width="100%" height="100%">
                  <BarChart data={membersChartData} margin={{ top: 10, right: 10, left: 0, bottom: 0 }}>
                    <CartesianGrid strokeDasharray="3 3" stroke="hsl(var(--border))" vertical={false} />
                    <XAxis
                      dataKey="month"
                      tick={{ fontSize: 12, fill: "hsl(var(--muted-foreground))" }}
                      axisLine={false}
                      tickLine={false}
                    />
                    <YAxis
                      tick={{ fontSize: 12, fill: "hsl(var(--muted-foreground))" }}
                      axisLine={false}
                      tickLine={false}
                    />
                    <Tooltip content={<CustomTooltip />} />
                    <Bar
                      dataKey="members"
                      name="New Members"
                      fill="#3b82f6"
                      radius={[6, 6, 0, 0]}
                      animationDuration={1500}
                    />
                  </BarChart>
                </ResponsiveContainer>
              </div>
            </CardContent>
          </Card>
        </motion.div>

        {/* Plan Distribution */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, delay: 0.2 }}
        >
          <Card className="border-0 shadow-card hover:shadow-card-hover transition-shadow duration-300">
            <CardHeader className="pb-2">
              <div className="flex items-center gap-2">
                <div className="p-1.5 rounded-lg bg-violet-500/10">
                  <Dumbbell className="h-4 w-4 text-violet-500" />
                </div>
                <CardTitle className="text-base font-semibold">Plan Distribution</CardTitle>
              </div>
            </CardHeader>
            <CardContent>
              {data.planDistribution.length === 0 ? (
                <div className="text-center py-12">
                  <div className="inline-flex items-center justify-center w-12 h-12 rounded-full bg-muted text-muted-foreground mb-3">
                    <Dumbbell className="h-6 w-6" />
                  </div>
                  <p className="text-sm font-medium text-muted-foreground">No data yet</p>
                  <p className="text-xs text-muted-foreground mt-1">Add members to see plan distribution</p>
                </div>
              ) : (
                <div className="h-64">
                  <ResponsiveContainer width="100%" height="100%">
                    <PieChart>
                      <Pie
                        data={data.planDistribution}
                        dataKey="count"
                        nameKey="_id"
                        cx="50%"
                        cy="50%"
                        outerRadius={80}
                        label={({ name, percent }) => `${name} ${(percent * 100).toFixed(0)}%`}
                        labelLine={false}
                      >
                        {data.planDistribution.map((_, i) => (
                          <Cell key={i} fill={COLORS[i % COLORS.length]} />
                        ))}
                      </Pie>
                      <Tooltip content={<CustomTooltip />} />
                    </PieChart>
                  </ResponsiveContainer>
                </div>
              )}
            </CardContent>
          </Card>
        </motion.div>
      </div>
    </div>
  );
}
