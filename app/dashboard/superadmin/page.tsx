"use client";

import { useEffect, useState } from "react";
import { motion } from "framer-motion";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { StatCard } from "@/components/dashboard/StatCard";
import { PageHeader } from "@/components/layout/PageHeader";
import { Building2, Users, DollarSign, TrendingUp } from "lucide-react";

interface OverviewData {
  totalGyms: number;
  totalMembers: number;
  totalRevenue: number;
}

export default function SuperAdminOverviewPage() {
  const [data, setData] = useState<OverviewData | null>(null);

  useEffect(() => {
    fetch("/api/dashboard")
      .then((r) => r.json())
      .then(setData);
  }, []);

  if (!data) {
    return (
      <div className="space-y-6">
        <div className="h-10 w-48 bg-muted rounded-lg animate-pulse" />
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
          {[...Array(3)].map((_, i) => (
            <div key={i} className="h-32 bg-card rounded-2xl border animate-pulse" />
          ))}
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <PageHeader
        title="Platform Overview"
        description="All gyms managed on this platform"
      />

      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <StatCard
          title="Active Gyms"
          value={data.totalGyms}
          icon={Building2}
          gradient="blue"
          description="Registered & active"
        />
        <StatCard
          title="Total Members"
          value={data.totalMembers}
          icon={Users}
          gradient="emerald"
          description="Across all gyms"
        />
        <StatCard
          title="Total Revenue"
          value={`₹${data.totalRevenue?.toLocaleString("en-IN") ?? 0}`}
          icon={DollarSign}
          gradient="orange"
          description="All-time payments"
        />
      </div>
    </div>
  );
}
