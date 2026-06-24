"use client";

import { useState, useEffect, useCallback } from "react";
import {
  Dialog, DialogContent, DialogHeader, DialogTitle,
  DialogDescription, DialogFooter,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Separator } from "@/components/ui/separator";
import {
  Select, SelectContent, SelectItem, SelectTrigger, SelectValue,
} from "@/components/ui/select";
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import { toast } from "sonner";
import { useCurrencySymbol, useGymSettings } from "@/lib/useGymSettings";
import { formatCurrency } from "@/lib/utils";
import { format, addDays } from "date-fns";
import { Search } from "lucide-react";
import { DatePicker } from "@/components/ui/date-picker";

interface Member { _id: string; name: string; phone: string; planName?: string; }
interface Plan { _id: string; name: string; price: number; durationDays: number; }

const METHODS = [
  { value: "cash", label: "Cash" },
  { value: "card", label: "Card" },
  { value: "upi", label: "UPI" },
  { value: "bank_transfer", label: "Bank Transfer" },
  { value: "other", label: "Other" },
];

const DEFAULT_FORM = {
  memberId: "", memberName: "",
  planId: "", planName: "",
  amount: "", method: "cash",
  paidAt: "", notes: "",
};

function getInitials(name: string) {
  return name.split(" ").map(n => n[0]).join("").toUpperCase().slice(0, 2);
}

interface PaymentFormDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  /** Pre-fill from member detail — locks the member field */
  prefillMemberId?: string;
  prefillMemberName?: string;
  onSuccess?: () => void;
}

