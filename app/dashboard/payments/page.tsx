"use client";

import { useEffect, useRef, useState } from "react";
import { useSearchParams } from "next/navigation";
import { toast } from "sonner";
import { SlidersHorizontal, Wallet, X } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Fab } from "@/components/ui/fab";
import { BottomSheetForm } from "@/components/dashboard/BottomSheetForm";
import { PaymentCard } from "@/components/dashboard/PaymentCard";
import { PaymentFormDialog } from "@/components/dashboard/PaymentFormDialog";
import { formatCurrency } from "@/lib/utils";
import { useGymSettings } from "@/lib/useGymSettings";
import { cn } from "@/lib/utils";
import { usePayments } from "@/lib/hooks/usePayments";
import { useQueryClient } from "@tanstack/react-query";
import { todayInTimeZone } from "@/lib/membershipCalendar";
import { createRequestId } from "@/lib/clientRequestId";

const MONTHS = [
  "01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12",
];

const selectClass =
  "flex h-12 w-full rounded-2xl border border-border/70 bg-card px-4 text-base focus-visible:border-primary/40 focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-primary/10";

export default function PaymentsPage() {
  const { currency, timezone, selectedGymId } = useGymSettings();
  const queryClient = useQueryClient();
  const currentMonth = todayInTimeZone(timezone).slice(0, 7);
  const [month, setMonth] = useState(currentMonth);
  const [recordOpen, setRecordOpen] = useState(false);
  const [filterOpen, setFilterOpen] = useState(false);
  const actionRequestIds = useRef(new Map<string, string>());
  const searchParams = useSearchParams();
  const memberId = searchParams.get("memberId") || "";
  const paymentsQuery = usePayments({ memberId, month, limit: 50 });
  const payments = paymentsQuery.data?.payments ?? [];
  const total = paymentsQuery.data?.total ?? 0;
  const loading = paymentsQuery.isLoading;

  useEffect(() => {
    setMonth(currentMonth);
    setRecordOpen(false);
    setFilterOpen(false);
  }, [currentMonth, selectedGymId]);

  async function runLifecycleAction(endpoint: string, successMessage: string) {
    const requestId = actionRequestIds.current.get(endpoint) ?? createRequestId();
    actionRequestIds.current.set(endpoint, requestId);
    const response = await fetch(endpoint, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ requestId }),
    });
    const data = await response.json();
    if (!response.ok) {
      toast.error(data.error || "Could not update payment");
      return;
    }
    actionRequestIds.current.delete(endpoint);
    toast.success(successMessage);
    await queryClient.invalidateQueries({ queryKey: ["gym", selectedGymId] });
  }

  const totalAmount = paymentsQuery.data?.summary.netAmount ?? 0;
  const monthLabel = month
    ? new Date(2000, parseInt(month.split("-")[1], 10) - 1).toLocaleString("default", { month: "long" }) + ` ${month.split("-")[0]}`
    : "All months";

  return (
    <div className="space-y-5">
      <section className="relative overflow-hidden rounded-[2rem] bg-primary p-5 text-primary-foreground shadow-xl shadow-primary/20">
        <div className="absolute -right-10 -top-12 h-32 w-32 rounded-full border-[22px] border-primary-foreground/10" />
        <p className="text-[10px] font-bold uppercase tracking-[0.18em] text-primary-foreground/70">Collected</p>
        <p className="mt-1 font-display text-[2rem] font-extrabold tracking-[-0.05em]">
          {formatCurrency(totalAmount, currency)}
        </p>
        <p className="mt-1 text-xs font-semibold text-primary-foreground/70">
          {total} payment record{total !== 1 ? "s" : ""} · {monthLabel}
        </p>
      </section>

      <div className="flex items-center justify-between gap-2 px-1">
        <p className="app-section-label">Payment history</p>
        <Button
          aria-label="Filter payments"
          variant="outline"
          size="sm"
          className={cn("h-9 shrink-0 gap-1.5 rounded-xl bg-card text-xs", month && "border-primary/40 text-primary")}
          onClick={() => setFilterOpen(true)}
        >
          <SlidersHorizontal className="h-3.5 w-3.5" />
          Filter
        </Button>
      </div>

      {loading ? (
        <div className="space-y-2">
          {[...Array(6)].map((_, i) => (
            <div key={i} className="h-[94px] animate-pulse rounded-[1.5rem] bg-card" />
          ))}
        </div>
      ) : payments.length === 0 ? (
        <div className="app-surface flex flex-col items-center gap-4 rounded-[2rem] px-6 py-16 text-center">
          <div className="inline-flex h-16 w-16 items-center justify-center rounded-[1.4rem] bg-success/10 text-success">
            <Wallet className="h-7 w-7" />
          </div>
          <div>
            <p className="font-display text-lg font-bold">No payments found</p>
            <p className="mt-1 text-sm text-muted-foreground">
              {month ? "No payments in this month" : "Record a payment to get started"}
            </p>
          </div>
        </div>
      ) : (
        <div className="space-y-3">
          {payments.map((p) => (
            <PaymentCard
              key={p._id}
              payment={p}
              onVoid={(id) => void runLifecycleAction(`/api/payments/${id}/void`, "Payment voided")}
              onRefund={(id) => void runLifecycleAction(`/api/payments/${id}/refund`, "Refund recorded")}
              onReversePurchase={(membershipId) => void runLifecycleAction(
                `/api/memberships/${membershipId}/reverse`,
                "Plan purchase reversed"
              )}
            />
          ))}
        </div>
      )}

      <Fab onClick={() => setRecordOpen(true)} />

      <PaymentFormDialog
        open={recordOpen}
        onOpenChange={setRecordOpen}
        onSuccess={() => void queryClient.invalidateQueries({ queryKey: ["gym", selectedGymId] })}
      />

      <BottomSheetForm
        open={filterOpen}
        onOpenChange={setFilterOpen}
        title="Filter by Month"
        footer={
          <div className="flex gap-2">
            <Button
              variant="outline"
              className="flex-1"
              onClick={() => {
                setMonth("");
                setFilterOpen(false);
              }}
            >
              <X className="mr-1.5 h-4 w-4" /> Clear
            </Button>
            <Button className="flex-1" onClick={() => setFilterOpen(false)}>
              Apply
            </Button>
          </div>
        }
      >
        <div className="grid grid-cols-2 gap-3 py-2">
          <select
            className={selectClass}
            value={month ? month.split("-")[1] : ""}
            onChange={(e) => {
              const m = e.target.value;
              const y = month ? month.split("-")[0] : String(new Date().getFullYear());
              setMonth(m ? `${y}-${m}` : "");
            }}
          >
            <option value="">Month</option>
            {MONTHS.map((m, i) => (
              <option key={m} value={m}>
                {new Date(2000, i).toLocaleString("default", { month: "long" })}
              </option>
            ))}
          </select>

          <select
            className={selectClass}
            value={month ? month.split("-")[0] : ""}
            onChange={(e) => {
              const y = e.target.value;
              const m = month ? month.split("-")[1] : "";
              setMonth(y && m ? `${y}-${m}` : "");
            }}
          >
            <option value="">Year</option>
            {Array.from({ length: 5 }, (_, i) => String(new Date().getFullYear() - i)).map((y) => (
              <option key={y} value={y}>{y}</option>
            ))}
          </select>
        </div>
      </BottomSheetForm>
    </div>
  );
}
