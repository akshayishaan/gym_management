"use client";

import { useState, useEffect } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import { useForm } from "react-hook-form";
import { toast } from "sonner";
import { ArrowLeft } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { format } from "date-fns";

interface Plan { _id: string; name: string; price: number; durationDays: number; }
interface FormData { memberId: string; memberName: string; planId: string; amount: string; method: string; notes: string; paidAt: string; }

export default function NewPaymentPage() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const [plans, setPlans] = useState<Plan[]>([]);
  const [loading, setLoading] = useState(false);
  const { register, handleSubmit, setValue, watch } = useForm<FormData>({
    defaultValues: {
      memberId: searchParams.get("memberId") || "",
      memberName: searchParams.get("memberName") || "",
      paidAt: format(new Date(), "yyyy-MM-dd"),
      method: "cash",
    },
  });

  useEffect(() => { fetch("/api/plans").then(r => r.json()).then(d => setPlans(Array.isArray(d) ? d : d.plans || [])); }, []);

  const selectedPlanId = watch("planId");
  const selectedPlan = plans.find(p => p._id === selectedPlanId);

  useEffect(() => {
    if (selectedPlan) setValue("amount", String(selectedPlan.price));
  }, [selectedPlan, setValue]);

  async function onSubmit(data: FormData) {
    setLoading(true);
    const plan = plans.find(p => p._id === data.planId);
    const payload = { ...data, amount: Number(data.amount), planName: plan?.name };
    const res = await fetch("/api/payments", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    });
    setLoading(false);
    if (res.ok) {
      toast.success("Payment recorded!");
      const memberId = searchParams.get("memberId");
      router.push(memberId ? `/dashboard/members/${memberId}` : "/dashboard/payments");
    } else {
      toast.error("Failed to record payment");
    }
  }

  return (
    <div className="space-y-6 max-w-lg">
      <div className="flex items-center gap-3">
        <Button variant="ghost" size="icon" onClick={() => router.back()}>
          <ArrowLeft className="h-4 w-4" />
        </Button>
        <div>
          <h1 className="text-2xl font-bold">Record Payment</h1>
          <p className="text-muted-foreground text-sm">Add a new payment entry</p>
        </div>
      </div>

      <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
        <Card>
          <CardHeader><CardTitle className="text-base">Payment Details</CardTitle></CardHeader>
          <CardContent className="space-y-4">
            <div className="space-y-2">
              <Label>Member Name *</Label>
              <Input {...register("memberName", { required: true })} placeholder="Member name" />
            </div>
            <div className="space-y-2">
              <Label>Plan</Label>
              <Select onValueChange={(v) => setValue("planId", v)}>
                <SelectTrigger><SelectValue placeholder="Select plan (optional)" /></SelectTrigger>
                <SelectContent>
                  {plans.map(p => (
                    <SelectItem key={p._id} value={p._id}>{p.name} — ₹{p.price}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div className="space-y-2">
              <Label>Amount (₹) *</Label>
              <Input type="number" {...register("amount", { required: true })} placeholder="1500" />
            </div>
            <div className="space-y-2">
              <Label>Payment Method *</Label>
              <Select defaultValue="cash" onValueChange={(v) => setValue("method", v)}>
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
            <div className="space-y-2">
              <Label>Payment Date *</Label>
              <Input type="date" {...register("paidAt", { required: true })} />
            </div>
            <div className="space-y-2">
              <Label>Notes</Label>
              <Input {...register("notes")} placeholder="Any additional notes" />
            </div>
          </CardContent>
        </Card>
        <div className="flex gap-3">
          <Button type="submit" disabled={loading}>{loading ? "Saving..." : "Record Payment"}</Button>
          <Button type="button" variant="outline" onClick={() => router.back()}>Cancel</Button>
        </div>
      </form>
    </div>
  );
}
