"use client";

import { useMemo, useState } from "react";
import { useSession } from "next-auth/react";
import {
  Activity,
  BadgeIndianRupee,
  BarChart3,
  Check,
  CirclePause,
  Copy,
  Dumbbell,
  Edit3,
  MoreHorizontal,
  Power,
  RefreshCw,
  Sparkles,
  UsersRound,
} from "lucide-react";
import { toast } from "sonner";
import { BottomSheetForm } from "@/components/dashboard/BottomSheetForm";
import { PlanForm, type PlanFormInitialData } from "@/components/dashboard/PlanForm";
import { StackHeader } from "@/components/layout/StackHeader";
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from "@/components/ui/alert-dialog";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Fab } from "@/components/ui/fab";
import type { PlanListItem } from "@/lib/planTypes";
import { useGymSettings } from "@/lib/useGymSettings";
import { cn, formatCurrency } from "@/lib/utils";
import { usePlans } from "@/lib/hooks/usePlans";
import { useInvalidateGymScope } from "@/lib/hooks/useGymScope";

type PlanFilter = "active" | "inactive";

const EMPTY_SUMMARY = {
  activePlans: 0,
  activeMembers: 0,
  salesYtd: 0,
  revenueAtSaleYtd: 0,
};

function toFormData(plan: PlanListItem): PlanFormInitialData {
  return {
    _id: plan._id,
    name: plan.name,
    description: plan.description,
    durationDays: plan.durationDays,
    price: plan.price,
    features: plan.features,
    isActive: plan.isActive,
  };
}

function Metric({
  icon: Icon,
  label,
  value,
}: {
  icon: typeof UsersRound;
  label: string;
  value: string | number;
}) {
  return (
    <div className="min-w-0 rounded-2xl bg-muted/55 p-3">
      <Icon className="mb-2 h-4 w-4 text-primary" />
      <p className="truncate font-display text-base font-extrabold tracking-tight">{value}</p>
      <p className="mt-0.5 truncate text-[10px] font-bold uppercase tracking-[0.08em] text-muted-foreground">
        {label}
      </p>
    </div>
  );
}

