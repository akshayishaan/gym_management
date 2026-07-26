"use client";

import { useDeferredValue, useRef, useState, useEffect } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { MobileDatePicker } from "@/components/ui/mobile-date-picker";
import { Label } from "@/components/ui/label";
import { Separator } from "@/components/ui/separator";
import { Badge } from "@/components/ui/badge";
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import { BottomSheetForm } from "@/components/dashboard/BottomSheetForm";
import { PaymentBreakdown } from "@/components/dashboard/PaymentBreakdown";
import { toast } from "sonner";
import {
  useCurrencySymbol,
  useGymScopedFormGuard,
  useGymSettings,
} from "@/lib/useGymSettings";
import { formatCurrency, formatDate } from "@/lib/utils";
import { Search } from "lucide-react";
import { useMember, useMembers } from "@/lib/hooks/useMembers";
import { usePlans } from "@/lib/hooks/usePlans";
import {
  addCalendarDays,
  calculateMembershipExpiry,
  todayInTimeZone,
} from "@/lib/membershipCalendar";

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

const selectClass =
  "flex h-12 w-full rounded-2xl border border-border/70 bg-card px-4 text-base shadow-[0_1px_0_hsl(var(--foreground)/0.03)] focus-visible:border-primary/40 focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-primary/10";

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
  const { currency, timezone } = useGymSettings();
  const [memberSearch, setMemberSearch] = useState("");
  const deferredMemberSearch = useDeferredValue(memberSearch);
  const [form, setForm] = useState({ ...DEFAULT_FORM });
  const initialFormRef = useRef(form);
  const [saving, setSaving] = useState(false);
  const requestIdRef = useRef<string | null>(null);

  // Current member's ledger/membership context (drives all the conditional logic)
  const [selectedDue, setSelectedDue] = useState(0);
  const [selectedExpiry, setSelectedExpiry] = useState<string | null>(null);

  const isMemberLocked = !!prefillMemberId;
  const plansQuery = usePlans({ status: "active", includeStats: false, enabled: open });
  const membersQuery = useMembers({
    search: deferredMemberSearch,
    limit: 50,
    enabled: open && !isMemberLocked,
  });
  const lockedMemberQuery = useMember(prefillMemberId || "", open && isMemberLocked);
  const plans = (plansQuery.data?.plans ?? []) as Plan[];
  const members = (membersQuery.data?.members ?? []) as Member[];

  // Reset form on open
  useEffect(() => {
    if (!open) return;
    requestIdRef.current = crypto.randomUUID();
    const nextForm = {
      ...DEFAULT_FORM,
      memberId: prefillMemberId || "",
      memberName: prefillMemberName || "",
    };
    initialFormRef.current = nextForm;
    setForm(nextForm);
    setMemberSearch("");
    setSelectedDue(0);
    setSelectedExpiry(null);
  }, [open, prefillMemberId, prefillMemberName]);

  const selectedPlan = plans.find(p => p._id === form.planId);
  const isDirty = memberSearch !== ""
    || JSON.stringify(form) !== JSON.stringify(initialFormRef.current);
  useGymScopedFormGuard({
    active: open,
    dirty: isDirty,
    reset: () => onOpenChange(false),
  });

  // Smart default for membership start: stack from current expiry while active,
  // otherwise start today.
  const memberDue = isMemberLocked
    ? lockedMemberQuery.data?.dueAmount ?? 0
    : selectedDue;
  const memberExpiry = isMemberLocked
    ? lockedMemberQuery.data?.membershipExpiry ?? null
    : selectedExpiry;
  const today = todayInTimeZone(timezone);
  const isActive = !!memberExpiry && memberExpiry >= today;
  const defaultStart = isActive ? addCalendarDays(memberExpiry!, 1) : today;

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
  const totalOwed = selectedPlan ? planPrice : memberDue;
  const validUntil =
    selectedPlan && form.membershipStart
      ? calculateMembershipExpiry(form.membershipStart, selectedPlan.durationDays)
      : null;

  const hasMember = !!form.memberId;
  // No-plan + no-dues → nothing to record
  const blockedNoDues = hasMember && !selectedPlan && memberDue <= 0;

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!form.memberId) { toast.error("Please select a member"); return; }
    if (blockedNoDues) { toast.error("No outstanding dues. Select a plan to record a payment."); return; }
    if (form.amount === "" || (!selectedPlan && amountNum <= 0) || amountNum < 0) {
      toast.error("Enter a valid amount");
      return;
    }
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
          requestId: requestIdRef.current ??= crypto.randomUUID(),
          memberId: form.memberId,
          planId: form.planId || undefined,
          amount: amountNum,
          method: form.method,
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
    <BottomSheetForm
      open={open}
      onOpenChange={onOpenChange}
      title="Record Payment"
      description="Clear outstanding dues, or select a plan to start / renew a membership."
      footer={
        <div className="flex gap-2">
          <Button variant="outline" className="flex-1" onClick={() => onOpenChange(false)} disabled={saving}>
            Cancel
          </Button>
          <Button
            type="submit"
            form="payment-form"
            className="flex-1"
            disabled={saving || !hasMember || blockedNoDues}
          >
            {saving ? "Recording…" : "Record Payment"}
          </Button>
        </div>
      }
    >
      <form id="payment-form" onSubmit={handleSubmit} className="space-y-5 pb-4">
        {/* ── Member ─────────────────────────────────────────── */}
        <div className="space-y-1.5">
          <Label>Member <span className="text-destructive">*</span></Label>
          {isMemberLocked ? (
            <div className="flex items-center gap-3 rounded-2xl border border-border/70 bg-muted/50 px-4 py-3">
              <Avatar className="h-9 w-9 shrink-0">
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
                <div className="flex items-center gap-2.5 rounded-2xl border border-primary/30 bg-primary/5 px-4 py-3">
                  <Avatar className="h-9 w-9 shrink-0">
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
                    <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
                    <Input
                      placeholder="Search members…"
                      className="h-12 pl-10"
                      value={memberSearch}
                      onChange={e => setMemberSearch(e.target.value)}
                    />
                  </div>
                  {members.length > 0 ? (
                    <div className="max-h-48 divide-y divide-border/60 overflow-y-auto rounded-2xl border border-border/70 bg-card">
                      {members.map(m => (
                        <button
                          key={m._id}
                          type="button"
                          className="flex min-h-14 w-full items-center gap-2.5 px-3 py-2 text-left transition-colors active:bg-muted/50"
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
                <Label htmlFor="pf-plan">
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
              <select
                id="pf-plan"
                className={selectClass}
                value={form.planId}
                onChange={e => setForm(f => ({ ...f, planId: e.target.value }))}
              >
                <option value="">No plan — clear dues only</option>
                {plans.map(p => (
                  <option key={p._id} value={p._id}>
                    {p.name} — {formatCurrency(p.price, currency)}
                  </option>
                ))}
              </select>
            </div>

            {/* ── PLAN PATH ────────────────────────────────────── */}
            {selectedPlan ? (
              <>
                <div className="space-y-1.5">
                  <Label htmlFor="pf-start">Membership Start Date</Label>
                  <MobileDatePicker
                    id="pf-start"
                    title="Membership start"
                    value={form.membershipStart}
                    onChange={(membershipStart) => setForm(f => ({ ...f, membershipStart }))}
                  />
                  {validUntil && (
                    <p className="text-xs text-success font-medium">
                      Active from {form.membershipStart ? formatDate(form.membershipStart) : "—"} until {formatDate(validUntil)}
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
                    className="h-12"
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
                {memberDue > 0 && (
                  <p className="text-xs text-warning">
                    This member also has {formatCurrency(memberDue, currency)} in outstanding dues — record a separate payment (no plan) to clear them.
                  </p>
                )}
              </>
            ) : (
              /* ── NO-PLAN PATH (clear dues) ──────────────────── */
              <>
                {memberDue > 0 ? (
                  <>
                    <div className="space-y-1.5">
                      <Label htmlFor="pf-amount">
                        Amount ({currencySymbol}) <span className="text-destructive">*</span>
                      </Label>
                      <Input
                        id="pf-amount"
                        type="number"
                        min="0"
                        max={memberDue}
                        placeholder="0"
                        className="h-12"
                        value={form.amount}
                        onChange={setField("amount")}
                      />
                    </div>

                    <PaymentBreakdown
                      items={[{ label: "Outstanding dues", value: memberDue }]}
                      amountPaid={amountNum}
                      currency={currency}
                      balanceLabel="Remaining due"
                      settledLabel="Cleared"
                    />
                  </>
                ) : (
                  <div className="rounded-2xl border border-border/60 bg-muted/50 px-4 py-6 text-center text-sm">
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
                  <Label htmlFor="pf-method">Method <span className="text-destructive">*</span></Label>
                  <select
                    id="pf-method"
                    className={selectClass}
                    value={form.method}
                    onChange={e => setForm(f => ({ ...f, method: e.target.value }))}
                  >
                    {METHODS.map(m => (
                      <option key={m.value} value={m.value}>{m.label}</option>
                    ))}
                  </select>
                </div>

                <div className="space-y-1.5 pb-2">
                  <Label htmlFor="pf-notes">Notes</Label>
                  <Input
                    id="pf-notes"
                    placeholder="Any additional notes…"
                    className="h-12"
                    value={form.notes}
                    onChange={setField("notes")}
                  />
                </div>
              </>
            )}
          </>
        )}
      </form>
    </BottomSheetForm>
  );
}
