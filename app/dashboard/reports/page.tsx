"use client";

import { useState } from "react";
import Link from "next/link";
import {
  AlertTriangle,
  ArrowDownRight,
  ArrowRight,
  ArrowUpRight,
  CalendarClock,
  ChevronLeft,
  ChevronRight,
  CircleDollarSign,
  CreditCard,
  Dumbbell,
  RefreshCw,
  Repeat2,
  Trophy,
  Users,
  WalletCards,
} from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { StackHeader } from "@/components/layout/StackHeader";
import { ReportTrendChart } from "@/components/dashboard/ReportTrendChart";
import type { ReportComparisonMetric } from "@/lib/reportTypes";
import { formatCurrency } from "@/lib/utils";
import { useGymSettings } from "@/lib/useGymSettings";
import { cn } from "@/lib/utils";
import { useReports } from "@/lib/hooks/useReports";
import { todayInTimeZone } from "@/lib/membershipCalendar";

const MONTHS = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];

const METHOD_LABELS: Record<string, string> = {
  cash: "Cash",
  card: "Card",
  upi: "UPI",
  bank_transfer: "Bank transfer",
  other: "Other",
};

const METHOD_COLORS = [
  "hsl(var(--primary))",
  "hsl(var(--success))",
  "hsl(var(--warning))",
  "hsl(var(--accent-foreground))",
  "hsl(var(--muted-foreground))",
];

function ComparisonPill({
  metric,
  previousYear,
  onPrimary = false,
}: {
  metric: ReportComparisonMetric;
  previousYear: number;
  onPrimary?: boolean;
}) {
  if (metric.changePercent === null) {
    return (
      <span className="rounded-full bg-primary-foreground/15 px-2.5 py-1 text-[10px] font-extrabold">
        New vs {previousYear}
      </span>
    );
  }

  const positive = metric.changePercent > 0;
  const unchanged = metric.changePercent === 0;

  return (
    <span
      className={cn(
        "inline-flex items-center gap-1 rounded-full px-2 py-1 text-[10px] font-extrabold",
        onPrimary
          ? "bg-primary-foreground/15 text-primary-foreground"
          : unchanged
          ? "bg-muted text-muted-foreground"
          : positive
          ? "bg-success/10 text-success"
          : "bg-destructive/10 text-destructive"
      )}
    >
      {!unchanged && (positive ? <ArrowUpRight className="h-3 w-3" /> : <ArrowDownRight className="h-3 w-3" />)}
      {unchanged ? "No change" : `${Math.abs(metric.changePercent)}%`}
    </span>
  );
}

function MetricCard({
  label,
  value,
  icon: Icon,
  tone,
  comparison,
  previousYear,
  detail,
}: {
  label: string;
  value: string | number;
  icon: React.ElementType;
  tone: string;
  comparison?: ReportComparisonMetric;
  previousYear: number;
  detail?: string;
}) {
  return (
    <div className="app-surface min-w-0 rounded-[1.6rem] p-4">
      <div className="flex items-start justify-between gap-2">
        <span className={cn("flex h-10 w-10 items-center justify-center rounded-2xl", tone)}>
          <Icon className="h-4 w-4" />
        </span>
        {comparison && <ComparisonPill metric={comparison} previousYear={previousYear} />}
      </div>
      <p className="mt-4 truncate font-display text-xl font-extrabold tracking-[-0.04em]">{value}</p>
      <p className="mt-0.5 text-xs font-bold text-muted-foreground">{label}</p>
      {detail && <p className="mt-1 truncate text-[10px] font-semibold text-muted-foreground">{detail}</p>}
    </div>
  );
}

function LoadingReports() {
  return (
    <div className="app-canvas flex min-h-svh flex-col">
      <StackHeader title="Reports" />
      <div className="flex-1 space-y-4 px-5 py-5">
        <div className="h-52 animate-pulse rounded-[2rem] bg-primary/10" />
        <div className="grid grid-cols-2 gap-3">
          {[0, 1, 2, 3].map((item) => (
            <div key={item} className="h-36 animate-pulse rounded-[1.6rem] bg-card" />
          ))}
        </div>
        <div className="h-80 animate-pulse rounded-[2rem] bg-card" />
      </div>
    </div>
  );
}

