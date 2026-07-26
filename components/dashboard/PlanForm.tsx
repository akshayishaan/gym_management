"use client";

import { useState, useEffect, useRef } from "react";
import { useRouter } from "next/navigation";
import { toast } from "sonner";
import { StackHeader } from "@/components/layout/StackHeader";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { BottomSheetForm } from "@/components/dashboard/BottomSheetForm";
import { useCurrencySymbol, useGymScopedFormGuard } from "@/lib/useGymSettings";
import { Dumbbell, Plus, X } from "lucide-react";

export interface PlanFormInitialData {
  _id: string;
  name: string;
  description?: string;
  durationDays: number;
  price: number;
  features?: string[];
  isActive: boolean;
}

interface PlanFormState {
  name: string;
  description: string;
  durationDays: string;
  price: string;
  features: string[];
  isActive: boolean;
}

const DEFAULT_FORM: PlanFormState = {
  name: "",
  description: "",
  durationDays: "30",
  price: "",
  features: [],
  isActive: true,
};

const DURATION_PRESETS = [30, 90, 180, 365];

interface PlanFormProps {
  mode: "create" | "edit";
  /** "page" (default) renders a full-screen StackHeader page; "sheet" renders
   *  inside a BottomSheetForm — used when triggered from a list page rather
   *  than its own route. */
  variant?: "page" | "sheet";
  /** Required when variant="sheet". */
  open?: boolean;
  onOpenChange?: (open: boolean) => void;
  initialData?: PlanFormInitialData;
  title?: string;
  onSuccess: () => void;
}

