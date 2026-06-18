"use client";

import { useEffect, use } from "react";
import { useRouter } from "next/navigation";
import { Button } from "@/components/ui/button";
import { ArrowLeft, Printer } from "lucide-react";
import { useState } from "react";
import { formatDate, formatCurrency } from "@/lib/utils";

interface Payment {
  _id: string; memberName: string; amount: number; method: string;
  invoiceNumber: string; paidAt: string; planName?: string; notes?: string;
}
interface Settings { gymName: string; address?: string; phone?: string; email?: string; }

export default function InvoicePage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params);
  const router = useRouter();
  const [payment, setPayment] = useState<Payment | null>(null);
  const [settings, setSettings] = useState<Settings>({ gymName: "My Gym" });

  useEffect(() => {
    Promise.all([
      fetch(`/api/payments/${id}`).then(r => r.json()),
      fetch("/api/settings").then(r => r.json()),
    ]).then(([p, s]) => { setPayment(p); setSettings(s); });
  }, [id]);

  if (!payment) return <div><div className="h-48 bg-muted rounded animate-pulse" /></div>;

  return (
    <div className="max-w-2xl space-y-4">
      <div className="flex items-center gap-3 print:hidden">
        <Button variant="ghost" size="icon" onClick={() => router.back()}><ArrowLeft className="h-4 w-4" /></Button>
        <Button onClick={() => window.print()}><Printer className="h-4 w-4 mr-2" />Print Invoice</Button>
      </div>

      <div className="border rounded-lg p-8 space-y-6 bg-white" id="invoice">
        <div className="flex justify-between items-start">
          <div>
            <h1 className="text-2xl font-bold">{settings.gymName}</h1>
            {settings.address && <p className="text-sm text-gray-600">{settings.address}</p>}
            {settings.phone && <p className="text-sm text-gray-600">{settings.phone}</p>}
            {settings.email && <p className="text-sm text-gray-600">{settings.email}</p>}
          </div>
          <div className="text-right">
            <h2 className="text-xl font-bold text-primary">INVOICE</h2>
            <p className="text-sm font-mono">{payment.invoiceNumber}</p>
            <p className="text-sm text-gray-600">Date: {formatDate(payment.paidAt)}</p>
          </div>
        </div>

        <hr />

        <div>
          <h3 className="font-semibold text-sm text-gray-500 uppercase tracking-wide mb-1">Bill To</h3>
          <p className="font-medium text-lg">{payment.memberName}</p>
        </div>

        <table className="w-full text-sm border-collapse">
          <thead>
            <tr className="border-b border-gray-200">
              <th className="text-left py-2 font-semibold">Description</th>
              <th className="text-right py-2 font-semibold">Amount</th>
            </tr>
          </thead>
          <tbody>
            <tr className="border-b border-gray-100">
              <td className="py-3">
                <p className="font-medium">{payment.planName || "Membership Fee"}</p>
                {payment.notes && <p className="text-gray-500 text-xs">{payment.notes}</p>}
              </td>
              <td className="text-right py-3 font-medium">{formatCurrency(payment.amount)}</td>
            </tr>
          </tbody>
          <tfoot>
            <tr>
              <td className="py-3 font-bold">Total</td>
              <td className="text-right py-3 font-bold text-lg">{formatCurrency(payment.amount)}</td>
            </tr>
          </tfoot>
        </table>

        <div className="flex justify-between text-sm text-gray-600">
          <span>Payment Method: <strong className="capitalize">{payment.method.replace("_", " ")}</strong></span>
          <span className="bg-green-100 text-green-700 px-3 py-1 rounded-full font-medium">PAID</span>
        </div>

        <p className="text-center text-xs text-gray-400 pt-4">Thank you for your membership! 💪</p>
      </div>
    </div>
  );
}
