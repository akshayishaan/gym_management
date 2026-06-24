"use client";

import { useState, useEffect, use } from "react";
import { useRouter } from "next/navigation";
import {
  ArrowLeft, MessageCircle, Phone, CreditCard, Pencil,
  User, Mail, MapPin, Calendar, AlertCircle, FileText, History, RefreshCw, RotateCcw,
} from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import { Separator } from "@/components/ui/separator";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { differenceInDays } from "date-fns";
import {
  formatDate, getMemberStatus, buildWhatsAppLink, buildSmsLink, formatCurrency,
} from "@/lib/utils";
import { useGymSettings } from "@/lib/useGymSettings";
import { PaymentFormDialog } from "@/components/dashboard/PaymentFormDialog";
import { MemberFormDialog } from "@/components/dashboard/MemberFormDialog";

interface Member {
  _id: string; name: string; phone: string; email?: string;
  address?: string; gender?: string; dateOfBirth?: string;
  planId?: string; planName?: string; membershipStart?: string;
  membershipExpiry?: string; notes?: string; emergencyContact?: string;
  dueAmount?: number; isActive?: boolean;
}
interface Payment {
  _id: string; amount: number; method: string; paidAt: string;
  invoiceNumber: string; planName?: string;
}
interface Membership {
  _id: string;
  planName: string;
  startDate: string;
  expiryDate: string;
  planPrice?: number;
  amount?: number;
  paymentId?: string;
  createdAt?: string;
}

const statusVariant = {
  active: "success" as const,
  expiring: "warning" as const,
  expired: "destructive" as const,
};

function getInitials(name: string) {
  return name.split(" ").map(n => n[0]).join("").toUpperCase().slice(0, 2);
}

function InfoRow({
  icon: Icon,
  label,
  value,
  mono = false,
}: {
  icon?: React.ElementType;
  label: string;
  value?: string | null;
  mono?: boolean;
}) {
  if (!value) return null;
  return (
    <div className="flex items-start gap-3 py-3">
      {Icon && (
        <div className="mt-0.5 shrink-0 text-muted-foreground">
          <Icon className="h-4 w-4" />
        </div>
      )}
      <div className="flex-1 min-w-0">
        <p className="text-xs text-muted-foreground mb-0.5">{label}</p>
        <p className={`text-sm font-medium break-words ${mono ? "font-mono" : ""}`}>{value}</p>
      </div>
    </div>
  );
}

