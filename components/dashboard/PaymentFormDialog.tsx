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
import { Badge } from "@/components/ui/badge";
import {
  Select, SelectContent, SelectItem, SelectTrigger, SelectValue,
} from "@/components/ui/select";
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import { DatePicker } from "@/components/ui/date-picker";
import { PaymentBreakdown } from "@/components/dashboard/PaymentBreakdown";
import { toast } from "sonner";
import { useCurrencySymbol, useGymSettings } from "@/lib/useGymSettings";
import { formatCurrency } from "@/lib/utils";
import { format, addDays } from "date-fns";
import { Search } from "lucide-react";

interface Member {
  _id: string;
  name: string;
  phone?: string;
  planName?: string;
  dueAmount?: number;
  membershipExpiry?: string;
}
interface Plan { _id: string; name: string; price: number; durationDays: number; isActive?: boolean; }

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
  membershipStart: "", notes: "",
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

  // Current member's ledger/membership context (drives all the conditional logic)
  const [selectedDue, setSelectedDue] = useState(0);
  const [selectedExpiry, setSelectedExpiry] = useState<string | null>(null);

  const isMemberLocked = !!prefillMemberId;

  // Reset form on open
  useEffect(() => {
    if (!open) return;
    setForm({
      ...DEFAULT_FORM,
      memberId: prefillMemberId || "",
      memberName: prefillMemberName || "",
    });
    setMemberSearch("");
    setSelectedDue(0);
    setSelectedExpiry(null);
  }, [open, prefillMemberId, prefillMemberName]);

  // Fetch plans once — only active plans can be assigned/sold.
  useEffect(() => {
    fetch("/api/plans")
      .then(r => r.json())
      .then(d => {
        const all: Plan[] = Array.isArray(d) ? d : d.plans || [];
        setPlans(all.filter(p => p.isActive !== false));
      });
  }, []);

  // Fetch the full member record (due + expiry) once a member is chosen / locked
  const loadMemberContext = useCallback((id: string) => {
    fetch(`/api/members/${id}`)
      .then(r => r.json())
      .then((m) => {
        setSelectedDue(m?.dueAmount ?? 0);
        setSelectedExpiry(m?.membershipExpiry ?? null);
      })
      .catch(() => { setSelectedDue(0); setSelectedExpiry(null); });
  }, []);

  // Locked (prefill) member — load context on open
  useEffect(() => {
    if (open && isMemberLocked && prefillMemberId) loadMemberContext(prefillMemberId);
  }, [open, isMemberLocked, prefillMemberId, loadMemberContext]);

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

  const selectedPlan = plans.find(p => p._id === form.planId);

  // Smart default for membership start: stack from current expiry while active,
  // otherwise start today.
  const today = format(new Date(), "yyyy-MM-dd");
  const isActive = !!selectedExpiry && new Date(selectedExpiry) > new Date();
  const defaultStart = isActive ? format(new Date(selectedExpiry!), "yyyy-MM-dd") : today;

  // When a plan is (de)selected, seed the start date + amount.
  useEffect(() => {
    if (selectedPlan) {
      setForm(f => ({
        ...f,
        planName: selectedPlan.name,
        membershipStart: f.membershipStart || defaultStart,
        amount: String(selectedPlan.price),
      }));
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [selectedPlan?._id]);

  function setField(key: keyof typeof form) {
    return (e: React.ChangeEvent<HTMLInputElement>) =>
      setForm(f => ({ ...f, [key]: e.target.value }));
  }

  function selectMember(member: Member) {
    setForm(f => ({ ...f, memberId: member._id, memberName: member.name }));
    setMemberSearch("");
    setSelectedDue(member.dueAmount ?? 0);
    setSelectedExpiry(member.membershipExpiry ?? null);
  }

  function clearMember() {
    setForm(f => ({ ...DEFAULT_FORM, planId: "", planName: "" }));
    setSelectedDue(0);
    setSelectedExpiry(null);
  }

  function clearPlan() {
    setForm(f => ({ ...f, planId: "", planName: "", membershipStart: "", amount: "" }));
  }

  const selectedMember: Member | undefined = isMemberLocked
    ? { _id: prefillMemberId!, name: prefillMemberName! }
    : members.find(m => m._id === form.memberId);

  // ── Derived amounts ─────────────────────────────────────────────────────────
  const amountNum = parseFloat(form.amount) || 0;
  const planPrice = selectedPlan?.price ?? 0;
  // Single-purpose: a plan payment is capped at the plan price; a no-plan
  // payment is capped at the outstanding dues.
  const totalOwed = selectedPlan ? planPrice : selectedDue;
  const validUntil =
    selectedPlan && form.membershipStart
      ? addDays(new Date(form.membershipStart), selectedPlan.durationDays)
      : null;

  const hasMember = !!form.memberId;
  // No-plan + no-dues → nothing to record
  const blockedNoDues = hasMember && !selectedPlan && selectedDue <= 0;

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!form.memberId) { toast.error("Please select a member"); return; }
    if (blockedNoDues) { toast.error("No outstanding dues. Select a plan to record a payment."); return; }
    if (!form.amount || amountNum <= 0) { toast.error("Enter a valid amount"); return; }
    if (amountNum > totalOwed) {
      toast.error(selectedPlan ? "Amount exceeds total owed" : "Amount exceeds outstanding dues");
      return;
    }
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
          amount: amountNum,
          method: form.method,
          paidAt: new Date().toISOString(),
          membershipStart: selectedPlan ? form.membershipStart || undefined : undefined,
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

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-md max-h-[90vh] flex flex-col gap-0 p-0">
        <DialogHeader className="px-6 pt-6 pb-4 shrink-0">
          <DialogTitle>Record Payment</DialogTitle>
          <DialogDescription>
            Clear outstanding dues, or select a plan to start / renew a membership.
          </DialogDescription>
        </DialogHeader>

        <form id="payment-form" onSubmit={handleSubmit} className="flex-1 flex flex-col min-h-0">
          <div className="flex-1 overflow-y-auto px-6 space-y-4 pb-2">

            {/* ── Member ─────────────────────────────────────────── */}
            <div className="space-y-1.5">
              <Label>Member <span className="text-destructive">*</span></Label>
              {isMemberLocked ? (
                <div className="flex items-center gap-3 px-3 py-2 rounded-md border border-input bg-muted/50">
                  <Avatar className="h-7 w-7 shrink-0">
                    <AvatarFallback className="bg-primary/10 text-primary text-xs font-semibold">
                      {getInitials(prefillMemberName || "?")}
                    </AvatarFallback>
                  </Avatar>
                  <span className="text-sm font-medium">{prefillMemberName}</span>
                </div>
              ) : (
                <div className="space-y-2">
                  {/* Selected member chip */}
                  {selectedMember && form.memberId ? (
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
                        onClick={clearMember}
                      >
                        Change
                      </button>
                    </div>
                  ) : (
                    <>
                      <div className="relative">
                        <Search className="absolute left-3 top-2.5 h-4 w-4 text-muted-foreground pointer-events-none" />
                        <Input
                          placeholder="Search members…"
                          className="pl-9"
                          value={memberSearch}
                          onChange={e => setMemberSearch(e.target.value)}
                        />
                      </div>
                      {members.length > 0 ? (
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
                              <div className="min-w-0 flex-1">
                                <p className="text-sm font-medium truncate">{m.name}</p>
                                {m.phone && <p className="text-xs text-muted-foreground">{m.phone}</p>}
                              </div>
                              {(m.dueAmount ?? 0) > 0 && (
                                <Badge variant="warning" className="text-xs shrink-0">
                                  {formatCurrency(m.dueAmount!, currency)} due
                                </Badge>
                              )}
                            </button>
                          ))}
                        </div>
                      ) : (
                        <p className="text-xs text-muted-foreground text-center py-2">
                          Start typing to search members
                        </p>
                      )}
                    </>
                  )}
                </div>
              )}
            </div>

            {hasMember && (
              <>
                <Separator />

                {/* ── Plan (optional) ──────────────────────────────── */}
                <div className="space-y-1.5">
                  <div className="flex items-center justify-between">
                    <Label>
                      Membership Plan{" "}
                      <span className="text-xs text-muted-foreground font-normal">(optional)</span>
                    </Label>
                    {selectedPlan && (
                      <button
                        type="button"
                        className="text-xs text-muted-foreground hover:text-foreground"
                        onClick={clearPlan}
                      >
                        Clear
                      </button>
                    )}
                  </div>
                  <Select
                    value={form.planId}
                    onValueChange={v => setForm(f => ({ ...f, planId: v }))}
                  >
                    <SelectTrigger>
                      <SelectValue placeholder="No plan — clear dues only" />
                    </SelectTrigger>
                    <SelectContent>
                      {plans.map(p => (
                        <SelectItem key={p._id} value={p._id}>
                          {p.name} — {formatCurrency(p.price, currency)}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>

                {/* ── PLAN PATH ────────────────────────────────────── */}
                {selectedPlan ? (
                  <>
                    <div className="space-y-1.5">
                      <Label>Membership Start Date</Label>
                      <DatePicker
                        value={form.membershipStart}
                        onChange={v => setForm(f => ({ ...f, membershipStart: v }))}
                        placeholder="Select start date"
                      />
                      {validUntil && (
                        <p className="text-xs text-success font-medium">
                          ✓ Active from {form.membershipStart ? format(new Date(form.membershipStart), "dd MMM yyyy") : "—"} until {format(validUntil, "dd MMM yyyy")}
                          {isActive && " (stacks after current plan)"}
                        </p>
                      )}
                    </div>

                    <div className="space-y-1.5">
                      <Label htmlFor="pf-amount">
                        Amount ({currencySymbol}) <span className="text-destructive">*</span>
                      </Label>
                      <Input
                        id="pf-amount"
                        type="number"
                        min="0"
                        max={totalOwed}
                        placeholder="0"
                        value={form.amount}
                        onChange={setField("amount")}
                      />
                    </div>

                    {/* Due breakdown card */}
                    <PaymentBreakdown
                      items={[{ label: "Plan price", value: planPrice }]}
                      amountPaid={amountNum}
                      currency={currency}
                    />
                    {selectedDue > 0 && (
                      <p className="text-xs text-warning">
                        This member also has {formatCurrency(selectedDue, currency)} in outstanding dues — record a separate payment (no plan) to clear them.
                      </p>
                    )}
                  </>
                ) : (
                  /* ── NO-PLAN PATH (clear dues) ──────────────────── */
                  <>
                    {selectedDue > 0 ? (
                      <>
                        <div className="space-y-1.5">
                          <Label htmlFor="pf-amount">
                            Amount ({currencySymbol}) <span className="text-destructive">*</span>
                          </Label>
                          <Input
                            id="pf-amount"
                            type="number"
                            min="0"
                            max={selectedDue}
                            placeholder="0"
                            value={form.amount}
                            onChange={setField("amount")}
                          />
                        </div>

                        <PaymentBreakdown
                          items={[{ label: "Outstanding dues", value: selectedDue }]}
                          amountPaid={amountNum}
                          currency={currency}
                          balanceLabel="Remaining due"
                          settledLabel="Cleared"
                        />
                      </>
                    ) : (
                      <div className="rounded-lg bg-muted/50 border px-4 py-6 text-center text-sm">
                        <p className="font-medium">No outstanding dues</p>
                        <p className="text-xs text-muted-foreground mt-1">
                          Select a plan above to start or renew a membership.
                        </p>
                      </div>
                    )}
                  </>
                )}

                {/* ── Method + Notes (hidden when nothing to record) ── */}
                {!blockedNoDues && (
                  <>
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

                    <div className="space-y-1.5 pb-2">
                      <Label htmlFor="pf-notes">Notes</Label>
                      <Input
                        id="pf-notes"
                        placeholder="Any additional notes…"
                        value={form.notes}
                        onChange={setField("notes")}
                      />
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
          <Button type="submit" form="payment-form" disabled={saving || !hasMember || blockedNoDues}>
            {saving ? "Recording…" : "Record Payment"}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
