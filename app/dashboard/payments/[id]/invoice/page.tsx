"use client";

import { useEffect, useState, use } from "react";
import { Button } from "@/components/ui/button";
import { Printer } from "lucide-react";
import { StackHeader } from "@/components/layout/StackHeader";
import { formatDate, formatCurrency } from "@/lib/utils";
import { useGymSettings } from "@/lib/useGymSettings";

interface Payment {
  _id: string; memberName: string; amount: number; method: string;
  invoiceNumber: string; paidAt: string; planName?: string; notes?: string;
  status: "paid" | "voided" | "refunded";
}
export default function InvoicePage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params);
  const [payment, setPayment] = useState<Payment | null>(null);
  const settings = useGymSettings();

  useEffect(() => {
    fetch(`/api/payments/${id}`).then((response) => response.json()).then(setPayment);
  }, [id]);

  if (!payment) {
    return (
      <div className="flex min-h-svh flex-col bg-background">
        <StackHeader title="Invoice" className="print:hidden" />
        <div className="px-4 py-4">
          <div className="h-64 animate-pulse rounded-lg bg-muted" />
        </div>
      </div>
    );
  }

  return (
    <div className="app-canvas flex min-h-svh flex-col bg-background">
      <StackHeader
        title="Invoice"
        className="print:hidden"
        actions={
          <Button size="sm" className="gap-1.5" onClick={() => window.print()}>
            <Printer className="h-3.5 w-3.5" /> Print
          </Button>
        }
      />

      <div
        className="flex-1 px-4 py-4"
        style={{ paddingBottom: "calc(1rem + env(safe-area-inset-bottom))" }}
      >
        <div className="app-surface space-y-6 rounded-[2rem] bg-card p-5 print:rounded-none print:border-0 print:bg-white print:p-0 print:shadow-none" id="invoice">
          <div className="flex items-start justify-between gap-4">
            <div className="min-w-0">
              <div className="mb-3 flex h-11 w-11 items-center justify-center rounded-2xl bg-primary font-display text-lg font-extrabold text-primary-foreground print:border print:border-black print:bg-white print:text-black">
                {settings.gymName.slice(0, 1).toUpperCase()}
              </div>
              <h1 className="truncate font-display text-xl font-extrabold text-foreground print:text-black">{settings.gymName}</h1>
              {settings.address && <p className="mt-1 text-xs leading-5 text-muted-foreground print:text-black">{settings.address}</p>}
              {settings.phone && <p className="text-xs text-muted-foreground print:text-black">{settings.phone}</p>}
              {settings.email && <p className="text-xs text-muted-foreground print:text-black">{settings.email}</p>}
            </div>
            <div className="shrink-0 text-right">
              <span className={`rounded-full px-3 py-1 text-[10px] font-extrabold tracking-wider print:border print:border-black print:bg-white print:text-black ${
                payment.status === "paid"
                  ? "bg-success/10 text-success"
                  : payment.status === "refunded"
                    ? "bg-warning/15 text-warning"
                    : "bg-muted text-muted-foreground"
              }`}>
                {payment.status.toUpperCase()}
              </span>
              <h2 className="mt-4 text-[10px] font-extrabold uppercase tracking-[0.18em] text-muted-foreground print:text-black">Receipt</h2>
              <p className="mt-1 font-mono text-xs font-bold text-foreground print:text-black">{payment.invoiceNumber}</p>
              <p className="mt-1 text-xs text-muted-foreground print:text-black">{formatDate(payment.paidAt)}</p>
            </div>
          </div>

          <div className="border-t border-dashed border-border print:border-black" />

          <div className="rounded-2xl bg-muted/70 p-4 print:border print:border-black print:bg-white">
            <h3 className="app-section-label print:text-black">Received from</h3>
            <p className="mt-1 font-display text-lg font-bold text-foreground print:text-black">{payment.memberName}</p>
          </div>

          <div className="space-y-4">
            <div className="flex items-start justify-between gap-4">
              <div className="min-w-0">
                <p className="text-sm font-bold text-foreground print:text-black">{payment.planName || "Membership Fee"}</p>
                {payment.notes && <p className="mt-1 text-xs text-muted-foreground print:text-black">{payment.notes}</p>}
              </div>
              <p className="shrink-0 text-sm font-bold text-foreground print:text-black">{formatCurrency(payment.amount, settings.currency)}</p>
            </div>
            <div className="border-t border-dashed border-border print:border-black" />
            <div className="flex items-end justify-between gap-4">
              <div>
                <p className="app-section-label print:text-black">Payment method</p>
                <p className="mt-1 text-sm font-bold capitalize text-foreground print:text-black">{payment.method.replace("_", " ")}</p>
              </div>
              <div className="text-right">
                <p className="app-section-label print:text-black">Total paid</p>
                <p className="mt-1 font-display text-2xl font-extrabold text-primary print:text-black">{formatCurrency(payment.amount, settings.currency)}</p>
              </div>
            </div>
          </div>

          <p className="pt-2 text-center text-xs font-semibold text-muted-foreground print:text-black">Thank you for training with us.</p>
        </div>
      </div>
    </div>
  );
}
