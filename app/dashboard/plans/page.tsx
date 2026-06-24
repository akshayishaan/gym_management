"use client";

import { useEffect, useState } from "react";
import { useSession } from "next-auth/react";
import { toast } from "sonner";
import { motion } from "framer-motion";
import { Plus, Edit, Trash2, Dumbbell, Check, Clock, Zap } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Card, CardContent } from "@/components/ui/card";
import { Separator } from "@/components/ui/separator";
import {
  Dialog, DialogContent, DialogHeader, DialogTitle,
  DialogDescription, DialogFooter,
} from "@/components/ui/dialog";
import {
  AlertDialog, AlertDialogAction, AlertDialogCancel, AlertDialogContent,
  AlertDialogDescription, AlertDialogFooter, AlertDialogHeader,
  AlertDialogTitle, AlertDialogTrigger,
} from "@/components/ui/alert-dialog";
import { Badge } from "@/components/ui/badge";
import { PageHeader } from "@/components/layout/PageHeader";
import { useForm } from "react-hook-form";
import { formatCurrency } from "@/lib/utils";
import { useGymSettings, useCurrencySymbol } from "@/lib/useGymSettings";

interface Plan {
  _id: string;
  name: string;
  description?: string;
  durationDays: number;
  price: number;
  features?: string[];
  isActive: boolean;
}
type PlanForm = {
  name: string;
  description: string;
  durationDays: string;
  price: string;
  features: string;
  isActive: boolean;
};