export default function PlansPage() {
  const { data: session } = useSession();
  const role = (session?.user as { role?: string })?.role;
  const { currency } = useGymSettings();
  const plansQuery = usePlans({ includeStats: true, limit: 100 });
  const invalidateGymScope = useInvalidateGymScope();
  const data = plansQuery.data ?? null;
  const loading = plansQuery.isLoading;
  const error = plansQuery.isError
    ? plansQuery.error instanceof Error ? plansQuery.error.message : "Could not load plans"
    : null;
  const [filter, setFilter] = useState<PlanFilter>("active");
  const [addOpen, setAddOpen] = useState(false);
  const [editPlan, setEditPlan] = useState<PlanFormInitialData | null>(null);
  const [duplicatePlan, setDuplicatePlan] = useState<PlanFormInitialData | null>(null);
  const [actionPlan, setActionPlan] = useState<PlanListItem | null>(null);
  const [deactivatePlan, setDeactivatePlan] = useState<PlanListItem | null>(null);
  const [updatingPlanId, setUpdatingPlanId] = useState<string | null>(null);

  const plans = data?.plans ?? [];
  const summary = data?.summary ?? EMPTY_SUMMARY;
  const activeCount = plans.filter((plan) => plan.isActive).length;
  const inactiveCount = plans.length - activeCount;
  const visiblePlans = plans.filter((plan) =>
    filter === "active" ? plan.isActive : !plan.isActive
  );

  const mostUsedPlanId = useMemo(() => {
    const activePlans = plans.filter((plan) => plan.isActive);
    const highest = Math.max(0, ...activePlans.map((plan) => plan.stats?.activeMembers ?? 0));
    if (highest === 0) return null;
    return activePlans.find((plan) => plan.stats?.activeMembers === highest)?._id ?? null;
  }, [plans]);

  async function togglePlanActive(plan: PlanListItem) {
    setUpdatingPlanId(plan._id);
    try {
      const response = await fetch(`/api/plans/${plan._id}`, {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ isActive: !plan.isActive }),
      });
      const payload = await response.json();
      if (!response.ok) throw new Error(payload.error || "Failed to update plan");
      toast.success(plan.isActive ? "Plan deactivated" : "Plan activated");
      await invalidateGymScope();
    } catch (updateError) {
      toast.error(updateError instanceof Error ? updateError.message : "Failed to update plan");
    } finally {
      setUpdatingPlanId(null);
    }
  }

  function startDuplicate(plan: PlanListItem) {
    const copy = {
      ...toFormData(plan),
      _id: "duplicate",
      name: `${plan.name} Copy`,
    };
    setActionPlan(null);
    window.setTimeout(() => setDuplicatePlan(copy), 220);
  }

  function requestStatusChange(plan: PlanListItem) {
    setActionPlan(null);
    if (plan.isActive) {
      window.setTimeout(() => setDeactivatePlan(plan), 220);
      return;
    }
    void togglePlanActive(plan);
  }

  return (
    <div className="app-canvas flex min-h-svh flex-col">
      <StackHeader title="Membership Plans" />
      <div
        className="app-screen flex-1 space-y-5 px-5 py-5"
        style={{ paddingBottom: "calc(6rem + env(safe-area-inset-bottom))" }}
      >
        <section className="relative overflow-hidden rounded-[1.9rem] bg-foreground p-5 text-background shadow-xl shadow-foreground/15">
          <div className="absolute -right-10 -top-12 h-36 w-36 rounded-full bg-primary/60 blur-2xl" />
          <div className="absolute -bottom-14 -left-8 h-28 w-28 rounded-full bg-success/30 blur-2xl" />
          <div className="relative">
            <div className="flex items-start justify-between gap-4">
              <div>
                <p className="text-[10px] font-extrabold uppercase tracking-[0.16em] text-background/50">
                  Plan revenue · YTD
                </p>
                <p className="mt-1 font-display text-3xl font-extrabold tracking-[-0.05em]">
                  {data ? formatCurrency(summary.revenueAtSaleYtd, currency) : "—"}
                </p>
                <p className="mt-1 text-xs font-semibold text-background/55">
                  {data
                    ? `From ${summary.salesYtd} plan sale${summary.salesYtd === 1 ? "" : "s"}`
                    : "Performance will appear here"}
                </p>
              </div>
              <span className="flex h-11 w-11 shrink-0 items-center justify-center rounded-2xl bg-background/10 text-primary">
                <BarChart3 className="h-5 w-5" />
              </span>
            </div>
            <div className="mt-5 grid grid-cols-2 divide-x divide-background/10 rounded-2xl bg-background/[0.07] py-3">
              <div className="px-3">
                <p className="font-display text-xl font-extrabold text-success">{data ? summary.activePlans : "—"}</p>
                <p className="text-[10px] font-bold uppercase tracking-[0.1em] text-background/45">Active plans</p>
              </div>
              <div className="px-4">
                <p className="font-display text-xl font-extrabold">{data ? summary.activeMembers : "—"}</p>
                <p className="text-[10px] font-bold uppercase tracking-[0.1em] text-background/45">Current members</p>
              </div>
            </div>
          </div>
        </section>

        <div className="app-surface grid grid-cols-2 rounded-[1.35rem] p-1.5" aria-label="Plan status filter">
          {(["active", "inactive"] as const).map((status) => {
            const selected = filter === status;
            const count = status === "active" ? activeCount : inactiveCount;
            return (
              <button
                key={status}
                type="button"
                aria-pressed={selected}
                onClick={() => setFilter(status)}
                className={cn(
                  "flex h-10 items-center justify-center gap-2 rounded-2xl text-sm font-bold capitalize transition-all active:scale-[0.98]",
                  selected ? "bg-foreground text-background shadow-sm" : "text-muted-foreground"
                )}
              >
                {status}
                <span className={cn(
                  "rounded-full px-2 py-0.5 text-[10px]",
                  selected ? "bg-background/10" : "bg-muted"
                )}>
                  {count}
                </span>
              </button>
            );
          })}
        </div>

        <div className="flex items-center justify-between px-1">
          <p className="app-section-label">{filter === "active" ? "Available now" : "Paused plans"}</p>
          {!loading && visiblePlans.length > 0 && (
            <p className="text-xs font-semibold text-muted-foreground">
              {visiblePlans.length} plan{visiblePlans.length === 1 ? "" : "s"}
            </p>
          )}
        </div>

        {loading ? (
          <div className="space-y-3" aria-label="Loading plans">
            {[0, 1, 2].map((item) => (
              <div key={item} className="h-56 animate-pulse rounded-[1.75rem] bg-card" />
            ))}
          </div>
        ) : error ? (
          <div className="app-surface flex flex-col items-center rounded-[1.75rem] px-6 py-12 text-center">
            <span className="flex h-14 w-14 items-center justify-center rounded-2xl bg-destructive/10 text-destructive">
              <RefreshCw className="h-6 w-6" />
            </span>
            <p className="mt-4 font-display text-lg font-extrabold">Plans could not load</p>
            <p className="mt-1 text-sm text-muted-foreground">{error}</p>
            <Button className="mt-5" variant="outline" onClick={() => {
              void plansQuery.refetch();
            }}>
              Try again
            </Button>
          </div>
        ) : plans.length === 0 ? (
          <div className="app-surface flex flex-col items-center rounded-[1.75rem] px-6 py-14 text-center">
            <span className="flex h-16 w-16 items-center justify-center rounded-[1.4rem] bg-primary/10 text-primary">
              <Dumbbell className="h-7 w-7" />
            </span>
            <p className="mt-4 font-display text-lg font-extrabold">Build your first plan</p>
            <p className="mt-1 max-w-[16rem] text-sm text-muted-foreground">
              Package your membership into a clear offer your team can sell.
            </p>
            {role === "admin" && (
              <Button className="mt-5" onClick={() => setAddOpen(true)}>Create plan</Button>
            )}
          </div>
        ) : visiblePlans.length === 0 ? (
          <div className="app-surface flex flex-col items-center rounded-[1.75rem] px-6 py-12 text-center">
            <span className="flex h-14 w-14 items-center justify-center rounded-2xl bg-muted text-muted-foreground">
              {filter === "active" ? <Activity className="h-6 w-6" /> : <CirclePause className="h-6 w-6" />}
            </span>
            <p className="mt-4 font-display text-lg font-extrabold">
              {filter === "active" ? "No active plans" : "Nothing is paused"}
            </p>
            <p className="mt-1 text-sm text-muted-foreground">
              {filter === "active"
                ? "Activate a plan or create a new offer."
                : "Inactive plans will appear here."}
            </p>
          </div>
        ) : (
          <div className="space-y-3">
            {visiblePlans.map((plan) => {
              const stats = plan.stats ?? {
                activeMembers: 0,
                salesYtd: 0,
                revenueAtSaleYtd: 0,
                totalMemberships: 0,
              };
              const features = plan.features ?? [];
              const isMostUsed = plan._id === mostUsedPlanId;

              return (
                <article
                  key={plan._id}
                  className={cn(
                    "app-surface relative overflow-hidden rounded-[1.75rem] p-4",
                    !plan.isActive && "border-dashed bg-muted/35"
                  )}
                >
                  {!plan.isActive && <div className="absolute inset-y-0 left-0 w-1 bg-warning" />}
                  <div className="flex items-start gap-3">
                    <span className={cn(
                      "flex h-11 w-11 shrink-0 items-center justify-center rounded-2xl",
                      plan.isActive ? "bg-primary/10 text-primary" : "bg-warning/15 text-warning"
                    )}>
                      {plan.isActive ? <Dumbbell className="h-5 w-5" /> : <CirclePause className="h-5 w-5" />}
                    </span>
                    <div className="min-w-0 flex-1">
                      <div className="flex flex-wrap items-center gap-1.5">
                        <h2 className="truncate font-display text-lg font-extrabold tracking-tight">{plan.name}</h2>
                        {isMostUsed && (
                          <Badge variant="success" className="gap-1">
                            <Sparkles className="h-3 w-3" /> Most used
                          </Badge>
                        )}
                        {!plan.isActive && <Badge variant="warning">Paused</Badge>}
                      </div>
                      <p className="mt-0.5 text-sm font-semibold text-muted-foreground">
                        {formatCurrency(plan.price, currency)} · {plan.durationDays} days
                      </p>
                    </div>
                    {role === "admin" && (
                      <Button
                        size="icon"
                        variant="ghost"
                        className="-mr-1 -mt-1 h-10 w-10 shrink-0"
                        onClick={() => setActionPlan(plan)}
                        aria-label={`Manage ${plan.name}`}
                      >
                        <MoreHorizontal className="h-5 w-5" />
                      </Button>
                    )}
                  </div>

                  {plan.description && (
                    <p className="mt-3 line-clamp-2 text-sm leading-relaxed text-muted-foreground">
                      {plan.description}
                    </p>
                  )}

                  <div className="mt-4 grid grid-cols-3 gap-2">
                    <Metric icon={UsersRound} label="Members" value={stats.activeMembers} />
                    <Metric icon={Activity} label="YTD sales" value={stats.salesYtd} />
                    <Metric
                      icon={BadgeIndianRupee}
                      label="YTD revenue"
                      value={formatCurrency(stats.revenueAtSaleYtd, currency)}
                    />
                  </div>

                  {features.length > 0 && (
                    <div className="mt-4 flex flex-wrap gap-1.5 border-t border-border/60 pt-3">
                      {features.slice(0, 3).map((feature) => (
                        <span
                          key={feature}
                          className="inline-flex max-w-full items-center gap-1.5 rounded-xl bg-secondary px-2.5 py-1.5 text-[11px] font-bold text-secondary-foreground"
                        >
                          <Check className="h-3 w-3 shrink-0 text-success" />
                          <span className="truncate">{feature}</span>
                        </span>
                      ))}
                      {features.length > 3 && (
                        <span className="rounded-xl bg-muted px-2.5 py-1.5 text-[11px] font-bold text-muted-foreground">
                          +{features.length - 3}
                        </span>
                      )}
                    </div>
                  )}

                  {!plan.isActive && (
                    <p className="mt-4 rounded-xl bg-warning/10 px-3 py-2 text-xs font-semibold text-warning-foreground dark:text-warning">
                      Hidden from new purchases. Existing memberships remain valid.
                    </p>
                  )}
                </article>
              );
            })}
          </div>
        )}
      </div>

      {role === "admin" && (
        <Fab
          onClick={() => setAddOpen(true)}
          aria-label="Create membership plan"
          style={{ bottom: "calc(1.25rem + env(safe-area-inset-bottom))" }}
        />
      )}

      <BottomSheetForm
        open={!!actionPlan}
        onOpenChange={(open) => { if (!open) setActionPlan(null); }}
        title={actionPlan?.name ?? "Plan actions"}
        description={actionPlan
          ? `${formatCurrency(actionPlan.price, currency)} for ${actionPlan.durationDays} days`
          : undefined}
        footer={
          <Button variant="outline" className="h-12 w-full" onClick={() => setActionPlan(null)}>
            Close
          </Button>
        }
        className="max-h-[80svh]"
      >
        {actionPlan && (
          <div className="space-y-2 pb-4">
            <button
              type="button"
              className="flex w-full items-center gap-3 rounded-2xl bg-muted/55 p-4 text-left transition-all active:scale-[0.98]"
              onClick={() => {
                const plan = toFormData(actionPlan);
                setActionPlan(null);
                window.setTimeout(() => setEditPlan(plan), 220);
              }}
            >
              <span className="flex h-11 w-11 items-center justify-center rounded-2xl bg-primary/10 text-primary">
                <Edit3 className="h-5 w-5" />
              </span>
              <span>
                <span className="block text-sm font-extrabold">Edit plan</span>
                <span className="block text-xs text-muted-foreground">Change pricing, duration, or benefits</span>
              </span>
            </button>
            <button
              type="button"
              className="flex w-full items-center gap-3 rounded-2xl bg-muted/55 p-4 text-left transition-all active:scale-[0.98]"
              onClick={() => startDuplicate(actionPlan)}
            >
              <span className="flex h-11 w-11 items-center justify-center rounded-2xl bg-secondary text-secondary-foreground">
                <Copy className="h-5 w-5" />
              </span>
              <span>
                <span className="block text-sm font-extrabold">Duplicate plan</span>
                <span className="block text-xs text-muted-foreground">Use this offer as a starting point</span>
              </span>
            </button>
            <button
              type="button"
              disabled={updatingPlanId === actionPlan._id}
              className={cn(
                "flex w-full items-center gap-3 rounded-2xl p-4 text-left transition-all active:scale-[0.98] disabled:opacity-50",
                actionPlan.isActive ? "bg-destructive/10" : "bg-success/10"
              )}
              onClick={() => requestStatusChange(actionPlan)}
            >
              <span className={cn(
                "flex h-11 w-11 items-center justify-center rounded-2xl",
                actionPlan.isActive ? "bg-destructive/10 text-destructive" : "bg-success/10 text-success"
              )}>
                {actionPlan.isActive ? <CirclePause className="h-5 w-5" /> : <Power className="h-5 w-5" />}
              </span>
              <span>
                <span className={cn(
                  "block text-sm font-extrabold",
                  actionPlan.isActive ? "text-destructive" : "text-success"
                )}>
                  {actionPlan.isActive ? "Deactivate plan" : "Activate plan"}
                </span>
                <span className="block text-xs text-muted-foreground">
                  {actionPlan.isActive ? "Stop offering it to new members" : "Offer it to members again"}
                </span>
              </span>
            </button>
          </div>
        )}
      </BottomSheetForm>

      <AlertDialog open={!!deactivatePlan} onOpenChange={(open) => { if (!open) setDeactivatePlan(null); }}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Pause {deactivatePlan?.name}?</AlertDialogTitle>
            <AlertDialogDescription>
              It will disappear from new purchases and renewals. The {deactivatePlan?.stats?.activeMembers ?? 0} active member{(deactivatePlan?.stats?.activeMembers ?? 0) === 1 ? "" : "s"} currently on this plan will keep their membership.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Keep active</AlertDialogCancel>
            <AlertDialogAction
              className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
              disabled={!!deactivatePlan && updatingPlanId === deactivatePlan._id}
              onClick={() => {
                if (deactivatePlan) void togglePlanActive(deactivatePlan);
                setDeactivatePlan(null);
              }}
            >
              Deactivate
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>

      <PlanForm
        mode="create"
        variant="sheet"
        open={addOpen}
        onOpenChange={setAddOpen}
        onSuccess={() => {
          setAddOpen(false);
          void invalidateGymScope();
        }}
      />

      <PlanForm
        mode="create"
        variant="sheet"
        title="Duplicate Plan"
        initialData={duplicatePlan ?? undefined}
        open={!!duplicatePlan}
        onOpenChange={(open) => { if (!open) setDuplicatePlan(null); }}
        onSuccess={() => {
          setDuplicatePlan(null);
          void invalidateGymScope();
        }}
      />

      <PlanForm
        mode="edit"
        variant="sheet"
        initialData={editPlan ?? undefined}
        open={!!editPlan}
        onOpenChange={(open) => { if (!open) setEditPlan(null); }}
        onSuccess={() => {
          setEditPlan(null);
          void invalidateGymScope();
        }}
      />
    </div>
  );
}
