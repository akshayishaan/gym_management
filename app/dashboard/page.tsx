"use client";

import { useEffect, useState } from "react";
import { useSession } from "next-auth/react";
import { useRouter } from "next/navigation";
import { motion } from "framer-motion";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import { PageHeader } from "@/components/layout/PageHeader";
import { StatCard } from "@/components/dashboard/StatCard";
import { QuickActions } from "@/components/dashboard/QuickActions";
import { RevenueChart } from "@/components/dashboard/RevenueChart";
import { MemberTrendChart } from "@/components/dashboard/MemberTrendChart";
import {
  Users,
  TrendingUp,
  AlertTriangle,
  UserX,
  MessageCircle,
  Phone,
  ArrowRight,
  Wallet,
} from "lucide-react";
import {
  formatCurrency,
  formatDate,
  daysUntilExpiry,
  buildWhatsAppLink,
  buildSmsLink,
} from "@/lib/utils";
import Link from "next/link";

interface DashboardData {
  totalMembers: number;
  activeMembers: number;
  expiredMembers: number;
  expiringMembers: number;
  monthRevenue: number;
  recentPayments: {
    _id: string;
    memberName: string;
    amount: number;
    paidAt: string;
    method: string;
  }[];
  expiringList: {
    _id: string;
    name: string;
    phone: string;
    membershipExpiry: string;
    planName?: string;
  }[];
}

// Generate mock chart data from available metrics
function generateRevenueData(monthRevenue: number) {
  const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun"];
  return months.map((month, i) => ({
    month,
    revenue: Math.max(0, Math.round(monthRevenue * (0.6 + Math.random() * 0.8))),
  }));
}

function generateMemberTrendData(totalMembers: number, activeMembers: number) {
  const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun"];
  return months.map((month) => ({
    month,
    active: Math.round(activeMembers * (0.7 + Math.random() * 0.3)),
    new: Math.round(totalMembers * 0.05 + Math.random() * 10),
  }));
}

function getInitials(name: string) {
  return name
    .split(" ")
    .map((n) => n[0])
    .join("")
    .toUpperCase()
    .slice(0, 2);
}

const container = {
  hidden: { opacity: 0 },
  show: {
    opacity: 1,
    transition: { staggerChildren: 0.08 },
  },
};

const item = {
  hidden: { opacity: 0, y: 20 },
  show: { opacity: 1, y: 0, transition: { type: "spring" as const, stiffness: 300, damping: 24 } },
};