export default function PlansPage() {
  const { data: session } = useSession();
  const role = (session?.user as { role?: string })?.role;
  const { currency } = useGymSettings();
  const currencySymbol = useCurrencySymbol();
  const [plans, setPlans] = useState<Plan[]>([]);
  const [open, setOpen] = useState(false);
  const [editPlan, setEditPlan] = useState<Plan | null>(null);
  const { register, handleSubmit, reset } = useForm<PlanForm>();

  const fetchPlans = () =>
    fetch("/api/plans")
      .then(r => r.json())
      .then(d => setPlans(Array.isArray(d) ? d : d.plans || []));

  useEffect(() => { fetchPlans(); }, []);

  function openEdit(p: Plan) {
    setEditPlan(p);
    reset({
      name: p.name,
      description: p.description || "",
      durationDays: String(p.durationDays),
      price: String(p.price),
      features: (p.features || []).join(", "),
      isActive: p.isActive,
    });
    setOpen(true);
  }

  function openNew() {
    setEditPlan(null);
    reset({ name: "", description: "", durationDays: "30", price: "", features: "", isActive: true });
    setOpen(true);
  }

  async function onSubmit(data: PlanForm) {
    const payload = {
      name: data.name,
      description: data.description,
      durationDays: Number(data.durationDays),
      price: Number(data.price),
      features: data.features
        ? data.features.split(",").map(f => f.trim()).filter(Boolean)
        : [],
      isActive: data.isActive,
    };
    const res = await fetch(
      editPlan ? `/api/plans/${editPlan._id}` : "/api/plans",
      { method: editPlan ? "PUT" : "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(payload) }
    );
    if (res.ok) {
      toast.success(editPlan ? "Plan updated!" : "Plan created!");
      setOpen(false);
      fetchPlans();
    } else {
      toast.error("Failed to save plan");
    }
  }

  async function deletePlan(id: string) {
    const res = await fetch(`/api/plans/${id}`, { method: "DELETE" });
    if (res.ok) { toast.success("Plan deleted"); fetchPlans(); }
    else toast.error("Failed to delete plan");
  }

  return (
    <div className="space-y-6">
      <PageHeader
        title="Membership Plans"
        description={`${plans.length} plan${plans.length !== 1 ? "s" : ""} configured`}
        actions={
          role === "admin" ? (
            <Button onClick={openNew} className="gap-2">
              <Plus className="h-4 w-4" /> New Plan
            </Button>
          ) : undefined
        }
      />

      {/* ── Empty state ────────────────────────────────────────────────── */}
      {plans.length === 0 ? (
        <Card className="border-0 shadow-card">
          <CardContent className="py-16 flex flex-col items-center text-center gap-3">
            <div className="w-14 h-14 rounded-2xl bg-primary/10 flex items-center justify-center">
              <Dumbbell className="h-7 w-7 text-primary" />
            </div>
            <div>
              <p className="font-medium">No plans yet</p>
              <p className="text-sm text-muted-foreground mt-1">
                Create your first membership plan to get started
              </p>
            </div>
            {role === "admin" && (
              <Button onClick={openNew} className="gap-2 mt-2">
                <Plus className="h-4 w-4" /> Create First Plan
              </Button>
            )}
          </CardContent>
        </Card>
      ) : (
        /* ── Plan cards ──────────────────────────────────────────────── */
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {plans.map((plan, i) => {
            const perDay = plan.durationDays > 0
              ? Math.round(plan.price / plan.durationDays)
              : null;

            return (
              <motion.div
                key={plan._id}
                initial={{ opacity: 0, y: 16 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: i * 0.06, type: "spring", stiffness: 300, damping: 24 }}
                className={plan.isActive ? "" : "opacity-60"}
              >
                <Card className="border-0 shadow-card hover:shadow-card-hover transition-all duration-300 overflow-hidden flex flex-col h-full relative">
                  {/* Decorative ambient glow */}
                  <div className="absolute top-0 right-0 w-40 h-40 bg-primary/5 rounded-full -translate-y-1/2 translate-x-1/2 blur-3xl pointer-events-none" />

                  {/* Coloured top accent */}
                  <div className="h-1 bg-gradient-to-r from-primary to-primary/60 shrink-0" />

                  <CardContent className="p-6 flex flex-col gap-5 flex-1">
                    {/* ── Header ──────────────────────────────── */}
                    <div className="flex items-start justify-between gap-3">
                      <div className="min-w-0">
                        <div className="flex items-center gap-2 flex-wrap">
                          <h3 className="font-bold text-lg leading-tight">{plan.name}</h3>
                          {!plan.isActive && (
                            <Badge variant="secondary" className="text-xs shrink-0">Inactive</Badge>
                          )}
                        </div>
                        {plan.description && (
                          <p className="text-sm text-muted-foreground mt-0.5 line-clamp-2">
                            {plan.description}
                          </p>
                        )}
                      </div>
                      <div className="p-2.5 rounded-xl bg-primary/10 shrink-0">
                        <Dumbbell className="h-4 w-4 text-primary" />
                      </div>
                    </div>

                    {/* ── Price ───────────────────────────────── */}
                    <div>
                      <p className="text-4xl font-bold tracking-tight">
                        {formatCurrency(plan.price, currency)}
                      </p>
                      <div className="flex items-center gap-2 mt-1.5 text-sm text-muted-foreground">
                        <Clock className="h-3.5 w-3.5 shrink-0" />
                        <span>{plan.durationDays} days</span>
                        {perDay !== null && (
                          <>
                            <span className="text-border">·</span>
                            <Zap className="h-3.5 w-3.5 shrink-0" />
                            <span>~{formatCurrency(perDay, currency)}/day</span>
                          </>
                        )}
                      </div>
                    </div>

                    {/* ── Features ────────────────────────────── */}
                    {plan.features && plan.features.length > 0 && (
                      <>
                        <Separator />
                        <ul className="space-y-2.5 flex-1">
                          {plan.features.map((f, j) => (
                            <li key={j} className="flex items-center gap-2.5 text-sm">
                              <span className="flex items-center justify-center w-4 h-4 rounded-full bg-success/10 shrink-0">
                                <Check className="h-2.5 w-2.5 text-success" />
                              </span>
                              <span className="text-muted-foreground">{f}</span>
                            </li>
                          ))}
                        </ul>
                      </>
                    )}

                    {/* ── Actions ─────────────────────────────── */}
                    {role === "admin" && (
                      <>
                        <Separator className="mt-auto" />
                        <div className="flex gap-2">
                          <Button
                            size="sm"
                            variant="outline"
                            className="flex-1 gap-1.5"
                            onClick={() => openEdit(plan)}
                          >
                            <Edit className="h-3.5 w-3.5" /> Edit
                          </Button>
                          <AlertDialog>
                            <AlertDialogTrigger asChild>
                              <Button
                                size="sm"
                                variant="outline"
                                className="flex-1 gap-1.5 text-destructive hover:bg-destructive/10 hover:text-destructive"
                              >
                                <Trash2 className="h-3.5 w-3.5" /> Delete
                              </Button>
                            </AlertDialogTrigger>
                            <AlertDialogContent>
                              <AlertDialogHeader>
                                <AlertDialogTitle>Delete "{plan.name}"?</AlertDialogTitle>
                                <AlertDialogDescription>
                                  This will permanently remove the plan. Members currently on this plan
                                  won't be affected but won't be able to renew with it.
                                </AlertDialogDescription>
                              </AlertDialogHeader>
                              <AlertDialogFooter>
                                <AlertDialogCancel>Cancel</AlertDialogCancel>
                                <AlertDialogAction
                                  className="bg-destructive hover:bg-destructive/90"
                                  onClick={() => deletePlan(plan._id)}
                                >
                                  Delete
                                </AlertDialogAction>
                              </AlertDialogFooter>
                            </AlertDialogContent>
                          </AlertDialog>
                        </div>
                      </>
                    )}
                  </CardContent>
                </Card>
              </motion.div>
            );
          })}
        </div>
      )}

      {/* ── Create / Edit Dialog ───────────────────────────────────────── */}
      <Dialog open={open} onOpenChange={setOpen}>
        <DialogContent className="sm:max-w-md max-h-[90vh] flex flex-col gap-0 p-0">
          <DialogHeader className="px-6 pt-6 pb-4 shrink-0">
            <DialogTitle>{editPlan ? "Edit Plan" : "New Membership Plan"}</DialogTitle>
            <DialogDescription>
              {editPlan
                ? "Update the plan details below."
                : "Create a new membership plan for your gym."}
            </DialogDescription>
          </DialogHeader>

          <form
            id="plan-form"
            onSubmit={handleSubmit(onSubmit)}
            className="flex-1 flex flex-col min-h-0"
          >
            <div className="flex-1 overflow-y-auto px-6 space-y-4 pb-2">
              <div className="space-y-1.5">
                <Label>Name <span className="text-destructive">*</span></Label>
                <Input {...register("name", { required: true })} placeholder="e.g. Monthly, Quarterly" />
              </div>

              <div className="space-y-1.5">
                <Label>Description</Label>
                <Input {...register("description")} placeholder="Brief description of the plan" />
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div className="space-y-1.5">
                  <Label>Duration (days) <span className="text-destructive">*</span></Label>
                  <Input type="number" min="1" {...register("durationDays", { required: true })} />
                </div>
                <div className="space-y-1.5">
                  <Label>Price ({currencySymbol}) <span className="text-destructive">*</span></Label>
                  <Input type="number" min="0" {...register("price", { required: true })} />
                </div>
              </div>

              <div className="space-y-1.5">
                <Label>Features</Label>
                <Input
                  {...register("features")}
                  placeholder="Locker room, General trainer, Pool access"
                />
                <p className="text-xs text-muted-foreground">Separate features with commas</p>
              </div>

              <div className="flex items-center gap-3 py-1">
                <input
                  id="plan-active"
                  type="checkbox"
                  {...register("isActive")}
                  className="h-4 w-4 rounded border-input accent-primary cursor-pointer"
                />
                <Label htmlFor="plan-active" className="cursor-pointer font-normal">
                  Plan is active and available to members
                </Label>
              </div>
            </div>

            <DialogFooter className="px-6 py-4 border-t shrink-0">
              <Button type="button" variant="outline" onClick={() => setOpen(false)}>
                Cancel
              </Button>
              <Button type="submit" form="plan-form">
                {editPlan ? "Save Changes" : "Create Plan"}
              </Button>
            </DialogFooter>
          </form>
        </DialogContent>
      </Dialog>
    </div>
  );
}