export function PaymentFormDialog({
  open, onOpenChange, prefillMemberId, prefillMemberName, onSuccess,
}: PaymentFormDialogProps) {
  const currencySymbol = useCurrencySymbol();
  const { currency } = useGymSettings();
  const [members, setMembers] = useState<Member[]>([]);
  const [memberSearch, setMemberSearch] = useState("");
  const [plans, setPlans] = useState<Plan[]>([]);
  const [form, setForm] = useState({ ...DEFAULT_FORM });
  const [saving, setSaving] = useState(false);

  const isMemberLocked = !!prefillMemberId;

  // Reset form on open
  useEffect(() => {
    if (!open) return;
    setForm({
      ...DEFAULT_FORM,
      memberId: prefillMemberId || "",
      memberName: prefillMemberName || "",
      paidAt: format(new Date(), "yyyy-MM-dd"),
    });
    setMemberSearch("");
  }, [open, prefillMemberId, prefillMemberName]);

  // Fetch plans once
  useEffect(() => {
    fetch("/api/plans").then(r => r.json()).then(d => setPlans(Array.isArray(d) ? d : d.plans || []));
  }, []);

  // Fetch members (debounced by search) — only when member is not pre-filled
  const fetchMembers = useCallback(() => {
    if (isMemberLocked) return;
    const params = new URLSearchParams({ limit: "50" });
    if (memberSearch) params.set("search", memberSearch);
    fetch(`/api/members?${params}`)
      .then(r => r.json())
      .then(d => setMembers(d.members || []));
  }, [memberSearch, isMemberLocked]);

  useEffect(() => {
    if (!open || isMemberLocked) return;
    const t = setTimeout(fetchMembers, 250);
    return () => clearTimeout(t);
  }, [open, fetchMembers, isMemberLocked]);

  // Auto-fill amount from selected plan
  useEffect(() => {
    const plan = plans.find(p => p._id === form.planId);
    if (plan) {
      setForm(f => ({ ...f, amount: String(plan.price), planName: plan.name }));
    }
  }, [form.planId, plans]);

  function setField(key: keyof typeof form) {
    return (e: React.ChangeEvent<HTMLInputElement>) =>
      setForm(f => ({ ...f, [key]: e.target.value }));
  }

  function selectMember(member: Member) {
    setForm(f => ({ ...f, memberId: member._id, memberName: member.name }));
    setMemberSearch("");
  }

  const selectedMember = isMemberLocked
    ? { _id: prefillMemberId!, name: prefillMemberName! }
    : members.find(m => m._id === form.memberId);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!form.memberId) { toast.error("Please select a member"); return; }
    if (!form.memberName) { toast.error("Member name is required"); return; }
    if (!form.amount || Number(form.amount) <= 0) { toast.error("Enter a valid amount"); return; }
    if (!form.method) { toast.error("Select a payment method"); return; }

    setSaving(true);
    try {
      const res = await fetch("/api/payments", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          memberId: form.memberId,
          memberName: form.memberName,
          planId: form.planId || undefined,
          planName: form.planName || undefined,
          amount: Number(form.amount),
          method: form.method,
          paidAt: form.paidAt || undefined,
          notes: form.notes || undefined,
        }),
      });
      if (!res.ok) {
        const data = await res.json();
        throw new Error(data.error || "Failed to record payment");
      }
      toast.success("Payment recorded!");
      onOpenChange(false);
      onSuccess?.();
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "Failed to record payment");
    } finally {
      setSaving(false);
    }
  }

  const selectedPlan = plans.find(p => p._id === form.planId);

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-md max-h-[90vh] flex flex-col gap-0 p-0">
        <DialogHeader className="px-6 pt-6 pb-4 shrink-0">
          <DialogTitle>Record Payment</DialogTitle>
          <DialogDescription>Add a new payment entry for a gym member.</DialogDescription>
        </DialogHeader>

        <form id="payment-form" onSubmit={handleSubmit} className="flex-1 flex flex-col min-h-0">
          <div className="flex-1 overflow-y-auto px-6 space-y-4 pb-2">

            {/* ── Member ─────────────────────────────────────────── */}
            <div className="space-y-1.5">
              <Label>Member <span className="text-destructive">*</span></Label>
              {isMemberLocked ? (
                /* Locked — came from member detail page */
                <div className="flex items-center gap-3 px-3 py-2 rounded-md border border-input bg-muted/50">
                  <Avatar className="h-7 w-7 shrink-0">
                    <AvatarFallback className="bg-primary/10 text-primary text-xs font-semibold">
                      {getInitials(prefillMemberName || "?")}
                    </AvatarFallback>
                  </Avatar>
                  <span className="text-sm font-medium">{prefillMemberName}</span>
                </div>
              ) : (
                /* Searchable member picker */
                <div className="space-y-2">
                  <div className="relative">
                    <Search className="absolute left-3 top-2.5 h-4 w-4 text-muted-foreground pointer-events-none" />
                    <Input
                      placeholder="Search members…"
                      className="pl-9"
                      value={memberSearch}
                      onChange={e => setMemberSearch(e.target.value)}
                    />
                  </div>

                  {/* Selected member chip */}
                  {selectedMember && !memberSearch && (
                    <div className="flex items-center gap-2.5 px-3 py-2 rounded-md border border-primary/40 bg-primary/5">
                      <Avatar className="h-6 w-6 shrink-0">
                        <AvatarFallback className="bg-primary/10 text-primary text-xs font-semibold">
                          {getInitials(selectedMember.name)}
                        </AvatarFallback>
                      </Avatar>
                      <span className="text-sm font-medium flex-1">{selectedMember.name}</span>
                      <button
                        type="button"
                        className="text-xs text-muted-foreground hover:text-foreground"
                        onClick={() => setForm(f => ({ ...f, memberId: "", memberName: "" }))}
                      >
                        Change
                      </button>
                    </div>
                  )}

                  {/* Members list */}
                  {(memberSearch || !form.memberId) && members.length > 0 && (
                    <div className="border rounded-md divide-y max-h-40 overflow-y-auto">
                      {members.map(m => (
                        <button
                          key={m._id}
                          type="button"
                          className="w-full flex items-center gap-2.5 px-3 py-2 hover:bg-muted/50 transition-colors text-left"
                          onClick={() => selectMember(m)}
                        >
                          <Avatar className="h-6 w-6 shrink-0">
                            <AvatarFallback className="bg-primary/10 text-primary text-xs font-semibold">
                              {getInitials(m.name)}
                            </AvatarFallback>
                          </Avatar>
                          <div className="min-w-0">
                            <p className="text-sm font-medium truncate">{m.name}</p>
                            {m.phone && <p className="text-xs text-muted-foreground">{m.phone}</p>}
                          </div>
                        </button>
                      ))}
                    </div>
                  )}
                  {!form.memberId && !memberSearch && members.length === 0 && (
                    <p className="text-xs text-muted-foreground text-center py-2">
                      Start typing to search members
                    </p>
                  )}
                </div>
              )}
            </div>

            <Separator />

            {/* ── Plan (optional) ────────────────────────────────── */}
            <div className="space-y-1.5">
              <Label>Membership Plan <span className="text-xs text-muted-foreground font-normal">(optional)</span></Label>
              <Select
                value={form.planId}
                onValueChange={v => setForm(f => ({ ...f, planId: v }))}
              >
                <SelectTrigger>
                  <SelectValue placeholder="Select plan — auto-fills amount" />
                </SelectTrigger>
                <SelectContent>
                  {plans.map(p => (
                    <SelectItem key={p._id} value={p._id}>
                      {p.name} — {formatCurrency(p.price, currency)}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
              {selectedPlan && (() => {
                const paymentDate = form.paidAt ? new Date(form.paidAt) : new Date();
                const renewedUntil = addDays(paymentDate, selectedPlan.durationDays);
                return (
                  <p className="text-xs text-success font-medium">
                    ✓ Membership will be renewed until {format(renewedUntil, "dd MMM yyyy")}
                  </p>
                );
              })()}
            </div>

            {/* ── Amount ─────────────────────────────────────────── */}
            <div className="space-y-1.5">
              <Label htmlFor="pf-amount">
                Amount ({currencySymbol}) <span className="text-destructive">*</span>
              </Label>
              <Input
                id="pf-amount"
                type="number"
                min="0"
                placeholder="0"
                value={form.amount}
                onChange={setField("amount")}
              />
            </div>

            {/* ── Method + Date ───────────────────────────────────── */}
            <div className="grid grid-cols-2 gap-3">
              <div className="space-y-1.5">
                <Label>Method <span className="text-destructive">*</span></Label>
                <Select
                  value={form.method}
                  onValueChange={v => setForm(f => ({ ...f, method: v }))}
                >
                  <SelectTrigger><SelectValue /></SelectTrigger>
                  <SelectContent>
                    {METHODS.map(m => (
                      <SelectItem key={m.value} value={m.value}>{m.label}</SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
              <div className="space-y-1.5">
                <Label>Date <span className="text-destructive">*</span></Label>
                <DatePicker
                  value={form.paidAt}
                  onChange={v => setForm(f => ({ ...f, paidAt: v }))}
                  placeholder="Select date"
                />
              </div>
            </div>

            {/* ── Notes ──────────────────────────────────────────── */}
            <div className="space-y-1.5 pb-2">
              <Label htmlFor="pf-notes">Notes</Label>
              <Input
                id="pf-notes"
                placeholder="Any additional notes…"
                value={form.notes}
                onChange={setField("notes")}
              />
            </div>
          </div>
        </form>

        <DialogFooter className="px-6 py-4 border-t shrink-0">
          <Button variant="outline" onClick={() => onOpenChange(false)} disabled={saving}>
            Cancel
          </Button>
          <Button type="submit" form="payment-form" disabled={saving}>
            {saving ? "Recording…" : "Record Payment"}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