export default function MemberDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params);
  const router = useRouter();
  const { currency } = useGymSettings();
  const [member, setMember] = useState<Member | null>(null);
  const [payments, setPayments] = useState<Payment[]>([]);
  const [memberships, setMemberships] = useState<Membership[]>([]);
  const [paymentOpen, setPaymentOpen] = useState(false);
  const [editOpen, setEditOpen] = useState(false);

  const fetchMember = () =>
    fetch(`/api/members/${id}`).then(r => r.json()).then(setMember);

  const fetchPayments = () =>
    fetch(`/api/payments?memberId=${id}`).then(r => r.json()).then(d => setPayments(d.payments || []));

  const fetchMemberships = () =>
    fetch(`/api/memberships?memberId=${id}`).then(r => r.json()).then(d => setMemberships(d.memberships || []));

  async function restoreMember() {
    const res = await fetch(`/api/members/${id}`, {
      method: "PUT",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ isActive: true }),
    });
    if (res.ok) { toast.success("Member restored"); fetchMember(); }
    else toast.error("Failed to restore member");
  }

  useEffect(() => {
    Promise.all([fetchMember(), fetchPayments(), fetchMemberships()]);
  }, [id]); // eslint-disable-line react-hooks/exhaustive-deps

  // ── Loading skeleton ────────────────────────────────────────────────────────
  if (!member) {
    return (
      <div className="space-y-6">
        <div className="flex items-center gap-4">
          <div className="h-14 w-14 rounded-full bg-muted animate-pulse shrink-0" />
          <div className="space-y-2">
            <div className="h-7 w-40 bg-muted rounded-lg animate-pulse" />
            <div className="h-4 w-24 bg-muted rounded animate-pulse" />
          </div>
        </div>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          {[1, 2].map(i => (
            <Card key={i} className="border-0 shadow-card">
              <CardContent className="p-6 space-y-4">
                {[...Array(5)].map((_, j) => (
                  <div key={j} className="h-4 bg-muted rounded animate-pulse" />
                ))}
              </CardContent>
            </Card>
          ))}
        </div>
      </div>
    );
  }

  const st = member.membershipExpiry ? getMemberStatus(member.membershipExpiry) : null;
  const reminderMsg = `Hi ${member.name}, your gym membership expires on ${
    member.membershipExpiry ? formatDate(member.membershipExpiry) : "soon"
  }. Please renew to continue! 💪`;

  return (
    <div className="space-y-6">

      {/* ── Header ─────────────────────────────────────────────────────────── */}
      <div className="flex items-start justify-between gap-4 flex-wrap">
        <div className="flex items-center gap-4">
          <Button variant="ghost" size="icon" className="shrink-0" onClick={() => router.back()}>
            <ArrowLeft className="h-4 w-4" />
          </Button>
          <Avatar className="h-12 w-12 shrink-0">
            <AvatarFallback className="bg-primary/10 text-primary font-bold text-base">
              {getInitials(member.name)}
            </AvatarFallback>
          </Avatar>
          <div>
            <div className="flex items-center gap-2 flex-wrap">
              <h1 className="text-2xl font-bold tracking-tight">{member.name}</h1>
              {member.isActive === false ? (
                <Badge variant="destructive">Deleted</Badge>
              ) : st && (
                <Badge variant={statusVariant[st]} className="capitalize">{st}</Badge>
              )}
            </div>
            <p className="text-sm text-muted-foreground mt-0.5">
              {member.planName || "No plan assigned"}
              {member.phone && <span className="text-muted-foreground/50 mx-1.5">·</span>}
              {member.phone && <span>{member.phone}</span>}
            </p>
          </div>
        </div>

        <div className="flex items-center gap-2 flex-wrap">
          {member.isActive === false ? (
            <Button variant="default" size="sm" className="gap-2" onClick={restoreMember}>
              <RotateCcw className="h-4 w-4" /> Restore Member
            </Button>
          ) : (
            <>
              {member.phone && (
                <>
                  <a href={buildWhatsAppLink(member.phone, reminderMsg)} target="_blank" rel="noreferrer">
                    <Button variant="outline" size="sm" className="gap-2 text-success">
                      <MessageCircle className="h-4 w-4" /> WhatsApp
                    </Button>
                  </a>
                  <a href={buildSmsLink(member.phone, reminderMsg)}>
                    <Button variant="outline" size="sm" className="gap-2">
                      <Phone className="h-4 w-4" /> SMS
                    </Button>
                  </a>
                </>
              )}
              {st && (st === "expired" || st === "expiring") && (
                <Button variant="default" size="sm" className="gap-2" onClick={() => setPaymentOpen(true)}>
                  <RefreshCw className="h-4 w-4" /> Renew
                </Button>
              )}
              <Button variant="outline" size="sm" className="gap-2" onClick={() => setPaymentOpen(true)}>
                <CreditCard className="h-4 w-4" /> Record Payment
              </Button>
              <Button size="sm" variant="outline" className="gap-2" onClick={() => setEditOpen(true)}>
                <Pencil className="h-4 w-4" /> Edit
              </Button>
            </>
          )}
        </div>
      </div>

      <Separator />

      {/* ── Tabs ───────────────────────────────────────────────────────────── */}
      <Tabs defaultValue="overview" className="space-y-4">
        <TabsList>
          <TabsTrigger value="overview">Overview</TabsTrigger>
          <TabsTrigger value="memberships">
            Memberships
            {memberships.length > 0 && (
              <Badge variant="secondary" className="ml-1.5 h-5 px-1.5 text-xs">
                {memberships.length}
              </Badge>
            )}
          </TabsTrigger>
          <TabsTrigger value="payments">
            Payments
            {payments.length > 0 && (
              <Badge variant="secondary" className="ml-1.5 h-5 px-1.5 text-xs">
                {payments.length}
              </Badge>
            )}
          </TabsTrigger>
        </TabsList>

        {/* ── Overview Tab ───────────────────────────────────────────────── */}
        <TabsContent value="overview" className="space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">

            {/* Personal Info */}
            <Card className="border-0 shadow-card">
              <CardHeader className="pb-2">
                <CardTitle className="text-base">Personal Info</CardTitle>
              </CardHeader>
              <CardContent className="divide-y divide-border px-6 pb-4">
                <InfoRow icon={Phone} label="Phone" value={member.phone} mono />
                <InfoRow icon={Mail} label="Email" value={member.email} />
                <InfoRow icon={User} label="Gender" value={member.gender ? member.gender.charAt(0).toUpperCase() + member.gender.slice(1) : null} />
                <InfoRow icon={Calendar} label="Date of Birth" value={member.dateOfBirth ? formatDate(member.dateOfBirth) : null} />
                <InfoRow icon={MapPin} label="Address" value={member.address} />
                <InfoRow icon={AlertCircle} label="Emergency Contact" value={member.emergencyContact} mono />
                <InfoRow icon={FileText} label="Notes" value={member.notes} />
              </CardContent>
            </Card>

            {/* Membership */}
            <Card className="border-0 shadow-card">
              <CardHeader className="pb-2">
                <CardTitle className="text-base">Membership</CardTitle>
              </CardHeader>
              <CardContent className="divide-y divide-border px-6 pb-4">
                <InfoRow icon={FileText} label="Plan" value={member.planName} />
                <InfoRow icon={Calendar} label="Start Date" value={member.membershipStart ? formatDate(member.membershipStart) : null} />
                <InfoRow icon={Calendar} label="Expiry Date" value={member.membershipExpiry ? formatDate(member.membershipExpiry) : null} />
                {st && (
                  <div className="flex items-start gap-3 py-3">
                    <div className="mt-0.5 shrink-0 text-muted-foreground">
                      <AlertCircle className="h-4 w-4" />
                    </div>
                    <div className="flex-1 min-w-0">
                      <p className="text-xs text-muted-foreground mb-0.5">Status</p>
                      <Badge variant={statusVariant[st]} className="capitalize">{st}</Badge>
                    </div>
                  </div>
                )}
                <div className="flex items-start gap-3 py-3">
                  <div className="mt-0.5 shrink-0 text-muted-foreground">
                    <AlertCircle className="h-4 w-4" />
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="text-xs text-muted-foreground mb-0.5">Outstanding Balance</p>
                    {(member.dueAmount ?? 0) > 0 ? (
                      <Badge variant="warning" className="font-semibold">
                        {formatCurrency(member.dueAmount!, currency)} due
                      </Badge>
                    ) : (
                      <Badge variant="success" className="font-semibold">Paid in full</Badge>
                    )}
                  </div>
                </div>
              </CardContent>
            </Card>
          </div>
        </TabsContent>

        {/* ── Memberships Tab ────────────────────────────────────────────── */}
        <TabsContent value="memberships">
          <Card className="border-0 shadow-card">
            <CardHeader className="flex flex-row items-center justify-between">
              <div>
                <CardTitle className="text-base">Membership History</CardTitle>
                <CardDescription>
                  {memberships.length} membership period{memberships.length !== 1 ? "s" : ""} recorded
                </CardDescription>
              </div>
              <Button size="sm" variant="outline" className="gap-2" onClick={() => setPaymentOpen(true)}>
                <CreditCard className="h-4 w-4" /> Record Payment
              </Button>
            </CardHeader>
            <CardContent className="p-0">
              {memberships.length === 0 ? (
                <div className="text-center py-12">
                  <div className="inline-flex items-center justify-center w-12 h-12 rounded-full bg-muted mb-3">
                    <History className="h-6 w-6 text-muted-foreground" />
                  </div>
                  <p className="text-sm font-medium">No membership history yet</p>
                  <p className="text-xs text-muted-foreground mt-1">
                    Membership periods are recorded when a payment with a plan is created
                  </p>
                </div>
              ) : (
                <Table>
                  <TableHeader>
                    <TableRow className="hover:bg-transparent">
                      <TableHead>Plan</TableHead>
                      <TableHead>Purchased</TableHead>
                      <TableHead>Period</TableHead>
                      <TableHead>Duration</TableHead>
                      <TableHead>Plan Price</TableHead>
                      <TableHead>Status</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {memberships.map(ms => {
                      const now = new Date();
                      const expiry = new Date(ms.expiryDate);
                      const start = new Date(ms.startDate);
                      const durationDays = differenceInDays(expiry, start);
                      const status = expiry > now
                        ? (differenceInDays(expiry, now) <= 7 ? "expiring" : "active")
                        : "expired";
                      return (
                        <TableRow key={ms._id}>
                          <TableCell className="font-medium">{ms.planName}</TableCell>
                          <TableCell className="text-muted-foreground whitespace-nowrap">
                            {ms.createdAt ? formatDate(ms.createdAt) : "—"}
                          </TableCell>
                          <TableCell className="text-muted-foreground whitespace-nowrap">
                            {formatDate(ms.startDate)} – {formatDate(ms.expiryDate)}
                          </TableCell>
                          <TableCell className="text-muted-foreground">
                            {durationDays} day{durationDays !== 1 ? "s" : ""}
                          </TableCell>
                          <TableCell>
                            {(ms.planPrice ?? ms.amount) != null
                              ? <span className="font-semibold">{formatCurrency((ms.planPrice ?? ms.amount)!, currency)}</span>
                              : <span className="text-muted-foreground">—</span>}
                          </TableCell>
                          <TableCell>
                            <Badge variant={statusVariant[status]} className="capitalize">
                              {status}
                            </Badge>
                          </TableCell>
                        </TableRow>
                      );
                    })}
                  </TableBody>
                </Table>
              )}
            </CardContent>
          </Card>
        </TabsContent>

        {/* ── Payments Tab ───────────────────────────────────────────────── */}
        <TabsContent value="payments">
          <Card className="border-0 shadow-card">
            <CardHeader className="flex flex-row items-center justify-between">
              <div>
                <CardTitle className="text-base">Payment History</CardTitle>
                <CardDescription>
                  {payments.length} payment{payments.length !== 1 ? "s" : ""} recorded
                </CardDescription>
              </div>
              <Button size="sm" variant="outline" className="gap-2" onClick={() => setPaymentOpen(true)}>
                <CreditCard className="h-4 w-4" /> Record Payment
              </Button>
            </CardHeader>
            <CardContent className="p-0">
              {payments.length === 0 ? (
                <div className="text-center py-12">
                  <div className="inline-flex items-center justify-center w-12 h-12 rounded-full bg-muted mb-3">
                    <CreditCard className="h-6 w-6 text-muted-foreground" />
                  </div>
                  <p className="text-sm font-medium">No payments yet</p>
                  <p className="text-xs text-muted-foreground mt-1">
                    Record the first payment to see it here
                  </p>
                </div>
              ) : (
                <Table>
                  <TableHeader>
                    <TableRow className="hover:bg-transparent">
                      <TableHead>Invoice</TableHead>
                      <TableHead>Plan</TableHead>
                      <TableHead>Method</TableHead>
                      <TableHead>Date</TableHead>
                      <TableHead className="text-right">Amount</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {payments.map(p => (
                      <TableRow key={p._id}>
                        <TableCell className="font-medium">{p.invoiceNumber}</TableCell>
                        <TableCell className="text-muted-foreground">{p.planName || "—"}</TableCell>
                        <TableCell className="capitalize">{p.method.replace("_", " ")}</TableCell>
                        <TableCell>{formatDate(p.paidAt)}</TableCell>
                        <TableCell className="text-right font-semibold text-success">
                          {formatCurrency(p.amount, currency)}
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              )}
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>

      {/* ── Dialogs ────────────────────────────────────────────────────────── */}
      <PaymentFormDialog
        open={paymentOpen}
        onOpenChange={setPaymentOpen}
        prefillMemberId={id}
        prefillMemberName={member.name}
        onSuccess={() => {
          fetchPayments();
          fetchMemberships();
          fetchMember();
        }}
      />

      <MemberFormDialog
        open={editOpen}
        onOpenChange={setEditOpen}
        showMembership={false}
        initialData={member}
        onSuccess={() => fetchMember()}
      />
    </div>
  );
}
