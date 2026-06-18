"use client";

import { useState, useEffect, use } from "react";
import { useRouter } from "next/navigation";
import { useForm } from "react-hook-form";
import { toast } from "sonner";
import { ArrowLeft, MessageCircle, Phone, CreditCard } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Badge } from "@/components/ui/badge";
import { addDays, format } from "date-fns";
import { formatDate, getMemberStatus, buildWhatsAppLink, buildSmsLink, formatCurrency } from "@/lib/utils";
import Link from "next/link";

interface Plan { _id: string; name: string; durationDays: number; price: number; }
interface Member {
  _id: string; name: string; phone: string; email?: string;
  address?: string; gender?: string; dateOfBirth?: string;
  planId?: string; planName?: string; membershipStart?: string;
  membershipExpiry?: string; notes?: string; emergencyContact?: string;
}
interface Payment {
  _id: string; amount: number; method: string; paidAt: string;
  invoiceNumber: string; planName?: string;
}

const statusVariant = { active: "success" as const, expiring: "warning" as const, expired: "destructive" as const };

export default function MemberDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params);
  const router = useRouter();
  const [member, setMember] = useState<Member | null>(null);
  const [plans, setPlans] = useState<Plan[]>([]);
  const [payments, setPayments] = useState<Payment[]>([]);
  const [editing, setEditing] = useState(false);
  const [loading, setLoading] = useState(false);
  const { register, handleSubmit, watch, setValue, reset } = useForm<Member>();

  useEffect(() => {
    Promise.all([
      fetch(`/api/members/${id}`).then(r => r.json()),
      fetch("/api/plans").then(r => r.json()),
      fetch(`/api/payments?memberId=${id}`).then(r => r.json()),
    ]).then(([m, p, pay]) => {
      setMember(m);
      setPlans(Array.isArray(p) ? p : p.plans || []);
      setPayments(pay.payments || []);
      reset(m);
    });
  }, [id, reset]);

  const selectedPlanId = watch("planId");
  const membershipStart = watch("membershipStart");
  const selectedPlan = plans.find(p => p._id === selectedPlanId);
  const expiryDate = selectedPlan && membershipStart
    ? format(addDays(new Date(membershipStart), selectedPlan.durationDays), "yyyy-MM-dd")
    : member?.membershipExpiry ? format(new Date(member.membershipExpiry), "yyyy-MM-dd") : "";

  async function onSubmit(data: Member) {
    setLoading(true);
    const plan = plans.find(p => p._id === data.planId);
    const payload = { ...data, planName: plan?.name || member?.planName, membershipExpiry: expiryDate || data.membershipExpiry };
    const res = await fetch(`/api/members/${id}`, {
      method: "PUT",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    });
    setLoading(false);
    if (res.ok) {
      const updated = await res.json();
      setMember(updated);
      toast.success("Member updated!");
      setEditing(false);
    } else {
      toast.error("Failed to update");
    }
  }

  if (!member) return <div><div className="h-48 bg-muted rounded animate-pulse" /></div>;

  const st = member.membershipExpiry ? getMemberStatus(member.membershipExpiry) : null;
  const reminderMsg = `Hi ${member.name}, your gym membership expires on ${member.membershipExpiry ? formatDate(member.membershipExpiry) : "soon"}. Please renew to continue! 💪`;

  return (
    <div className="space-y-6 max-w-3xl">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <Button variant="ghost" size="icon" onClick={() => router.back()}>
            <ArrowLeft className="h-4 w-4" />
          </Button>
          <div>
            <div className="flex items-center gap-2">
              <h1 className="text-2xl font-bold">{member.name}</h1>
              {st && <Badge variant={statusVariant[st]} className="capitalize">{st}</Badge>}
            </div>
            <p className="text-muted-foreground text-sm">{member.planName || "No plan"}</p>
          </div>
        </div>
        <div className="flex gap-2">
          {member.phone && (
            <>
              <a href={buildWhatsAppLink(member.phone, reminderMsg)} target="_blank" rel="noreferrer">
                <Button variant="outline" size="sm" className="text-green-600 border-green-200">
                  <MessageCircle className="h-4 w-4 mr-2" /> WhatsApp
                </Button>
              </a>
              <a href={buildSmsLink(member.phone, reminderMsg)}>
                <Button variant="outline" size="sm" className="text-blue-600 border-blue-200">
                  <Phone className="h-4 w-4 mr-2" /> SMS
                </Button>
              </a>
            </>
          )}
          <Link href={`/dashboard/payments/new?memberId=${id}&memberName=${encodeURIComponent(member.name)}`}>
            <Button variant="outline" size="sm">
              <CreditCard className="h-4 w-4 mr-2" /> Record Payment
            </Button>
          </Link>
          <Button size="sm" onClick={() => setEditing(!editing)}>
            {editing ? "Cancel" : "Edit"}
          </Button>
        </div>
      </div>

      {editing ? (
        <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
          <Card>
            <CardHeader><CardTitle className="text-base">Personal Info</CardTitle></CardHeader>
            <CardContent className="grid grid-cols-2 gap-4">
              <div className="space-y-2 col-span-2">
                <Label>Full Name</Label>
                <Input {...register("name")} />
              </div>
              <div className="space-y-2"><Label>Phone</Label><Input {...register("phone")} /></div>
              <div className="space-y-2"><Label>Email</Label><Input {...register("email")} /></div>
              <div className="space-y-2"><Label>Date of Birth</Label><Input type="date" {...register("dateOfBirth")} /></div>
              <div className="space-y-2">
                <Label>Gender</Label>
                <Select defaultValue={member.gender} onValueChange={(v) => setValue("gender", v)}>
                  <SelectTrigger><SelectValue /></SelectTrigger>
                  <SelectContent>
                    <SelectItem value="male">Male</SelectItem>
                    <SelectItem value="female">Female</SelectItem>
                    <SelectItem value="other">Other</SelectItem>
                  </SelectContent>
                </Select>
              </div>
              <div className="space-y-2 col-span-2"><Label>Address</Label><Input {...register("address")} /></div>
              <div className="space-y-2"><Label>Emergency Contact</Label><Input {...register("emergencyContact")} /></div>
              <div className="space-y-2 col-span-2"><Label>Notes</Label><Input {...register("notes")} /></div>
            </CardContent>
          </Card>
          <Card>
            <CardHeader><CardTitle className="text-base">Membership</CardTitle></CardHeader>
            <CardContent className="grid grid-cols-2 gap-4">
              <div className="space-y-2 col-span-2">
                <Label>Plan</Label>
                <Select defaultValue={member.planId} onValueChange={(v) => setValue("planId", v)}>
                  <SelectTrigger><SelectValue placeholder="Select plan" /></SelectTrigger>
                  <SelectContent>
                    {plans.map(p => (
                      <SelectItem key={p._id} value={p._id}>{p.name} — ₹{p.price}</SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
              <div className="space-y-2"><Label>Start Date</Label><Input type="date" {...register("membershipStart")} /></div>
              <div className="space-y-2"><Label>Expiry Date</Label><Input value={expiryDate} disabled /></div>
            </CardContent>
          </Card>
          <div className="flex gap-3">
            <Button type="submit" disabled={loading}>{loading ? "Saving..." : "Save Changes"}</Button>
            <Button type="button" variant="outline" onClick={() => setEditing(false)}>Cancel</Button>
          </div>
        </form>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <Card>
            <CardHeader><CardTitle className="text-base">Personal Info</CardTitle></CardHeader>
            <CardContent className="space-y-3 text-sm">
              {[
                ["Phone", member.phone],
                ["Email", member.email],
                ["Gender", member.gender],
                ["Date of Birth", member.dateOfBirth ? formatDate(member.dateOfBirth) : null],
                ["Address", member.address],
                ["Emergency Contact", member.emergencyContact],
                ["Notes", member.notes],
              ].map(([label, val]) => val ? (
                <div key={label as string} className="flex justify-between">
                  <span className="text-muted-foreground">{label}</span>
                  <span className="font-medium capitalize">{val as string}</span>
                </div>
              ) : null)}
            </CardContent>
          </Card>

          <Card>
            <CardHeader><CardTitle className="text-base">Membership</CardTitle></CardHeader>
            <CardContent className="space-y-3 text-sm">
              {[
                ["Plan", member.planName],
                ["Start Date", member.membershipStart ? formatDate(member.membershipStart) : null],
                ["Expiry Date", member.membershipExpiry ? formatDate(member.membershipExpiry) : null],
                ["Status", st],
              ].map(([label, val]) => val ? (
                <div key={label as string} className="flex justify-between">
                  <span className="text-muted-foreground">{label}</span>
                  {label === "Status" ? (
                    <Badge variant={statusVariant[val as keyof typeof statusVariant]} className="capitalize">{val as string}</Badge>
                  ) : (
                    <span className="font-medium capitalize">{val as string}</span>
                  )}
                </div>
              ) : null)}
            </CardContent>
          </Card>

          <Card className="md:col-span-2">
            <CardHeader><CardTitle className="text-base">Payment History</CardTitle></CardHeader>
            <CardContent>
              {payments.length === 0 ? (
                <p className="text-sm text-muted-foreground text-center py-4">No payments recorded</p>
              ) : (
                <div className="space-y-2">
                  {payments.map(p => (
                    <div key={p._id} className="flex items-center justify-between text-sm p-2 rounded border">
                      <div>
                        <p className="font-medium">{p.invoiceNumber}</p>
                        <p className="text-xs text-muted-foreground capitalize">{p.method} · {formatDate(p.paidAt)} · {p.planName}</p>
                      </div>
                      <span className="font-semibold text-green-600">{formatCurrency(p.amount)}</span>
                    </div>
                  ))}
                </div>
              )}
            </CardContent>
          </Card>
        </div>
      )}
    </div>
  );
}
