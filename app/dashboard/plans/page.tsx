"use client";

import { useEffect, useState } from "react";
import { useSession } from "next-auth/react";
import { toast } from "sonner";
import { motion } from "framer-motion";
import { Plus, Edit, Trash2, Dumbbell, Check, Users } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
} from "@/components/ui/dialog";
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
  AlertDialogTrigger,
} from "@/components/ui/alert-dialog";
import { Badge } from "@/components/ui/badge";
import { PageHeader } from "@/components/layout/PageHeader";
import { useForm } from "react-hook-form";
import { formatCurrency } from "@/lib/utils";

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
  const [plans, setPlans] = useState<Plan[]>([]);
  const [open, setOpen] = useState(false);
  const [editPlan, setEditPlan] = useState<Plan | null>(null);
  const { register, handleSubmit, reset, setValue } = useForm<PlanForm>();

  const fetchPlans = () =>
    fetch("/api/plans")
      .then((r) => r.json())
      .then((d) => setPlans(Array.isArray(d) ? d : d.plans || []));
  useEffect(() => {
    fetchPlans();
  }, []);

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
    reset({
      name: "",
      description: "",
      durationDays: "30",
      price: "",
      features: "",
      isActive: true,
    });
    setOpen(true);
  }

  async function onSubmit(data: PlanForm) {
    const payload = {
      name: data.name,
      description: data.description,
      durationDays: Number(data.durationDays),
      price: Number(data.price),
      features: data.features
        ? data.features.split(",").map((f) => f.trim()).filter(Boolean)
        : [],
      isActive: data.isActive,
    };
    const res = await fetch(
      editPlan ? `/api/plans/${editPlan._id}` : "/api/plans",
      {
        method: editPlan ? "PUT" : "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload),
      }
    );
    if (res.ok) {
      toast.success(editPlan ? "Plan updated!" : "Plan created!");
      setOpen(false);
      fetchPlans();
    } else toast.error("Failed to save plan");
  }

  async function deletePlan(id: string) {
    const res = await fetch(`/api/plans/${id}`, { method: "DELETE" });
    if (res.ok) {
      toast.success("Plan deleted");
      fetchPlans();
    } else toast.error("Failed to delete plan");
  }

  return (
    <div className="space-y-6">
      <PageHeader
        title="Membership Plans"
        description={`${plans.length} plans configured`}
        actions={
          role === "admin" ? (
            <Button onClick={openNew} className="gap-2">
              <Plus className="h-4 w-4" />
              New Plan
            </Button>
          ) : undefined
        }
      />

      {plans.length === 0 ? (
        <Card className="border-0 shadow-card">
          <CardContent className="py-12">
            <div className="flex flex-col items-center gap-3">
              <div className="inline-flex items-center justify-center w-12 h-12 rounded-full bg-muted text-muted-foreground">
                <Dumbbell className="h-6 w-6" />
              </div>
              <div className="text-center">
                <p className="text-sm font-medium text-muted-foreground">No plans yet</p>
                <p className="text-xs text-muted-foreground mt-1">
                  Create your first membership plan to get started
                </p>
              </div>
            </div>
          </CardContent>
        </Card>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {plans.map((plan, i) => (
            <motion.div
              key={plan._id}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: i * 0.05 }}
            >
              <Card
                className={`border-0 shadow-card hover:shadow-card-hover transition-all duration-300 ${
                  !plan.isActive ? "opacity-60" : ""
                }`}
              >
                <CardHeader className="pb-2">
                  <div className="flex items-start justify-between">
                    <div>
                      <div className="flex items-center gap-2 mb-1">
                        <CardTitle className="text-lg font-bold">
                          {plan.name}
                        </CardTitle>
                        {!plan.isActive && (
                          <Badge variant="secondary" className="text-xs">
                            Inactive
                          </Badge>
                        )}
                      </div>
                      {plan.description && (
                        <p className="text-sm text-muted-foreground">
                          {plan.description}
                        </p>
                      )}
                    </div>
                    <div className="p-2 rounded-xl bg-gradient-to-br from-orange-500 to-red-500 shadow-lg shadow-orange-500/20">
                      <Dumbbell className="h-4 w-4 text-white" />
                    </div>
                  </div>
                </CardHeader>
                <CardContent className="space-y-4">
                  <div>
                    <p className="text-3xl font-bold tracking-tight">
                      {formatCurrency(plan.price)}
                    </p>
                    <p className="text-sm text-muted-foreground">
                      {plan.durationDays} days
                    </p>
                  </div>
                  {plan.features && plan.features.length > 0 && (
                    <ul className="space-y-1.5">
                      {plan.features.map((f, j) => (
                        <li
                          key={j}
                          className="text-sm flex items-center gap-2 text-muted-foreground"
                        >
                          <span className="inline-flex items-center justify-center w-4 h-4 rounded-full bg-emerald-100 text-emerald-600">
                            <Check className="h-2.5 w-2.5" />
                          </span>
                          {f}
                        </li>
                      ))}
                    </ul>
                  )}
                  {role === "admin" && (
                    <div className="flex gap-2 pt-2 border-t">
                      <Button
                        size="sm"
                        variant="outline"
                        onClick={() => openEdit(plan)}
                        className="gap-1"
                      >
                        <Edit className="h-3.5 w-3.5" />
                        Edit
                      </Button>
                      <AlertDialog>
                        <AlertDialogTrigger asChild>
                          <Button
                            size="sm"
                            variant="outline"
                            className="text-destructive gap-1"
                          >
                            <Trash2 className="h-3.5 w-3.5" />
                            Delete
                          </Button>
                        </AlertDialogTrigger>
                        <AlertDialogContent>
                          <AlertDialogHeader>
                            <AlertDialogTitle>Delete Plan</AlertDialogTitle>
                            <AlertDialogDescription>
                              Delete "{plan.name}"? This cannot be undone.
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
                  )}
                </CardContent>
              </Card>
            </motion.div>
          ))}
        </div>
      )}

      <Dialog open={open} onOpenChange={setOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>
              {editPlan ? "Edit Plan" : "New Membership Plan"}
            </DialogTitle>
          </DialogHeader>
          <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
            <div className="space-y-2">
              <Label>Name *</Label>
              <Input {...register("name", { required: true })} placeholder="Monthly" />
            </div>
            <div className="space-y-2">
              <Label>Description</Label>
              <Input {...register("description")} placeholder="Brief description" />
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>Duration (days) *</Label>
                <Input
                  type="number"
                  {...register("durationDays", { required: true })}
                />
              </div>
              <div className="space-y-2">
                <Label>Price (₹) *</Label>
                <Input
                  type="number"
                  {...register("price", { required: true })}
                />
              </div>
            </div>
            <div className="space-y-2">
              <Label>Features (comma-separated)</Label>
              <Input
                {...register("features")}
                placeholder="Full gym access, Locker room"
              />
            </div>
            <DialogFooter>
              <Button type="button" variant="outline" onClick={() => setOpen(false)}>
                Cancel
              </Button>
              <Button type="submit">
                {editPlan ? "Update" : "Create"} Plan
              </Button>
            </DialogFooter>
          </form>
        </DialogContent>
      </Dialog>
    </div>
  );
}
