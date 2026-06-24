"use client";

import { useState, useEffect } from "react";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
  DialogFooter,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Separator } from "@/components/ui/separator";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Badge } from "@/components/ui/badge";
import { DatePicker } from "@/components/ui/date-picker";
import { toast } from "sonner";
import { useCurrencySymbol, useGymSettings } from "@/lib/useGymSettings";
import { addDays, format } from "date-fns";
import { formatCurrency } from "@/lib/utils";

interface Plan { _id: string; name: string; durationDays: number; price: number; }

const DEFAULT_FORM = {
  name: "", phone: "", email: "", dateOfBirth: "",
  gender: "", address: "", emergencyContact: "",
  planId: "", membershipStart: "", notes: "",
  amountPaid: "", paymentMethod: "cash",
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

interface MemberFormDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  onSuccess?: () => void;
  /** When provided the dialog operates in edit mode — pre-fills fields and PUTs to /api/members/[id] */
  initialData?: MemberFormInitialData;
  /** Set to false to hide the Membership + Payment sections (edit mode) */
  showMembership?: boolean;
}

export function MemberFormDialog({
  open,
  onOpenChange,
  onSuccess,
  initialData,
  showMembership = true,
}: MemberFormDialogProps) {
  const currencySymbol = useCurrencySymbol();
  const { currency } = useGymSettings();
  const [plans, setPlans] = useState<Plan[]>([]);
  const [form, setForm] = useState({ ...DEFAULT_FORM, membershipStart: "" });
  const [saving, setSaving] = useState(false);

  const isEdit = !!initialData?._id;

  useEffect(() => {
    if (showMembership) {
      fetch("/api/plans").then(r => r.json()).then(d => setPlans(Array.isArray(d) ? d : d.plans || []));
    }
  }, [showMembership]);

  // Reset form whenever dialog opens
  useEffect(() => {
    if (!open) return;
    if (isEdit && initialData) {
      setForm({
        name: initialData.name ?? "",
        phone: initialData.phone ?? "",
        email: initialData.email ?? "",
        dateOfBirth: initialData.dateOfBirth
          ? format(new Date(initialData.dateOfBirth), "yyyy-MM-dd")
          : "",
        gender: initialData.gender ?? "",
        address: initialData.address ?? "",
        emergencyContact: initialData.emergencyContact ?? "",
        notes: initialData.notes ?? "",
        planId: "",
        membershipStart: format(new Date(), "yyyy-MM-dd"),
        amountPaid: "",
        paymentMethod: "cash",
      });
    } else {
      setForm({ ...DEFAULT_FORM, membershipStart: format(new Date(), "yyyy-MM-dd") });
    }
  }, [open]); // eslint-disable-line react-hooks/exhaustive-deps

  const selectedPlan = plans.find(p => p._id === form.planId);

  // When a plan is selected, default amountPaid to the plan's price
  useEffect(() => {
    if (selectedPlan) {
      setForm(f => ({ ...f, amountPaid: String(selectedPlan.price) }));
    } else {
      setForm(f => ({ ...f, amountPaid: "" }));
    }
  }, [selectedPlan?._id]); // eslint-disable-line react-hooks/exhaustive-deps

  const expiryDate =
    selectedPlan && form.membershipStart
      ? format(addDays(new Date(form.membershipStart), selectedPlan.durationDays), "yyyy-MM-dd")
      : "";

  const amountPaidNum = parseFloat(form.amountPaid) || 0;
  const dueAmount = selectedPlan ? Math.max(0, selectedPlan.price - amountPaidNum) : 0;

  function field(key: keyof typeof form) {
    return {
      value: form[key],
      onChange: (e: React.ChangeEvent<HTMLInputElement>) =>
        setForm(f => ({ ...f, [key]: e.target.value })),
    };
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!form.name.trim()) { toast.error("Name is required"); return; }
    if (!form.phone.trim()) { toast.error("Phone is required"); return; }

    setSaving(true);
    try {
      if (isEdit) {
        // ── Edit mode: PUT personal info only ──────────────────────────
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
        // ── Create mode: POST with optional membership ─────────────────
        const payload: Record<string, unknown> = {
          name: form.name,
          phone: form.phone,
          email: form.email || undefined,
          dateOfBirth: form.dateOfBirth || undefined,
          gender: form.gender || undefined,
          address: form.address || undefined,
          emergencyContact: form.emergencyContact || undefined,
          notes: form.notes || undefined,
          planId: form.planId || undefined,
          membershipStart: form.membershipStart || undefined,
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

      onOpenChange(false);
      onSuccess?.();
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "Something went wrong");
    } finally {
      setSaving(false);
    }
  }

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-lg max-h-[90vh] flex flex-col gap-0 p-0">
        <DialogHeader className="px-6 pt-6 pb-4 shrink-0">
          <DialogTitle>{isEdit ? "Edit Member" : "Add New Member"}</DialogTitle>
          <DialogDescription>
            {isEdit
              ? "Update personal details. To change membership, use Record Payment."
              : "Fill in the details to add a member to your gym."}
          </DialogDescription>
        </DialogHeader>

        <form id="member-form" onSubmit={handleSubmit} className="flex-1 flex flex-col min-h-0">
          <div className="flex-1 overflow-y-auto px-6 space-y-4 pb-2">

            {/* ── Personal Info ──────────────────────────────────────── */}
            <p className="text-xs font-semibold text-muted-foreground uppercase tracking-wider pt-1">
              Personal Info
            </p>
            <div className="grid grid-cols-2 gap-3">
              <div className="space-y-1.5 col-span-2">
                <Label htmlFor="mf-name">
                  Full Name <span className="text-destructive">*</span>
                </Label>
                <Input id="mf-name" placeholder="John Doe" {...field("name")} />
              </div>
              <div className="space-y-1.5">
                <Label htmlFor="mf-phone">
                  Phone <span className="text-destructive">*</span>
                </Label>
                <Input id="mf-phone" placeholder="+91 98765 43210" {...field("phone")} />
              </div>
              <div className="space-y-1.5">
                <Label htmlFor="mf-email">Email</Label>
                <Input id="mf-email" type="email" placeholder="john@example.com" {...field("email")} />
              </div>
              <div className="space-y-1.5">
                <Label>Date of Birth</Label>
                <DatePicker
                  value={form.dateOfBirth}
                  onChange={v => setForm(f => ({ ...f, dateOfBirth: v }))}
                  placeholder="Select date of birth"
                />
              </div>
              <div className="space-y-1.5">
                <Label>Gender</Label>
                <Select
                  value={form.gender}
                  onValueChange={v => setForm(f => ({ ...f, gender: v }))}
                >
                  <SelectTrigger><SelectValue placeholder="Select" /></SelectTrigger>
                  <SelectContent>
                    <SelectItem value="male">Male</SelectItem>
                    <SelectItem value="female">Female</SelectItem>
                    <SelectItem value="other">Other</SelectItem>
                  </SelectContent>
                </Select>
              </div>
              <div className="space-y-1.5 col-span-2">
                <Label htmlFor="mf-address">Address</Label>
                <Input id="mf-address" placeholder="123 Main St, City" {...field("address")} />
              </div>
              <div className="space-y-1.5">
                <Label htmlFor="mf-emergency">Emergency Contact</Label>
                <Input id="mf-emergency" placeholder="+91 98765 43210" {...field("emergencyContact")} />
              </div>
            </div>

            <Separator />

            <div className="space-y-1.5 pb-2">
              <Label htmlFor="mf-notes">Notes</Label>
              <Input id="mf-notes" placeholder="Allergies, goals, preferences…" {...field("notes")} />
            </div>

            {/* ── Membership + Payment (create only) ─────────────────── */}
            {showMembership && (
              <>
                <Separator />
                <p className="text-xs font-semibold text-muted-foreground uppercase tracking-wider">
                  Membership
                </p>
                <div className="grid grid-cols-2 gap-3">
                  <div className="space-y-1.5 col-span-2">
                    <Label>Plan</Label>
                    <Select
                      value={form.planId}
                      onValueChange={v => setForm(f => ({ ...f, planId: v }))}
                    >
                      <SelectTrigger><SelectValue placeholder="Select a plan (optional)" /></SelectTrigger>
                      <SelectContent>
                        {plans.map(p => (
                          <SelectItem key={p._id} value={p._id}>
                            {p.name} — {currencySymbol}{p.price} / {p.durationDays}d
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                  </div>

                  {selectedPlan && (
                    <>
                      <div className="space-y-1.5">
                        <Label>Start Date</Label>
                        <DatePicker
                          value={form.membershipStart}
                          onChange={v => setForm(f => ({ ...f, membershipStart: v }))}
                          placeholder="Select start date"
                        />
                      </div>
                      <div className="space-y-1.5">
                        <Label>Expiry Date</Label>
                        <DatePicker value={expiryDate} onChange={() => {}} disabled placeholder="Auto-calculated" />
                      </div>
                    </>
                  )}
                </div>

                {selectedPlan && (
                  <>
                    <Separator />
                    <p className="text-xs font-semibold text-muted-foreground uppercase tracking-wider">
                      Payment
                    </p>
                    <div className="grid grid-cols-2 gap-3">
                      <div className="space-y-1.5">
                        <Label htmlFor="mf-amount">Amount Paid ({currencySymbol})</Label>
                        <Input
                          id="mf-amount"
                          type="number"
                          min="0"
                          step="1"
                          placeholder={String(selectedPlan.price)}
                          {...field("amountPaid")}
                        />
                      </div>
                      <div className="space-y-1.5">
                        <Label>Payment Method</Label>
                        <Select
                          value={form.paymentMethod}
                          onValueChange={v => setForm(f => ({ ...f, paymentMethod: v }))}
                        >
                          <SelectTrigger><SelectValue /></SelectTrigger>
                          <SelectContent>
                            <SelectItem value="cash">Cash</SelectItem>
                            <SelectItem value="card">Card</SelectItem>
                            <SelectItem value="upi">UPI</SelectItem>
                            <SelectItem value="bank_transfer">Bank Transfer</SelectItem>
                            <SelectItem value="other">Other</SelectItem>
                          </SelectContent>
                        </Select>
                      </div>
                    </div>

                    <div className="rounded-lg bg-muted/50 border px-4 py-3 flex items-center justify-between text-sm">
                      <div className="space-y-0.5">
                        <p className="text-muted-foreground text-xs">Plan price</p>
                        <p className="font-medium">{formatCurrency(selectedPlan.price, currency)}</p>
                      </div>
                      <div className="space-y-0.5 text-right">
                        <p className="text-muted-foreground text-xs">Amount paid</p>
                        <p className="font-medium">{formatCurrency(amountPaidNum, currency)}</p>
                      </div>
                      <div className="space-y-0.5 text-right">
                        <p className="text-muted-foreground text-xs">Due after</p>
                        {dueAmount > 0 ? (
                          <Badge variant="warning" className="font-semibold">
                            {formatCurrency(dueAmount, currency)}
                          </Badge>
                        ) : (
                          <Badge variant="success" className="font-semibold">Paid in full</Badge>
                        )}
                      </div>
                    </div>
                  </>
                )}
              </>
            )}
          </div>
        </form>

        <DialogFooter className="px-6 py-4 border-t shrink-0">
          <Button variant="outline" onClick={() => onOpenChange(false)} disabled={saving}>
            Cancel
          </Button>
          <Button type="submit" form="member-form" disabled={saving}>
            {saving ? (isEdit ? "Saving…" : "Adding…") : (isEdit ? "Save Changes" : "Add Member")}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
