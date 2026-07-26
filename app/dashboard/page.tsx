"use client";

import { useState } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import { QuickActions } from "@/components/dashboard/QuickActions";
import { MemberForm } from "@/components/dashboard/MemberForm";
import {
  Users,
  AlertTriangle,
  MessageCircle,
  Phone,
  ArrowRight,
  Wallet,
  ArrowUpRight,
} from "lucide-react";
import {
  formatCurrency,
  formatDate,
  daysUntilExpiry,
  buildWhatsAppLink,
  buildSmsLink,
} from "@/lib/utils";
import Link from "next/link";
import { useGymSettings } from "@/lib/useGymSettings";
import { useDashboard, useInvalidateDashboard } from "@/lib/hooks/useDashboard";

function getInitials(name: string) {
  return name
    .split(" ")
    .map((n) => n[0])
    .join("")
    .toUpperCase()
    .slice(0, 2);
}

export default function DashboardPage() {
  const { currency, timezone } = useGymSettings();
  const { data, isLoading: loading } = useDashboard();
  const invalidateDashboard = useInvalidateDashboard();
  const [addMemberOpen, setAddMemberOpen] = useState(false);

  if (loading) {
    return (
      <div className="space-y-6">
        <div className="h-52 animate-pulse rounded-[2rem] bg-foreground/10" />
        <div className="h-24 animate-pulse rounded-[1.75rem] bg-card" />
        <div className="h-64 animate-pulse rounded-[1.75rem] bg-card" />
      </div>
    );
  }

  if (!data) return null;

  const reminderMessage = (name: string, expiry: string) =>
    `Hi ${name}, your gym membership expires on ${formatDate(expiry)}. Please renew to continue your fitness journey! 💪`;

  return (
    <div className="space-y-6">
      <section className="relative overflow-hidden rounded-[2rem] bg-foreground p-5 text-background shadow-xl shadow-foreground/15">
        <div className="absolute -right-12 -top-16 h-40 w-40 rounded-full bg-primary/70 blur-2xl" />
        <div className="absolute -bottom-20 -left-8 h-36 w-36 rounded-full bg-success/35 blur-2xl" />
        <div className="relative">
          <div className="flex items-start justify-between gap-3">
            <div>
              <p className="text-[10px] font-bold uppercase tracking-[0.18em] text-background/55">
                Revenue this month
              </p>
              <p className="mt-1 font-display text-[2rem] font-extrabold tracking-[-0.05em]">
                {formatCurrency(data.monthRevenue, currency)}
              </p>
            </div>
            <span className="flex h-11 w-11 items-center justify-center rounded-2xl bg-background/10 text-primary backdrop-blur">
              <ArrowUpRight className="h-5 w-5" />
            </span>
          </div>
          <div className="mt-7 grid grid-cols-3 divide-x divide-background/10 rounded-2xl bg-background/[0.07] py-3 backdrop-blur">
            <div className="px-3">
              <p className="text-xl font-extrabold">{data.totalMembers}</p>
              <p className="mt-0.5 text-[10px] font-semibold text-background/55">Members</p>
            </div>
            <div className="px-3">
              <p className="text-xl font-extrabold text-success">{data.activeMembers}</p>
              <p className="mt-0.5 text-[10px] font-semibold text-background/55">Active</p>
            </div>
            <div className="px-3">
              <p className="text-xl font-extrabold text-warning">{data.expiringMembers}</p>
              <p className="mt-0.5 text-[10px] font-semibold text-background/55">Expiring</p>
            </div>
          </div>
        </div>
      </section>

      <section className="space-y-3">
        <p className="app-section-label px-1">Quick actions</p>
        <QuickActions onAddMember={() => setAddMemberOpen(true)} />
      </section>

      {/* Expiring Members */}
      <Card className="overflow-hidden border-0 shadow-card">
        <CardHeader className="flex flex-row items-center justify-between px-4 pb-2 pt-4">
          <div className="flex items-center gap-2">
            <div className="rounded-xl bg-warning/15 p-2">
              <AlertTriangle className="h-4 w-4 text-warning-foreground dark:text-warning" />
            </div>
            <CardTitle className="text-base font-semibold">Expiring Soon</CardTitle>
          </div>
          <Link href="/dashboard/members?status=expiring">
            <Button variant="ghost" size="sm" className="h-9 gap-1 px-2 text-xs text-primary">
              All <ArrowRight className="h-3.5 w-3.5" />
            </Button>
          </Link>
        </CardHeader>
        <CardContent className="px-3 pb-3">
          {(data.expiringList?.length ?? 0) === 0 ? (
            <div className="py-8 text-center">
              <div className="mb-3 inline-flex h-12 w-12 items-center justify-center rounded-full bg-success/10 text-success">
                <Users className="h-6 w-6" />
              </div>
              <p className="text-sm font-medium">No members expiring soon</p>
              <p className="mt-1 text-xs text-muted-foreground">All memberships are up to date</p>
            </div>
          ) : (
            <div className="divide-y divide-border/60">
              {(data.expiringList ?? []).map((m) => {
                const days = daysUntilExpiry(m.membershipExpiry, timezone);
                const msg = reminderMessage(m.name, m.membershipExpiry);
                return (
                  <div
                    key={m._id}
                    className="flex min-h-[4.25rem] items-center justify-between gap-3 rounded-xl px-1 py-2.5 active:bg-muted/60"
                  >
                    <div className="flex min-w-0 flex-1 items-center gap-3">
                      <Avatar className="h-10 w-10 shrink-0">
                        <AvatarFallback className="bg-primary/10 text-xs font-semibold text-primary">
                          {getInitials(m.name)}
                        </AvatarFallback>
                      </Avatar>
                      <div className="min-w-0 flex-1">
                        <p className="truncate text-sm font-medium">{m.name}</p>
                        <p className="truncate text-xs text-muted-foreground">
                          {m.planName || "No plan"} · {formatDate(m.membershipExpiry)}
                        </p>
                      </div>
                    </div>
                    <div className="flex shrink-0 items-center gap-1">
                      <Badge variant={days <= 3 ? "destructive" : "warning"} className="text-xs">
                        {days === 0 ? "Today" : `${days}d`}
                      </Badge>
                      <a href={buildWhatsAppLink(m.phone, msg)} target="_blank" rel="noreferrer">
                        <Button aria-label={`WhatsApp ${m.name}`} size="icon" variant="ghost" className="h-9 w-9 rounded-xl text-success hover:bg-success/10">
                          <MessageCircle className="h-3.5 w-3.5" />
                        </Button>
                      </a>
                      <a href={buildSmsLink(m.phone, msg)}>
                        <Button aria-label={`Text ${m.name}`} size="icon" variant="ghost" className="h-9 w-9 rounded-xl text-primary hover:bg-primary/10">
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

      {/* Recent Payments */}
      <Card className="overflow-hidden border-0 shadow-card">
        <CardHeader className="flex flex-row items-center justify-between px-4 pb-2 pt-4">
          <div className="flex items-center gap-2">
            <div className="rounded-xl bg-success/10 p-2">
              <Wallet className="h-4 w-4 text-success" />
            </div>
            <CardTitle className="text-base font-semibold">Recent Payments</CardTitle>
          </div>
          <Link href="/dashboard/payments">
            <Button variant="ghost" size="sm" className="h-9 gap-1 px-2 text-xs text-primary">
              All <ArrowRight className="h-3.5 w-3.5" />
            </Button>
          </Link>
        </CardHeader>
        <CardContent className="px-3 pb-3">
          {(data.recentPayments?.length ?? 0) === 0 ? (
            <div className="py-8 text-center">
              <div className="mb-3 inline-flex h-12 w-12 items-center justify-center rounded-full bg-muted text-muted-foreground">
                <Wallet className="h-6 w-6" />
              </div>
              <p className="text-sm font-medium">No payments yet</p>
              <p className="mt-1 text-xs text-muted-foreground">Record your first payment to see it here</p>
            </div>
          ) : (
            <div className="divide-y divide-border/60">
              {(data.recentPayments ?? []).map((p) => (
                <div
                  key={p._id}
                  className="flex min-h-[4.25rem] items-center justify-between gap-3 rounded-xl px-1 py-2.5 active:bg-muted/60"
                >
                  <div className="flex min-w-0 flex-1 items-center gap-3">
                    <Avatar className="h-10 w-10 shrink-0">
                      <AvatarFallback className="bg-success/10 text-xs font-semibold text-success">
                        {getInitials(p.memberName)}
                      </AvatarFallback>
                    </Avatar>
                    <div className="min-w-0 flex-1">
                      <p className="truncate text-sm font-medium">{p.memberName}</p>
                      <p className="truncate text-xs capitalize text-muted-foreground">
                        {p.method.replace("_", " ")} · {formatDate(p.paidAt)}
                      </p>
                    </div>
                  </div>
                  <span className="shrink-0 text-sm font-bold text-success">
                    {formatCurrency(p.amount, currency)}
                  </span>
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>

      <MemberForm
        mode="create"
        variant="sheet"
        open={addMemberOpen}
        onOpenChange={setAddMemberOpen}
        onSuccess={() => {
          setAddMemberOpen(false);
          void invalidateDashboard();
        }}
      />
    </div>
  );
}
