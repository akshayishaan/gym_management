"use client";

import { useState, use } from "react";
import { useQueryClient } from "@tanstack/react-query";
import {
  MessageCircle, Phone, CreditCard, Pencil,
  User, Mail, MapPin, Calendar, AlertCircle, FileText, History, RefreshCw, RotateCcw, Undo2,
} from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import {
  formatDate, getMemberStatus, buildWhatsAppLink, buildSmsLink, formatCurrency,
} from "@/lib/utils";
import { useGymSettings } from "@/lib/useGymSettings";
import { PaymentFormDialog } from "@/components/dashboard/PaymentFormDialog";
import { MemberForm } from "@/components/dashboard/MemberForm";
import { StackHeader } from "@/components/layout/StackHeader";
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
  AlertDialogTrigger,
} from "@/components/ui/alert-dialog";
import {
  calendarDaysBetween,
  membershipStatus,
  todayInTimeZone,
} from "@/lib/membershipCalendar";
import { useMember } from "@/lib/hooks/useMembers";
import { usePayments } from "@/lib/hooks/usePayments";
import { useMemberships } from "@/lib/hooks/useMemberships";
import { createRequestId } from "@/lib/clientRequestId";

const statusVariant = {
  active: "success" as const,
  expiring: "warning" as const,
  expired: "destructive" as const,
  reversed: "secondary" as const,
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
  const { currency, timezone, selectedGymId } = useGymSettings();
  const queryClient = useQueryClient();
  const memberQuery = useMember(id);
  const paymentsQuery = usePayments({ memberId: id, limit: 100 });
  const membershipsQuery = useMemberships(id);
  const member = memberQuery.data;
  const payments = paymentsQuery.data?.payments ?? [];
  const memberships = membershipsQuery.data?.memberships ?? [];
  const [paymentOpen, setPaymentOpen] = useState(false);
  const [editOpen, setEditOpen] = useState(false);

  const invalidateMemberLifecycle = () => queryClient.invalidateQueries({
    queryKey: ["gym", selectedGymId],
  });

  async function restoreMember() {
    const res = await fetch(`/api/members/${id}`, {
      method: "PUT",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ isActive: true }),
    });
    if (res.ok) {
      toast.success("Member restored");
      await invalidateMemberLifecycle();
    }
    else toast.error("Failed to restore member");
  }

  async function reversePlanPurchase(membershipId: string) {
    const response = await fetch(`/api/memberships/${membershipId}/reverse`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ requestId: createRequestId() }),
    });
    const data = await response.json();
    if (!response.ok) {
      toast.error(data.error || "Could not reverse Plan purchase");
      return;
    }
    toast.success("Plan purchase reversed");
    await invalidateMemberLifecycle();
  }

  if (memberQuery.isLoading) {
    return (
      <div className="app-canvas flex min-h-svh flex-col">
        <StackHeader title="Member" />
        <div className="flex-1 space-y-4 px-4 py-4">
          <div className="flex items-center gap-3">
            <div className="h-14 w-14 shrink-0 animate-pulse rounded-full bg-muted" />
            <div className="space-y-2">
              <div className="h-5 w-40 animate-pulse rounded bg-muted" />
              <div className="h-4 w-24 animate-pulse rounded bg-muted" />
            </div>
          </div>
          {[1, 2].map(i => (
            <div key={i} className="h-40 animate-pulse rounded-2xl border bg-card" />
          ))}
        </div>
      </div>
    );
  }

  if (!member) {
    return (
      <div className="app-canvas flex min-h-svh flex-col">
        <StackHeader title="Member" />
        <div className="flex flex-1 flex-col items-center justify-center px-6 text-center">
          <AlertCircle className="h-8 w-8 text-destructive" />
          <p className="mt-3 font-display text-lg font-bold">Member could not load</p>
          <p className="mt-1 text-sm text-muted-foreground">
            {memberQuery.error instanceof Error ? memberQuery.error.message : "Please try again."}
          </p>
          <Button className="mt-5" variant="outline" onClick={() => void memberQuery.refetch()}>
            Try again
          </Button>
        </div>
      </div>
    );
  }

  const st = member.membershipExpiry ? getMemberStatus(member.membershipExpiry, timezone) : null;
  const reminderMsg = `Hi ${member.name}, your gym membership expires on ${
    member.membershipExpiry ? formatDate(member.membershipExpiry) : "soon"
  }. Please renew to continue! 💪`;

  return (
    <div className="app-canvas flex min-h-svh flex-col">
      <StackHeader
        title={member.name}
        actions={
          member.isActive !== false ? (
            <Button
              aria-label="Edit member"
              size="icon"
              variant="ghost"
              className="h-9 w-9"
              onClick={() => setEditOpen(true)}
            >
              <Pencil className="h-4 w-4" />
            </Button>
          ) : undefined
        }
      />

      <div className="app-screen flex-1 space-y-5 px-5 py-5">
        {/* ── Profile summary ─────────────────────────────────────── */}
        <section className="relative overflow-hidden rounded-[2rem] bg-foreground p-5 text-background shadow-xl shadow-foreground/15">
          <div className="absolute -right-12 -top-14 h-40 w-40 rounded-full bg-primary/55 blur-2xl" />
          <div className="relative flex items-center gap-4">
          <Avatar className="h-16 w-16 shrink-0 ring-4 ring-background/10">
            <AvatarFallback className="bg-background/10 text-lg font-extrabold text-primary">
              {getInitials(member.name)}
            </AvatarFallback>
          </Avatar>
          <div className="min-w-0 flex-1">
            <div className="flex flex-wrap items-center gap-2">
              <p className="truncate font-display text-xl font-extrabold">{member.name}</p>
              {member.isActive === false ? (
                <Badge variant="destructive">Deleted</Badge>
              ) : st && (
                <Badge variant={statusVariant[st]} className="capitalize">{st}</Badge>
              )}
            </div>
            <p className="mt-1 truncate text-xs font-semibold text-background/55">
              {member.planName || "No plan assigned"} {member.phone && `· ${member.phone}`}
            </p>
            <p className={`mt-3 text-xs font-bold ${(member.dueAmount ?? 0) > 0 ? "text-warning" : "text-success"}`}>
              {(member.dueAmount ?? 0) > 0
                ? `${formatCurrency(member.dueAmount!, currency)} outstanding`
                : "Account paid in full"}
            </p>
          </div>
          </div>
        </section>

        {/* ── Actions row ─────────────────────────────────────────── */}
        <div className="app-surface grid grid-cols-4 gap-1 rounded-[1.75rem] p-2">
          {member.isActive === false ? (
            <Button size="sm" className="col-span-4 h-12 gap-2" onClick={restoreMember}>
              <RotateCcw className="h-4 w-4" /> Restore Member
            </Button>
          ) : (
            <>
              {member.phone && (
                <>
                  <a href={buildWhatsAppLink(member.phone, reminderMsg)} target="_blank" rel="noreferrer">
                    <Button variant="ghost" className="h-[4.5rem] w-full flex-col gap-1 rounded-2xl px-1 text-[10px] font-bold text-success">
                      <MessageCircle className="h-5 w-5" /> WhatsApp
                    </Button>
                  </a>
                  <a href={buildSmsLink(member.phone, reminderMsg)}>
                    <Button variant="ghost" className="h-[4.5rem] w-full flex-col gap-1 rounded-2xl px-1 text-[10px] font-bold">
                      <Phone className="h-5 w-5" /> SMS
                    </Button>
                  </a>
                </>
              )}
              {st && (st === "expired" || st === "expiring") && (
                <Button variant="ghost" className="h-[4.5rem] w-full flex-col gap-1 rounded-2xl px-1 text-[10px] font-bold text-primary" onClick={() => setPaymentOpen(true)}>
                  <RefreshCw className="h-5 w-5" /> Renew
                </Button>
              )}
              <Button variant="ghost" className="h-[4.5rem] w-full flex-col gap-1 rounded-2xl px-1 text-[10px] font-bold" onClick={() => setPaymentOpen(true)}>
                <CreditCard className="h-5 w-5" /> Payment
              </Button>
            </>
          )}
        </div>

        {/* ── Tabs ───────────────────────────────────────────────── */}
        <Tabs defaultValue="overview" className="space-y-4">
          <TabsList className="grid w-full grid-cols-3">
            <TabsTrigger value="overview">Overview</TabsTrigger>
            <TabsTrigger value="memberships">
              History
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

          {/* ── Overview Tab ───────────────────────────────────── */}
          <TabsContent value="overview" className="space-y-4">
            <Card className="overflow-hidden rounded-[1.75rem] border-0 shadow-card">
              <CardHeader className="px-4 pb-2 pt-4">
                <CardTitle className="font-display text-base font-bold">Personal Info</CardTitle>
              </CardHeader>
              <CardContent className="divide-y divide-border px-4 pb-4">
                <InfoRow icon={Phone} label="Phone" value={member.phone} mono />
                <InfoRow icon={Mail} label="Email" value={member.email} />
                <InfoRow icon={User} label="Gender" value={member.gender ? member.gender.charAt(0).toUpperCase() + member.gender.slice(1) : null} />
                <InfoRow icon={Calendar} label="Date of Birth" value={member.dateOfBirth ? formatDate(member.dateOfBirth) : null} />
                <InfoRow icon={MapPin} label="Address" value={member.address} />
                <InfoRow icon={AlertCircle} label="Emergency Contact" value={member.emergencyContact} mono />
                <InfoRow icon={FileText} label="Notes" value={member.notes} />
              </CardContent>
            </Card>

            <Card className="overflow-hidden rounded-[1.75rem] border-0 shadow-card">
              <CardHeader className="px-4 pb-2 pt-4">
                <CardTitle className="font-display text-base font-bold">Membership</CardTitle>
              </CardHeader>
              <CardContent className="divide-y divide-border px-4 pb-4">
                <InfoRow icon={FileText} label="Plan" value={member.planName} />
                <InfoRow icon={Calendar} label="Start Date" value={member.membershipStart ? formatDate(member.membershipStart) : null} />
                <InfoRow icon={Calendar} label="Expiry Date" value={member.membershipExpiry ? formatDate(member.membershipExpiry) : null} />
                {st && (
                  <div className="flex items-start gap-3 py-3">
                    <div className="mt-0.5 shrink-0 text-muted-foreground">
                      <AlertCircle className="h-4 w-4" />
                    </div>
                    <div className="min-w-0 flex-1">
                      <p className="mb-0.5 text-xs text-muted-foreground">Status</p>
                      <Badge variant={statusVariant[st]} className="capitalize">{st}</Badge>
                    </div>
                  </div>
                )}
                <div className="flex items-start gap-3 py-3">
                  <div className="mt-0.5 shrink-0 text-muted-foreground">
                    <AlertCircle className="h-4 w-4" />
                  </div>
                  <div className="min-w-0 flex-1">
                    <p className="mb-0.5 text-xs text-muted-foreground">Outstanding Balance</p>
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
          </TabsContent>

          {/* ── Memberships Tab ────────────────────────────────── */}
          <TabsContent value="memberships">
            {memberships.length === 0 ? (
              <div className="py-12 text-center">
                <div className="mb-3 inline-flex h-12 w-12 items-center justify-center rounded-full bg-muted">
                  <History className="h-6 w-6 text-muted-foreground" />
                </div>
                <p className="text-sm font-medium">No membership history yet</p>
                <p className="mt-1 text-xs text-muted-foreground">
                  Membership periods are recorded when a payment with a plan is created
                </p>
              </div>
            ) : (
              <div className="space-y-2">
                {memberships.map(ms => {
                  const durationDays = calendarDaysBetween(ms.startDate, ms.expiryDate) + 1;
                  const status = ms.status === "reversed"
                    ? "reversed"
                    : membershipStatus(ms.expiryDate, todayInTimeZone(timezone));
                  return (
                    <div key={ms._id} className={`app-surface space-y-2 rounded-[1.5rem] p-4 ${status === "reversed" ? "bg-muted/40" : ""}`}>
                      <div className="flex items-center justify-between gap-2">
                        <p className="truncate text-sm font-semibold">{ms.planName}</p>
                        <Badge variant={statusVariant[status]} className="shrink-0 capitalize">{status}</Badge>
                      </div>
                      <div className="flex items-center justify-between text-xs text-muted-foreground">
                        <span>{formatDate(ms.startDate)} – {formatDate(ms.expiryDate)}</span>
                        <span>{durationDays} day{durationDays !== 1 ? "s" : ""}</span>
                      </div>
                      <div className="flex items-center justify-between text-xs">
                        <span className="text-muted-foreground">
                          Purchased {ms.createdAt ? formatDate(ms.createdAt) : "—"}
                        </span>
                        {(ms.planPrice ?? ms.amount) != null ? (
                          <span className="font-semibold">{formatCurrency((ms.planPrice ?? ms.amount)!, currency)}</span>
                        ) : (
                          <span className="text-muted-foreground">—</span>
                        )}
                      </div>
                      {status !== "reversed" && (
                        <AlertDialog>
                          <AlertDialogTrigger asChild>
                            <Button variant="outline" size="sm" className="mt-2 w-full gap-2 text-destructive">
                              <Undo2 className="h-4 w-4" /> Reverse Plan purchase
                            </Button>
                          </AlertDialogTrigger>
                          <AlertDialogContent>
                            <AlertDialogHeader>
                              <AlertDialogTitle>Reverse {ms.planName}?</AlertDialogTitle>
                              <AlertDialogDescription>
                                This Membership period will be reversed and its associated Payment will be voided. Newer Membership transactions must be reversed first.
                              </AlertDialogDescription>
                            </AlertDialogHeader>
                            <AlertDialogFooter>
                              <AlertDialogCancel>Cancel</AlertDialogCancel>
                              <AlertDialogAction
                                className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
                                onClick={() => void reversePlanPurchase(ms._id)}
                              >
                                Reverse purchase
                              </AlertDialogAction>
                            </AlertDialogFooter>
                          </AlertDialogContent>
                        </AlertDialog>
                      )}
                    </div>
                  );
                })}
              </div>
            )}
          </TabsContent>

          {/* ── Payments Tab ───────────────────────────────────── */}
          <TabsContent value="payments">
            {payments.length === 0 ? (
              <div className="py-12 text-center">
                <div className="mb-3 inline-flex h-12 w-12 items-center justify-center rounded-full bg-muted">
                  <CreditCard className="h-6 w-6 text-muted-foreground" />
                </div>
                <p className="text-sm font-medium">No payments yet</p>
                <p className="mt-1 text-xs text-muted-foreground">
                  Record the first payment to see it here
                </p>
              </div>
            ) : (
              <div className="space-y-2">
                {payments.map(p => (
                  <div key={p._id} className={`app-surface flex items-center justify-between gap-3 rounded-[1.5rem] p-4 ${p.status !== "paid" ? "bg-muted/40" : ""}`}>
                    <div className="min-w-0 flex-1">
                      <div className="flex items-center gap-2">
                        <p className="truncate text-sm font-semibold">{p.invoiceNumber}</p>
                        {p.status !== "paid" && (
                          <Badge variant={p.status === "refunded" ? "warning" : "secondary"} className="capitalize">
                            {p.status}
                          </Badge>
                        )}
                      </div>
                      <p className="truncate text-xs capitalize text-muted-foreground">
                        {p.planName ? `${p.planName} · ` : ""}{p.method.replace("_", " ")} · {formatDate(p.paidAt)}
                      </p>
                    </div>
                    <span className={`shrink-0 text-sm font-semibold ${p.status === "paid" ? "text-success" : "text-muted-foreground line-through"}`}>
                      {formatCurrency(p.amount, currency)}
                    </span>
                  </div>
                ))}
              </div>
            )}
          </TabsContent>
        </Tabs>
      </div>

      {/* ── Dialogs ────────────────────────────────────────────── */}
      <PaymentFormDialog
        open={paymentOpen}
        onOpenChange={setPaymentOpen}
        prefillMemberId={id}
        prefillMemberName={member.name}
        onSuccess={() => {
          void invalidateMemberLifecycle();
        }}
      />

      <MemberForm
        mode="edit"
        variant="sheet"
        open={editOpen}
        onOpenChange={setEditOpen}
        initialData={member}
        onSuccess={() => {
          setEditOpen(false);
          void invalidateMemberLifecycle();
        }}
      />
    </div>
  );
}