export default function ReportsPage() {
  const { currency, timezone } = useGymSettings();
  const currentYear = Number(todayInTimeZone(timezone).slice(0, 4));
  const [year, setYear] = useState(currentYear);
  const { data, isLoading: loading, isError: error, refetch } = useReports(year);

  if (loading && !data) return <LoadingReports />;

  if (error || !data) {
    return (
      <div className="app-canvas flex min-h-svh flex-col">
        <StackHeader title="Reports" />
        <div className="flex flex-1 items-center justify-center px-5">
          <div className="app-surface w-full rounded-[2rem] px-6 py-12 text-center">
            <div className="mx-auto flex h-14 w-14 items-center justify-center rounded-[1.25rem] bg-destructive/10 text-destructive">
              <AlertTriangle className="h-6 w-6" />
            </div>
            <h2 className="mt-5 font-display text-lg font-extrabold">Couldn&apos;t load reports</h2>
            <p className="mt-1 text-sm text-muted-foreground">Check the database connection and try again.</p>
            <Button className="mt-5" onClick={() => void refetch()}>
              <RefreshCw className="h-4 w-4" /> Try again
            </Button>
          </div>
        </div>
      </div>
    );
  }

  const previousYear = year - 1;
  const maxPlanRevenue = Math.max(...data.planPerformance.map((plan) => plan.revenue), 0);
  const bestMonth = data.insights.bestMonth;

  return (
    <div className="app-canvas flex min-h-svh flex-col">
      <StackHeader
        title="Reports"
        actions={
          <div className="flex items-center gap-0.5 rounded-2xl bg-muted/70 p-0.5">
            <Button
              aria-label="Previous year"
              variant="ghost"
              size="icon"
              className="h-8 w-8 rounded-xl"
              onClick={() => setYear((selectedYear) => selectedYear - 1)}
            >
              <ChevronLeft className="h-4 w-4" />
            </Button>
            <span className="min-w-[3rem] text-center text-xs font-extrabold">{year}</span>
            <Button
              aria-label="Next year"
              variant="ghost"
              size="icon"
              className="h-8 w-8 rounded-xl"
              disabled={year >= currentYear}
              onClick={() => setYear((selectedYear) => Math.min(currentYear, selectedYear + 1))}
            >
              <ChevronRight className="h-4 w-4" />
            </Button>
          </div>
        }
      />

      <div
        className="app-screen flex-1 space-y-6 px-5 py-5"
        style={{ paddingBottom: "calc(1.5rem + env(safe-area-inset-bottom))" }}
      >
        <section className="relative overflow-hidden rounded-[2rem] bg-primary p-5 text-primary-foreground shadow-xl shadow-primary/20">
          <div className="absolute -right-12 -top-14 h-40 w-40 rounded-full border-[26px] border-primary-foreground/10" />
          <div className="absolute -bottom-20 -left-8 h-36 w-36 rounded-full bg-primary-foreground/10 blur-2xl" />
          <div className="relative">
            <div className="flex items-start justify-between gap-4">
              <span className="flex h-11 w-11 items-center justify-center rounded-2xl bg-primary-foreground/15">
                <CircleDollarSign className="h-5 w-5" />
              </span>
              <ComparisonPill metric={data.summary.revenue} previousYear={previousYear} onPrimary />
            </div>
            <p className="mt-7 text-[10px] font-extrabold uppercase tracking-[0.18em] text-primary-foreground/65">
              Collected in {year}
            </p>
            <p className="mt-1 font-display text-[2.25rem] font-extrabold tracking-[-0.055em]">
              {formatCurrency(data.summary.revenue.value, currency)}
            </p>
            <div className="mt-5 flex items-center justify-between gap-4 rounded-2xl bg-primary-foreground/10 px-4 py-3">
              <div>
                <p className="text-lg font-extrabold">{data.summary.activeMembers}</p>
                <p className="text-[10px] font-bold text-primary-foreground/60">Active now</p>
              </div>
              <div className="h-8 w-px bg-primary-foreground/15" />
              <div className="min-w-0 flex-1 text-right">
                <p className="truncate text-lg font-extrabold">{formatCurrency(data.summary.outstandingDues, currency)}</p>
                <p className="text-[10px] font-bold text-primary-foreground/60">Outstanding now</p>
              </div>
            </div>
          </div>
        </section>

        <section className="space-y-3">
          <p className="app-section-label px-1">Year at a glance</p>
          <div className="grid grid-cols-2 gap-3">
            <MetricCard
              label="Transactions"
              value={data.summary.transactions.value}
              icon={CreditCard}
              tone="bg-primary/10 text-primary"
              comparison={data.summary.transactions}
              previousYear={previousYear}
            />
            <MetricCard
              label="New members"
              value={data.summary.newMembers.value}
              icon={Users}
              tone="bg-accent text-accent-foreground"
              comparison={data.summary.newMembers}
              previousYear={previousYear}
            />
            <MetricCard
              label="Renewals"
              value={data.summary.renewals.value}
              icon={Repeat2}
              tone="bg-success/10 text-success"
              comparison={data.summary.renewals}
              previousYear={previousYear}
            />
            <MetricCard
              label="Members with dues"
              value={data.summary.dueMembers}
              icon={WalletCards}
              tone="bg-warning/15 text-warning-foreground dark:text-warning"
              previousYear={previousYear}
              detail={formatCurrency(data.summary.outstandingDues, currency)}
            />
          </div>
        </section>

        <Card className="overflow-hidden rounded-[2rem] border-0 shadow-card">
          <CardHeader className="px-5 pb-2 pt-5">
            <CardTitle className="font-display text-lg font-extrabold">Year in motion</CardTitle>
            <p className="text-xs text-muted-foreground">Switch the signal to compare monthly movement.</p>
          </CardHeader>
          <CardContent className="px-4 pb-5 pt-2">
            <ReportTrendChart series={data.series} currency={currency} />
          </CardContent>
        </Card>

        <section className="space-y-3">
          <p className="app-section-label px-1">Live member health</p>
          <div className="app-surface divide-y divide-border/60 overflow-hidden rounded-[1.75rem] px-2">
            <Link
              href="/dashboard/members?status=expiring30"
              className="flex min-h-[4.4rem] items-center gap-3 rounded-2xl px-2 py-3 active:bg-muted/60"
            >
              <span className="flex h-10 w-10 items-center justify-center rounded-2xl bg-warning/15 text-warning-foreground dark:text-warning">
                <CalendarClock className="h-4 w-4" />
              </span>
              <div className="min-w-0 flex-1">
                <p className="text-sm font-bold">Expiring in 30 days</p>
                <p className="text-xs text-muted-foreground">Members to contact before renewal</p>
              </div>
              <span className="text-sm font-extrabold">{data.insights.expiringSoon}</span>
              <ArrowRight className="h-4 w-4 text-muted-foreground" />
            </Link>

            <Link
              href="/dashboard/members?status=due"
              className="flex min-h-[4.4rem] items-center gap-3 rounded-2xl px-2 py-3 active:bg-muted/60"
            >
              <span className="flex h-10 w-10 items-center justify-center rounded-2xl bg-destructive/10 text-destructive">
                <WalletCards className="h-4 w-4" />
              </span>
              <div className="min-w-0 flex-1">
                <p className="text-sm font-bold">Outstanding dues</p>
                <p className="truncate text-xs text-muted-foreground">
                  {data.insights.dueMembers} member{data.insights.dueMembers !== 1 ? "s" : ""}
                </p>
              </div>
              <span className="max-w-[7rem] truncate text-sm font-extrabold text-destructive">
                {formatCurrency(data.insights.outstandingDues, currency)}
              </span>
              <ArrowRight className="h-4 w-4 text-muted-foreground" />
            </Link>

            <Link
              href="/dashboard/members?status=expired"
              className="flex min-h-[4.4rem] items-center gap-3 rounded-2xl px-2 py-3 active:bg-muted/60"
            >
              <span className="flex h-10 w-10 items-center justify-center rounded-2xl bg-muted text-muted-foreground">
                <AlertTriangle className="h-4 w-4" />
              </span>
              <div className="min-w-0 flex-1">
                <p className="text-sm font-bold">Expired memberships</p>
                <p className="text-xs text-muted-foreground">Members available to win back</p>
              </div>
              <span className="text-sm font-extrabold">{data.insights.expiredMembers}</span>
              <ArrowRight className="h-4 w-4 text-muted-foreground" />
            </Link>

            <div className="flex min-h-[4.4rem] items-center gap-3 px-2 py-3">
              <span className="flex h-10 w-10 items-center justify-center rounded-2xl bg-success/10 text-success">
                <Trophy className="h-4 w-4" />
              </span>
              <div className="min-w-0 flex-1">
                <p className="text-sm font-bold">Best month</p>
                <p className="text-xs text-muted-foreground">
                  {bestMonth ? MONTHS[bestMonth.month - 1] : "No revenue recorded"}
                </p>
              </div>
              {bestMonth && (
                <span className="max-w-[8rem] truncate text-sm font-extrabold text-success">
                  {formatCurrency(bestMonth.revenue, currency)}
                </span>
              )}
            </div>
          </div>
        </section>

        <Card className="overflow-hidden rounded-[2rem] border-0 shadow-card">
          <CardHeader className="px-5 pb-3 pt-5">
            <div className="flex items-center gap-3">
              <span className="flex h-10 w-10 items-center justify-center rounded-2xl bg-secondary text-secondary-foreground">
                <Dumbbell className="h-4 w-4" />
              </span>
              <div>
                <CardTitle className="font-display text-lg font-extrabold">Plan performance</CardTitle>
                <p className="mt-0.5 text-xs text-muted-foreground">Net cash tied to Plan sales in {year}</p>
              </div>
            </div>
          </CardHeader>
          <CardContent className="px-5 pb-5">
            {data.planPerformance.length === 0 ? (
              <div className="py-8 text-center text-sm text-muted-foreground">No plan sales in {year}</div>
            ) : (
              <div className="space-y-5">
                {data.planPerformance.map((plan) => {
                  const percentage = maxPlanRevenue > 0 ? Math.round((plan.revenue / maxPlanRevenue) * 100) : 0;
                  return (
                    <div key={plan.key}>
                      <div className="flex items-start justify-between gap-3">
                        <div className="min-w-0">
                          <p className="truncate text-sm font-bold">{plan.name}</p>
                          <p className="mt-0.5 text-[11px] text-muted-foreground">
                            {plan.sales} sale{plan.sales !== 1 ? "s" : ""} · {plan.activeMembers} active now
                          </p>
                        </div>
                        <p className="shrink-0 text-sm font-extrabold">{formatCurrency(plan.revenue, currency)}</p>
                      </div>
                      <div className="mt-2 h-2 overflow-hidden rounded-full bg-muted">
                        <div className="h-full rounded-full bg-primary" style={{ width: `${percentage}%` }} />
                      </div>
                    </div>
                  );
                })}
              </div>
            )}
          </CardContent>
        </Card>

        <Card className="overflow-hidden rounded-[2rem] border-0 shadow-card">
          <CardHeader className="px-5 pb-3 pt-5">
            <div className="flex items-center gap-3">
              <span className="flex h-10 w-10 items-center justify-center rounded-2xl bg-accent text-accent-foreground">
                <WalletCards className="h-4 w-4" />
              </span>
              <div>
                <CardTitle className="font-display text-lg font-extrabold">How members paid</CardTitle>
                <p className="mt-0.5 text-xs text-muted-foreground">Net cash by Payment method</p>
              </div>
            </div>
          </CardHeader>
          <CardContent className="px-5 pb-5">
            {data.paymentMethods.length === 0 ? (
              <div className="py-8 text-center text-sm text-muted-foreground">No payments in {year}</div>
            ) : (
              <>
                <div className="flex h-3 overflow-hidden rounded-full bg-muted">
                  {data.paymentMethods.map((method, index) => (
                    <div
                      key={method.method}
                      style={{
                        width: `${method.percentage}%`,
                        backgroundColor: METHOD_COLORS[index % METHOD_COLORS.length],
                      }}
                    />
                  ))}
                </div>
                <div className="mt-4 divide-y divide-border/60">
                  {data.paymentMethods.map((method, index) => (
                    <div key={method.method} className="flex items-center gap-3 py-3 first:pt-1 last:pb-0">
                      <span
                        className="h-2.5 w-2.5 shrink-0 rounded-full"
                        style={{ backgroundColor: METHOD_COLORS[index % METHOD_COLORS.length] }}
                      />
                      <div className="min-w-0 flex-1">
                        <p className="text-sm font-bold">{METHOD_LABELS[method.method] ?? method.method}</p>
                        <p className="text-[11px] text-muted-foreground">
                          {method.count} transaction{method.count !== 1 ? "s" : ""} · {method.percentage}%
                        </p>
                      </div>
                      <p className="max-w-[8rem] truncate text-sm font-extrabold">{formatCurrency(method.amount, currency)}</p>
                    </div>
                  ))}
                </div>
              </>
            )}
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
