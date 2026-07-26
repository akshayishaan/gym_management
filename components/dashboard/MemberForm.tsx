"use client";

import { useRef, useState, useEffect } from "react";
import { useRouter } from "next/navigation";
import { toast } from "sonner";
import { format } from "date-fns";
import { StackHeader } from "@/components/layout/StackHeader";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { MobileDatePicker } from "@/components/ui/mobile-date-picker";
import { Label } from "@/components/ui/label";
import { Separator } from "@/components/ui/separator";
import { PaymentBreakdown } from "@/components/dashboard/PaymentBreakdown";
import { BottomSheetForm } from "@/components/dashboard/BottomSheetForm";
import {
  useCurrencySymbol,
  useGymScopedFormGuard,
  useGymSettings,
} from "@/lib/useGymSettings";
import { usePlans } from "@/lib/hooks/usePlans";
import {
  calculateMembershipExpiry,
  todayInTimeZone,
} from "@/lib/membershipCalendar";

const DEFAULT_FORM = {
  name: "",
  phone: "",
  email: "",
  dateOfBirth: "",
  gender: "",
  address: "",
  emergencyContact: "",
  planId: "",
  membershipStart: "",
  notes: "",
  amountPaid: "",
  paymentMethod: "cash",
};

export interface MemberFormInitialData {
  _id: string;
  name?: string;
  phone?: string;
  email?: string;
  dateOfBirth?: string;
  gender?: string;
  address?: string;
  emergencyContact?: string;
  notes?: string;
}

interface MemberFormProps {
  mode: "create" | "edit";
  /** "page" (default) renders a full-screen StackHeader page; "sheet" renders
   *  inside a BottomSheetForm — used for the Add Member flow, which is
   *  triggered from a list page rather than its own route. */
  variant?: "page" | "sheet";
  /** Required when variant="sheet". */
  open?: boolean;
  onOpenChange?: (open: boolean) => void;
  /** Required for edit mode — pre-fills personal info fields. */
  initialData?: MemberFormInitialData;
  onSuccess: () => void;
}

const selectClass =
  "flex h-12 w-full rounded-2xl border border-border/70 bg-card px-4 text-base shadow-[0_1px_0_hsl(var(--foreground)/0.03)] focus-visible:border-primary/40 focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-primary/10";

