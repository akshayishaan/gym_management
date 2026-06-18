"use client";

import { useState, useEffect } from "react";
import { useRouter } from "next/navigation";
import { useForm } from "react-hook-form";
import { toast } from "sonner";
import { ArrowLeft } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { addDays, format } from "date-fns";

interface Plan { _id: string; name: string; durationDays: number; price: number; }
interface FormData {
  name: string; email: string; phone: string; address: string;
  gender: string; dateOfBirth: string; planId: string;
  membershipStart: string; notes: string; emergencyContact: string;
}

export default function NewMemberPage() {
  const router = useRouter();
  const [plans, setPlans] = useState<Plan[]>([]);
  const [loading, setLoading] = useState(false);
  const { register, handleSubmit, watch, setValue } = useForm<FormData>({
    defaultValues: { membershipStart: format(new Date(), "yyyy-MM-dd") },
  });

  useEffect(() => {
    fetch("/api/plans").then(r => r.json()).then(d => setPlans(Array.isArray(d) ? d : d.plans || []));
  }, []);

  const selectedPlanId = watch("planId");
  const membershipStart = watch("membershipStart");

  const selectedPlan = plans.find(p => p._id === selectedPlanId);
  const expiryDate = selectedPlan && membershipStart
    ? format(addDays(new Date(membershipStart), selectedPlan.durationDays), "yyyy-MM-dd")
    : "";

  async function onSubmit(data: FormData) {
    setLoading(true);
    const plan = plans.find(p => p._id === data.planId);
    const payload = {
      ...data,
      planName: plan?.name,
      membershipExpiry: expiryDate || undefined,
    };
    const res = await fetch("/api/members", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    });
    setLoading(false);
    if (res.ok) {
      toast.success("Member added successfully!");
      router.push("/dashboard/members");
    } else {
      toast.error("Failed to add member");
    }
  }

  return (
    <div className="space-y-6 max-w-2xl">
      <div className="flex items-center gap-3">
        <Button variant="ghost" size="icon" onClick={() => router.back()}>
          <ArrowLeft className="h-4 w-4" />
        </Button>
        <div>
          <h1 className="text-2xl font-bold">Add New Member</h1>
          <p className="text-muted-foreground text-sm">Fill in the member details below</p>
        </div>
      </div>

      <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
        <Card>
          <CardHeader><CardTitle className="text-base">Personal Info</CardTitle></CardHeader>
          <CardContent className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2 col-span-2">
                <Label htmlFor="name">Full Name *</Label>
                <Input id="name" {...register("name", { required: true })} placeholder="John Doe" />
              </div>
              <div className="space-y-2">
                <Label htmlFor="phone">Phone *</Label>
                <Input id="phone" {...register("phone", { required: true })} placeholder="+91 98765 43210" />
              </div>
              <div className="space-y-2">
                <Label htmlFor="email">Email</Label>
                <Input id="email" type="email" {...register("email")} placeholder="john@example.com" />
              </div>
              <div className="space-y-2">
                <Label htmlFor="dateOfBirth">Date of Birth</Label>
                <Input id="dateOfBirth" type="date" {...register("dateOfBirth")} />
              </div>
              <div className="space-y-2">
                <Label htmlFor="gender">Gender</Label>
                <Select onValueChange={(v) => setValue("gender", v)}>
                  <SelectTrigger>
                    <SelectValue placeholder="Select gender" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="male">Male</SelectItem>
                    <SelectItem value="female">Female</SelectItem>
                    <SelectItem value="other">Other</SelectItem>
                  </SelectContent>
                </Select>
              </div>
              <div className="space-y-2 col-span-2">
                <Label htmlFor="address">Address</Label>
                <Input id="address" {...register("address")} placeholder="123 Main Street, City" />
              </div>
              <div className="space-y-2">
                <Label htmlFor="emergencyContact">Emergency Contact</Label>
                <Input id="emergencyContact" {...register("emergencyContact")} placeholder="+91 98765 43210" />
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader><CardTitle className="text-base">Membership</CardTitle></CardHeader>
          <CardContent className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2 col-span-2">
                <Label>Membership Plan</Label>
                <Select onValueChange={(v) => setValue("planId", v)}>
                  <SelectTrigger>
                    <SelectValue placeholder="Select a plan" />
                  </SelectTrigger>
                  <SelectContent>
                    {plans.map(p => (
                      <SelectItem key={p._id} value={p._id}>
                        {p.name} — ₹{p.price} / {p.durationDays} days
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
              <div className="space-y-2">
                <Label htmlFor="membershipStart">Start Date</Label>
                <Input id="membershipStart" type="date" {...register("membershipStart")} />
              </div>
              <div className="space-y-2">
                <Label>Expiry Date</Label>
                <Input value={expiryDate} readOnly disabled placeholder="Auto-calculated" />
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader><CardTitle className="text-base">Notes</CardTitle></CardHeader>
          <CardContent>
            <Input {...register("notes")} placeholder="Any additional notes..." />
          </CardContent>
        </Card>

        <div className="flex gap-3">
          <Button type="submit" disabled={loading}>
            {loading ? "Saving..." : "Add Member"}
          </Button>
          <Button type="button" variant="outline" onClick={() => router.back()}>Cancel</Button>
        </div>
      </form>
    </div>
  );
}