export default function DashboardPage() {
  const { data: session } = useSession();
  const router = useRouter();
  const [data, setData] = useState<DashboardData | null>(null);
  const [loading, setLoading] = useState(true);

  const isSuperAdmin = (session?.user as { role?: string })?.role === "superadmin";

  useEffect(() => {
    if (isSuperAdmin) {
      router.replace("/dashboard/superadmin");
    }
  }, [isSuperAdmin, router]);

  useEffect(() => {
    if (isSuperAdmin) return;
    fetch("/api/dashboard")
      .then((r) => r.json())
      .then((d) => {
        setData(d);
        setLoading(false);
      });
  }, [isSuperAdmin]);

  if (isSuperAdmin) return null;

  if (loading) {
    return (
      <div className="space-y-6">
        <div className="h-10 w-48 bg-muted rounded-lg animate-pulse" />
        <div className="h-14 bg-muted rounded-xl animate-pulse" />
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
          {[...Array(4)].map((_, i) => (
            <div key={i} className="h-32 bg-card rounded-2xl border animate-pulse" />
          ))}
        </div>
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {[...Array(2)].map((_, i) => (
            <div key={i} className="h-80 bg-card rounded-2xl border animate-pulse" />
          ))}
        </div>
      </div>
    );
  }

  if (!data) return null;

  const revenueData = generateRevenueData(data.monthRevenue);
  const memberTrendData = generateMemberTrendData(data.totalMembers, data.activeMembers);

  const reminderMessage = (name: string, expiry: string) =>
    `Hi ${name}, your gym membership expires on ${formatDate(expiry)}. Please renew to continue your fitness journey! 💪`;

  return (
    <motion.div
      variants={container}
      initial="hidden"
      animate="show"
      className="space-y-6"
    >
      <motion.div variants={item}>
        <PageHeader
          title="Dashboard"
          description="Welcome back! Here's your gym overview."
        />
      </motion.div>

      <motion.div variants={item}>
        <QuickActions />
      </motion.div>

      {/* Stats */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <StatCard
          title="Total Members"
          value={data.totalMembers}
          icon={Users}
          gradient="blue"
          description="All time registrations"
          delay={0}
        />
        <StatCard
          title="Active Members"
          value={data.activeMembers}
          icon={TrendingUp}
          gradient="emerald"
          description="Valid membership"
          trend={5}
          delay={0.05}
        />
        <StatCard
          title="Expiring Soon"
          value={data.expiringMembers}
          icon={AlertTriangle}
          gradient="amber"
          description="Within 7 days"
          delay={0.1}
        />
        <StatCard
          title="This Month Revenue"
          value={formatCurrency(data.monthRevenue)}
          icon={Wallet}
          gradient="orange"
          description="Collections so far"
          trend={12}
          delay={0.15}
        />
      </div>

      {/* Charts */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <RevenueChart data={revenueData} />
        <MemberTrendChart data={memberTrendData} />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Expiring Members */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, delay: 0.5 }}
        >
          <Card className="border-0 shadow-card hover:shadow-card-hover transition-shadow duration-300">
            <CardHeader className="flex flex-row items-center justify-between pb-3">
              <div className="flex items-center gap-2">
                <div className="p-1.5 rounded-lg bg-amber-500/10">
                  <AlertTriangle className="h-4 w-4 text-amber-500" />
                </div>
                <CardTitle className="text-base font-semibold">Expiring Soon</CardTitle>
              </div>
              <Link href="/dashboard/members?status=expiring">
                <Button variant="ghost" size="sm" className="gap-1">
                  View all <ArrowRight className="h-3.5 w-3.5" />
                </Button>
              </Link>
            </CardHeader>
            <CardContent>
              {(data.expiringList?.length ?? 0) === 0 ? (
                <div className="text-center py-8">
                  <div className="inline-flex items-center justify-center w-12 h-12 rounded-full bg-emerald-100 text-emerald-600 mb-3">
                    <Users className="h-6 w-6" />
                  </div>
                  <p className="text-sm text-muted-foreground font-medium">No members expiring soon</p>
                  <p className="text-xs text-muted-foreground mt-1">All memberships are up to date 🎉</p>
                </div>
              ) : (
                <div className="space-y-3">
                  {(data.expiringList ?? []).map((m) => {
                    const days = daysUntilExpiry(m.membershipExpiry);
                    const msg = reminderMessage(m.name, m.membershipExpiry);
                    return (
                      <div
                        key={m._id}
                        className="flex items-center justify-between gap-3 p-2 rounded-xl hover:bg-muted/50 transition-colors group"
                      >
                        <div className="flex items-center gap-3 min-w-0 flex-1">
                          <Avatar className="h-9 w-9 border-2 border-background shadow-sm">
                            <AvatarFallback className="bg-primary/10 text-primary text-xs font-bold">
                              {getInitials(m.name)}
                            </AvatarFallback>
                          </Avatar>
                          <div className="min-w-0 flex-1">
                            <p className="font-medium text-sm truncate">{m.name}</p>
                            <p className="text-xs text-muted-foreground">
                              {m.planName || "No plan"} · {formatDate(m.membershipExpiry)}
                            </p>
                          </div>
                        </div>
                        <div className="flex items-center gap-1 shrink-0">
                          <Badge
                            variant={days <= 3 ? "destructive" : "warning"}
                            className="text-xs"
                          >
                            {days === 0 ? "Today" : `${days}d`}
                          </Badge>
                          <a
                            href={buildWhatsAppLink(m.phone, msg)}
                            target="_blank"
                            rel="noreferrer"
                          >
                            <Button
                              size="icon"
                              variant="ghost"
                              className="h-8 w-8 text-green-600 hover:bg-green-50 hover:text-green-700"
                              title="WhatsApp"
                            >
                              <MessageCircle className="h-3.5 w-3.5" />
                            </Button>
                          </a>
                          <a href={buildSmsLink(m.phone, msg)}>
                            <Button
                              size="icon"
                              variant="ghost"
                              className="h-8 w-8 text-blue-600 hover:bg-blue-50 hover:text-blue-700"
                              title="SMS"
                            >
                              <Phone className="h-3.5 w-3.5" />
                            </Button>
                          </a>
                        </div>
                      </div>
                    );
                  })}
                </div>
              )}
            </CardContent>
          </Card>
        </motion.div>

        {/* Recent Payments */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, delay: 0.6 }}
        >
          <Card className="border-0 shadow-card hover:shadow-card-hover transition-shadow duration-300">
            <CardHeader className="flex flex-row items-center justify-between pb-3">
              <div className="flex items-center gap-2">
                <div className="p-1.5 rounded-lg bg-emerald-500/10">
                  <Wallet className="h-4 w-4 text-emerald-500" />
                </div>
                <CardTitle className="text-base font-semibold">Recent Payments</CardTitle>
              </div>
              <Link href="/dashboard/payments">
                <Button variant="ghost" size="sm" className="gap-1">
                  View all <ArrowRight className="h-3.5 w-3.5" />
                </Button>
              </Link>
            </CardHeader>
            <CardContent>
              {(data.recentPayments?.length ?? 0) === 0 ? (
                <div className="text-center py-8">
                  <div className="inline-flex items-center justify-center w-12 h-12 rounded-full bg-muted text-muted-foreground mb-3">
                    <Wallet className="h-6 w-6" />
                  </div>
                  <p className="text-sm text-muted-foreground font-medium">No payments yet</p>
                  <p className="text-xs text-muted-foreground mt-1">Record your first payment to see it here</p>
                </div>
              ) : (
                <div className="space-y-3">
                  {(data.recentPayments ?? []).map((p) => (
                    <div
                      key={p._id}
                      className="flex items-center justify-between gap-3 p-2 rounded-xl hover:bg-muted/50 transition-colors"
                    >
                      <div className="flex items-center gap-3 min-w-0 flex-1">
                        <Avatar className="h-9 w-9 border-2 border-background shadow-sm">
                          <AvatarFallback className="bg-emerald-100 text-emerald-700 text-xs font-bold">
                            {getInitials(p.memberName)}
                          </AvatarFallback>
                        </Avatar>
                        <div className="min-w-0 flex-1">
                          <p className="font-medium text-sm truncate">{p.memberName}</p>
                          <p className="text-xs text-muted-foreground capitalize">
                            {p.method.replace("_", " ")} · {formatDate(p.paidAt)}
                          </p>
                        </div>
                      </div>
                      <span className="font-semibold text-sm text-emerald-600 shrink-0">
                        {formatCurrency(p.amount)}
                      </span>
                    </div>
                  ))}
                </div>
              )}
            </CardContent>
          </Card>
        </motion.div>
      </div>
    </motion.div>
  );
}