export function MemberForm({
  mode,
  variant = "page",
  open,
  onOpenChange,
  initialData,
  onSuccess,
}: MemberFormProps) {
  const router = useRouter();
  const currencySymbol = useCurrencySymbol();
  const { currency, timezone } = useGymSettings();
  const [saving, setSaving] = useState(false);
  const requestIdRef = useRef<string | null>(null);

  const isEdit = mode === "edit";
  const showMembership = !isEdit;

  const [form, setForm] = useState(() => ({
    ...DEFAULT_FORM,
    membershipStart: todayInTimeZone(timezone),
  }));
  const initialFormRef = useRef(form);
  const plansQuery = usePlans({ status: "active", includeStats: false, enabled: showMembership });
  const plans = plansQuery.data?.plans ?? [];

  useEffect(() => {
    if (variant !== "sheet" || !open || isEdit) return;
    requestIdRef.current = crypto.randomUUID();
    const nextForm = { ...DEFAULT_FORM, membershipStart: todayInTimeZone(timezone) };
    initialFormRef.current = nextForm;
    setForm(nextForm);
  }, [isEdit, open, timezone, variant]);

  // Pre-fill personal info in edit mode.
  useEffect(() => {
    if (!isEdit || !initialData) return;
    const nextForm = {
      ...initialFormRef.current,
      name: initialData.name ?? "",
      phone: initialData.phone ?? "",
      email: initialData.email ?? "",
      dateOfBirth: initialData.dateOfBirth ? format(new Date(initialData.dateOfBirth), "yyyy-MM-dd") : "",
      gender: initialData.gender ?? "",
      address: initialData.address ?? "",
      emergencyContact: initialData.emergencyContact ?? "",
      notes: initialData.notes ?? "",
    };
    initialFormRef.current = nextForm;
    setForm(nextForm);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [isEdit, initialData?._id]);

  const selectedPlan = plans.find((p) => p._id === form.planId);

  // When a plan is selected, default amountPaid to the plan's price.
  useEffect(() => {
    if (selectedPlan) {
      setForm((f) => ({ ...f, amountPaid: String(selectedPlan.price) }));
    } else {
      setForm((f) => ({ ...f, amountPaid: "" }));
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [selectedPlan?._id]);

  const expiryDate =
    selectedPlan && form.membershipStart
      ? calculateMembershipExpiry(form.membershipStart, selectedPlan.durationDays)
      : "";

  const amountPaidNum = parseFloat(form.amountPaid) || 0;
  const isDirty = JSON.stringify(form) !== JSON.stringify(initialFormRef.current);
  useGymScopedFormGuard({
    active: variant === "sheet" && !!open,
    dirty: isDirty,
    reset: () => onOpenChange?.(false),
  });

  function field(key: keyof typeof form) {
    return {
      value: form[key],
      onChange: (e: React.ChangeEvent<HTMLInputElement>) =>
        setForm((f) => ({ ...f, [key]: e.target.value })),
    };
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!form.name.trim()) {
      toast.error("Name is required");
      return;
    }
    if (!form.phone.trim()) {
      toast.error("Phone is required");
      return;
    }

    setSaving(true);
    try {
      if (isEdit) {
        const payload = {
          name: form.name,
          phone: form.phone,
          email: form.email || undefined,
          dateOfBirth: form.dateOfBirth || undefined,
          gender: form.gender || undefined,
          address: form.address || undefined,
          emergencyContact: form.emergencyContact || undefined,
          notes: form.notes || undefined,
        };
        const res = await fetch(`/api/members/${initialData!._id}`, {
          method: "PUT",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(payload),
        });
        if (!res.ok) throw new Error((await res.json()).error || "Failed to update member");
        toast.success("Member updated!");
      } else {
        const payload: Record<string, unknown> = {
          requestId: requestIdRef.current ??= crypto.randomUUID(),
          name: form.name,
          phone: form.phone,
          email: form.email || undefined,
          dateOfBirth: form.dateOfBirth || undefined,
          gender: form.gender || undefined,
          address: form.address || undefined,
          emergencyContact: form.emergencyContact || undefined,
          notes: form.notes || undefined,
          planId: form.planId || undefined,
          membershipStart: form.planId ? form.membershipStart || undefined : undefined,
        };
        if (form.planId && form.amountPaid !== "") {
          payload.amountPaid = amountPaidNum;
          payload.paymentMethod = form.paymentMethod;
        }
        const res = await fetch("/api/members", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(payload),
        });
        if (!res.ok) throw new Error((await res.json()).error || "Failed to add member");
        toast.success("Member added!");
      }
      onSuccess();
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "Something went wrong");
    } finally {
      setSaving(false);
    }
  }

  const formFields = (
    <>
      <p className="app-section-label pt-1">
        Personal Info
      </p>

      <div className="space-y-1.5">
        <Label htmlFor="mf-name">
          Full Name <span className="text-destructive">*</span>
        </Label>
        <Input id="mf-name" placeholder="John Doe" className="h-12" {...field("name")} />
      </div>

          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
            <div className="space-y-1.5">
              <Label htmlFor="mf-phone">
                Phone <span className="text-destructive">*</span>
              </Label>
              <Input id="mf-phone" placeholder="+91 98765 43210" className="h-12" {...field("phone")} />
            </div>
            <div className="space-y-1.5">
              <Label htmlFor="mf-email">Email</Label>
              <Input id="mf-email" type="email" placeholder="john@example.com" className="h-12" {...field("email")} />
            </div>
          </div>

          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
            <div className="space-y-1.5">
              <Label htmlFor="mf-dob">Date of Birth</Label>
              <MobileDatePicker
                id="mf-dob"
                title="Date of birth"
                placeholder="Select date of birth"
                value={form.dateOfBirth}
                onChange={(dateOfBirth) => setForm((f) => ({ ...f, dateOfBirth }))}
                variant="birth-date"
              />
            </div>
            <div className="space-y-1.5">
              <Label htmlFor="mf-gender">Gender</Label>
              <select
                id="mf-gender"
                className={selectClass}
                value={form.gender}
                onChange={(e) => setForm((f) => ({ ...f, gender: e.target.value }))}
              >
                <option value="">Select</option>
                <option value="male">Male</option>
                <option value="female">Female</option>
                <option value="other">Other</option>
              </select>
            </div>
          </div>

          <div className="space-y-1.5">
            <Label htmlFor="mf-address">Address</Label>
            <Input id="mf-address" placeholder="123 Main St, City" className="h-12" {...field("address")} />
          </div>

          <div className="space-y-1.5">
            <Label htmlFor="mf-emergency">Emergency Contact</Label>
            <Input id="mf-emergency" placeholder="+91 98765 43210" className="h-12" {...field("emergencyContact")} />
          </div>

          <Separator />

          <div className="space-y-1.5">
            <Label htmlFor="mf-notes">Notes</Label>
            <Input id="mf-notes" placeholder="Allergies, goals, preferences…" className="h-12" {...field("notes")} />
          </div>

          {showMembership && (
            <>
              <Separator />
              <p className="app-section-label">
                Membership
              </p>

              <div className="space-y-1.5">
                <Label htmlFor="mf-plan">Plan</Label>
                <select
                  id="mf-plan"
                  className={selectClass}
                  value={form.planId}
                  onChange={(e) => setForm((f) => ({ ...f, planId: e.target.value }))}
                >
                  <option value="">No plan (optional)</option>
                  {plans.map((p) => (
                    <option key={p._id} value={p._id}>
                      {p.name} — {currencySymbol}{p.price} / {p.durationDays}d
                    </option>
                  ))}
                </select>
              </div>

              {selectedPlan && (
                <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
                  <div className="space-y-1.5">
                    <Label htmlFor="mf-start">Start Date</Label>
                    <MobileDatePicker
                      id="mf-start"
                      title="Membership start"
                      value={form.membershipStart}
                      onChange={(membershipStart) => setForm((f) => ({ ...f, membershipStart }))}
                    />
                  </div>
                  <div className="space-y-1.5">
                    <Label htmlFor="mf-expiry">Expiry Date</Label>
                    <MobileDatePicker
                      id="mf-expiry"
                      title="Membership expiry"
                      value={expiryDate}
                      onChange={() => {}}
                      readOnly
                    />
                  </div>
                </div>
              )}

              {selectedPlan && (
                <>
                  <Separator />
                  <p className="app-section-label">
                    Payment
                  </p>
                  <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
                    <div className="space-y-1.5">
                      <Label htmlFor="mf-amount">Amount Paid ({currencySymbol})</Label>
                      <Input
                        id="mf-amount"
                        type="number"
                        min="0"
                        step="1"
                        className="h-12"
                        placeholder={String(selectedPlan.price)}
                        {...field("amountPaid")}
                      />
                    </div>
                    <div className="space-y-1.5">
                      <Label htmlFor="mf-method">Payment Method</Label>
                      <select
                        id="mf-method"
                        className={selectClass}
                        value={form.paymentMethod}
                        onChange={(e) => setForm((f) => ({ ...f, paymentMethod: e.target.value }))}
                      >
                        <option value="cash">Cash</option>
                        <option value="card">Card</option>
                        <option value="upi">UPI</option>
                        <option value="bank_transfer">Bank Transfer</option>
                        <option value="other">Other</option>
                      </select>
                    </div>
                  </div>

                  <PaymentBreakdown
                    items={[{ label: "Plan price", value: selectedPlan.price }]}
                    amountPaid={amountPaidNum}
                    currency={currency}
                  />
                </>
              )}
            </>
          )}
    </>
  );

  const submitLabel = saving
    ? isEdit
      ? "Saving…"
      : "Adding…"
    : isEdit
    ? "Save Changes"
    : "Add Member";

  if (variant === "sheet") {
    return (
      <BottomSheetForm
        open={open ?? false}
        onOpenChange={onOpenChange ?? (() => {})}
        title={isEdit ? "Edit Member" : "Add Member"}
        footer={
          <Button type="submit" form="member-form" className="h-12 w-full text-base font-semibold" disabled={saving}>
            {submitLabel}
          </Button>
        }
      >
        <form id="member-form" onSubmit={handleSubmit} className="space-y-5 pb-4">
          {formFields}
        </form>
      </BottomSheetForm>
    );
  }

  return (
    <div className="app-canvas flex min-h-svh flex-col">
      <StackHeader title={isEdit ? "Edit Member" : "Add Member"} onBack={() => router.back()} />
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