export function PlanForm({ mode, variant = "page", open, onOpenChange, initialData, title, onSuccess }: PlanFormProps) {
  const router = useRouter();
  const currencySymbol = useCurrencySymbol();
  const isEdit = mode === "edit";
  const [saving, setSaving] = useState(false);
  const [featureInput, setFeatureInput] = useState("");
  const [form, setForm] = useState<PlanFormState>(() =>
    initialData
      ? {
          name: initialData.name,
          description: initialData.description ?? "",
          durationDays: String(initialData.durationDays),
          price: String(initialData.price),
          features: initialData.features ?? [],
          isActive: initialData.isActive,
        }
      : DEFAULT_FORM
  );
  const initialFormRef = useRef(form);

  // Re-sync when initialData changes — needed because in "sheet" variant a
  // single PlanForm instance is reused across different plans (each Edit tap
  // just changes the initialData prop rather than remounting the component).
  useEffect(() => {
    if (!initialData) return;
    const nextForm = {
      name: initialData.name,
      description: initialData.description ?? "",
      durationDays: String(initialData.durationDays),
      price: String(initialData.price),
      features: initialData.features ?? [],
      isActive: initialData.isActive,
    };
    initialFormRef.current = nextForm;
    setForm(nextForm);
    setFeatureInput("");
  }, [initialData]);

  useEffect(() => {
    if (variant !== "sheet" || !open || initialData) return;
    initialFormRef.current = DEFAULT_FORM;
    setForm(DEFAULT_FORM);
    setFeatureInput("");
  }, [initialData, open, variant]);

  const isDirty = featureInput !== ""
    || JSON.stringify(form) !== JSON.stringify(initialFormRef.current);
  useGymScopedFormGuard({
    active: variant === "sheet" && !!open,
    dirty: isDirty,
    reset: () => onOpenChange?.(false),
  });

  function addFeature() {
    const value = featureInput.trim();
    if (!value) return;
    if (form.features.some((feature) => feature.toLocaleLowerCase() === value.toLocaleLowerCase())) {
      toast.error("Feature already added");
      return;
    }
    if (form.features.length >= 20) {
      toast.error("A plan can have up to 20 features");
      return;
    }
    setForm((current) => ({ ...current, features: [...current.features, value] }));
    setFeatureInput("");
  }

  const numericPrice = Number(form.price);
  const previewPrice = form.price !== "" && Number.isFinite(numericPrice)
    ? `${currencySymbol}${numericPrice.toLocaleString()}`
    : `${currencySymbol}0`;
  const formTitle = title ?? (isEdit ? "Edit Plan" : "New Plan");

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!form.name.trim()) {
      toast.error("Name is required");
      return;
    }
    if (!form.durationDays || Number(form.durationDays) <= 0) {
      toast.error("Enter a valid duration");
      return;
    }
    if (form.price === "" || Number(form.price) < 0) {
      toast.error("Enter a valid price");
      return;
    }

    setSaving(true);
    try {
      const payload = {
        name: form.name,
        description: form.description,
        durationDays: Number(form.durationDays),
        price: Number(form.price),
        features: form.features,
        isActive: form.isActive,
      };
      const res = await fetch(
        isEdit ? `/api/plans/${initialData!._id}` : "/api/plans",
        {
          method: isEdit ? "PUT" : "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(payload),
        }
      );
      if (!res.ok) throw new Error((await res.json()).error || "Failed to save plan");
      toast.success(isEdit ? "Plan updated!" : "Plan created!");
      onSuccess();
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "Something went wrong");
    } finally {
      setSaving(false);
    }
  }

  const formFields = (
    <>
      <div className="relative overflow-hidden rounded-[1.75rem] bg-foreground p-4 text-background">
        <div className="absolute -right-8 -top-10 h-28 w-28 rounded-full bg-primary/45 blur-2xl" />
        <div className="relative flex items-start justify-between gap-3">
          <div className="min-w-0 flex-1">
            <p className="text-[10px] font-extrabold uppercase tracking-[0.16em] text-background/50">
              Live preview
            </p>
            <p className="mt-2 truncate font-display text-lg font-extrabold">
              {form.name.trim() || "Your plan name"}
            </p>
            <div className="mt-3 flex items-end gap-2">
              <p className="font-display text-3xl font-extrabold tracking-[-0.05em]">
                {previewPrice}
              </p>
              <p className="pb-1 text-xs font-semibold text-background/55">for {form.durationDays || 0} days</p>
            </div>
          </div>
          <span className="flex h-11 w-11 shrink-0 items-center justify-center rounded-2xl bg-background/10 text-primary">
            <Dumbbell className="h-5 w-5" />
          </span>
        </div>
      </div>

      <p className="app-section-label pt-1">Plan details</p>

      <div className="space-y-1.5">
            <Label htmlFor="pf-name">
              Name <span className="text-destructive">*</span>
            </Label>
            <Input
              id="pf-name"
              className="h-12"
              placeholder="e.g. Monthly, Quarterly"
              value={form.name}
              onChange={(e) => setForm((f) => ({ ...f, name: e.target.value }))}
            />
          </div>

          <div className="space-y-1.5">
            <Label htmlFor="pf-desc">Description</Label>
            <Input
              id="pf-desc"
              className="h-12"
              placeholder="Brief description of the plan"
              value={form.description}
              onChange={(e) => setForm((f) => ({ ...f, description: e.target.value }))}
            />
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-1.5">
              <Label htmlFor="pf-duration">
                Duration (days) <span className="text-destructive">*</span>
              </Label>
              <Input
                id="pf-duration"
                type="number"
                min="1"
                className="h-12"
                value={form.durationDays}
                onChange={(e) => setForm((f) => ({ ...f, durationDays: e.target.value }))}
              />
            </div>
            <div className="space-y-1.5">
              <Label htmlFor="pf-price">
                Price ({currencySymbol}) <span className="text-destructive">*</span>
              </Label>
              <Input
                id="pf-price"
                type="number"
                min="0"
                className="h-12"
                value={form.price}
                onChange={(e) => setForm((f) => ({ ...f, price: e.target.value }))}
              />
            </div>
            <div className="col-span-2 grid grid-cols-4 gap-2">
              {DURATION_PRESETS.map((days) => (
                <button
                  key={days}
                  type="button"
                  onClick={() => setForm((current) => ({ ...current, durationDays: String(days) }))}
                  className={`h-9 rounded-xl text-xs font-bold transition-all active:scale-95 ${
                    form.durationDays === String(days)
                      ? "bg-primary text-primary-foreground"
                      : "bg-muted text-muted-foreground"
                  }`}
                >
                  {days === 365 ? "1 yr" : `${days}d`}
                </button>
              ))}
            </div>
          </div>

          <div className="space-y-2">
            <Label htmlFor="pf-features">Features</Label>
            <div className="flex gap-2">
              <Input
                id="pf-features"
                className="h-12"
                placeholder="e.g. Personal trainer"
                value={featureInput}
                onChange={(e) => setFeatureInput(e.target.value)}
                onKeyDown={(event) => {
                  if (event.key === "Enter") {
                    event.preventDefault();
                    addFeature();
                  }
                }}
              />
              <Button
                type="button"
                variant="outline"
                size="icon"
                className="h-12 w-12 shrink-0"
                onClick={addFeature}
                disabled={!featureInput.trim()}
                aria-label="Add feature"
              >
                <Plus className="h-4 w-4" />
              </Button>
            </div>
            {form.features.length > 0 ? (
              <div className="flex flex-wrap gap-2 pt-1">
                {form.features.map((feature) => (
                  <span
                    key={feature}
                    className="inline-flex min-h-8 items-center gap-1.5 rounded-xl bg-secondary px-2.5 py-1 text-xs font-bold text-secondary-foreground"
                  >
                    {feature}
                    <button
                      type="button"
                      onClick={() => setForm((current) => ({
                        ...current,
                        features: current.features.filter((item) => item !== feature),
                      }))}
                      className="rounded-full p-0.5 active:bg-background/40"
                      aria-label={`Remove ${feature}`}
                    >
                      <X className="h-3 w-3" />
                    </button>
                  </span>
                ))}
              </div>
            ) : (
              <p className="text-xs text-muted-foreground">Add the benefits members receive with this plan.</p>
            )}
          </div>

          <label className="flex items-center gap-3 rounded-2xl border border-border/60 bg-muted/50 p-4">
            <input
              type="checkbox"
              checked={form.isActive}
              onChange={(e) => setForm((f) => ({ ...f, isActive: e.target.checked }))}
              className="h-5 w-5 rounded-md border-input accent-primary"
            />
            <span>
              <span className="block text-sm font-bold">Active plan</span>
              <span className="block text-xs text-muted-foreground">Available for new purchases and renewals</span>
            </span>
          </label>
    </>
  );

  const submitLabel = saving ? "Saving…" : isEdit ? "Save Changes" : "Create Plan";

  if (variant === "sheet") {
    return (
      <BottomSheetForm
        open={open ?? false}
        onOpenChange={onOpenChange ?? (() => {})}
        title={formTitle}
        footer={
          <Button type="submit" form="plan-form" className="h-12 w-full text-base font-semibold" disabled={saving}>
            {submitLabel}
          </Button>
        }
      >
        <form id="plan-form" onSubmit={handleSubmit} className="space-y-5 pb-4">
          {formFields}
        </form>
      </BottomSheetForm>
    );
  }

  return (
    <div className="app-canvas flex min-h-svh flex-col">
      <StackHeader title={formTitle} onBack={() => router.back()} />
      <form onSubmit={handleSubmit} className="flex flex-1 flex-col">
        <div className="flex-1 space-y-5 px-5 py-5">{formFields}</div>
        <div
          className="shrink-0 border-t px-4 py-3"
          style={{ paddingBottom: "calc(0.75rem + env(safe-area-inset-bottom))" }}
        >
          <Button type="submit" className="h-12 w-full text-base font-semibold" disabled={saving}>
            {submitLabel}
          </Button>
        </div>
      </form>
    </div>
  );
}
