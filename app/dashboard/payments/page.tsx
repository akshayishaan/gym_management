"use client";

import { useEffect, useState, useCallback } from "react";
import { useSearchParams } from "next/navigation";
import Link from "next/link";
import { toast } from "sonner";
import {
  Plus, MoreHorizontal, Trash2, Download, Wallet, X,
} from "lucide-react";
import { Button } from "@/components/ui/button";
import {
  Select, SelectContent, SelectItem, SelectTrigger, SelectValue,
} from "@/components/ui/select";
import { Card, CardContent } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import {
  Table, TableBody, TableCell, TableHead, TableHeader, TableRow,
} from "@/components/ui/table";
import {
  AlertDialog, AlertDialogAction, AlertDialogCancel, AlertDialogContent,
  AlertDialogDescription, AlertDialogFooter, AlertDialogHeader,
  AlertDialogTitle, AlertDialogTrigger,
} from "@/components/ui/alert-dialog";
import {
  DropdownMenu, DropdownMenuContent, DropdownMenuItem,
  DropdownMenuSeparator, DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { PageHeader } from "@/components/layout/PageHeader";
import { PaymentFormDialog } from "@/components/dashboard/PaymentFormDialog";
import { formatDate, formatCurrency } from "@/lib/utils";
import { useGymSettings } from "@/lib/useGymSettings";

interface Payment {
  _id: string;
  memberName: string;
  memberId: string;
  amount: number;
  method: string;
  status: string;
  invoiceNumber: string;
  paidAt: string;
  planName?: string;
}

const methodConfig: Record<string, {
  label: string;
  variant: "default" | "secondary" | "success" | "warning" | "destructive" | "outline";
}> = {
  cash:          { label: "Cash",          variant: "success" },
  card:          { label: "Card",          variant: "secondary" },
  upi:           { label: "UPI",           variant: "default" },
  bank_transfer: { label: "Bank",          variant: "warning" },
  other:         { label: "Other",         variant: "outline" },
};

function getInitials(name: string) {
  return name.split(" ").map(n => n[0]).join("").toUpperCase().slice(0, 2);
}

export default function PaymentsPage() {
  const { currency, selectedGymId } = useGymSettings();
  const [payments, setPayments] = useState<Payment[]>([]);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(true);
  const now = new Date();
  const currentMonth = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}`;
  const [month, setMonth] = useState(currentMonth);
  const [recordOpen, setRecordOpen] = useState(false);
  const searchParams = useSearchParams();
  const memberId = searchParams.get("memberId") || "";

  const fetchPayments = useCallback(async () => {
    setLoading(true);
    const params = new URLSearchParams();
    if (memberId) params.set("memberId", memberId);
    if (month) params.set("month", month);
    const res = await fetch(`/api/payments?${params}&limit=50`);
    const data = await res.json();
    setPayments(data.payments || []);
    setTotal(data.total || 0);
    setLoading(false);
  }, [memberId, month, selectedGymId]);

  useEffect(() => { fetchPayments(); }, [fetchPayments]);

  async function deletePayment(id: string) {
    const res = await fetch(`/api/payments/${id}`, { method: "DELETE" });
    if (res.ok) { toast.success("Payment deleted"); fetchPayments(); }
    else toast.error("Failed to delete payment");
  }

  const totalAmount = payments.reduce((s, p) => s + p.amount, 0);

  return (
    <div className="space-y-6">
      <PageHeader
        title="Payments"
        description={`${total} record${total !== 1 ? "s" : ""} · Total: ${formatCurrency(totalAmount, currency)}`}
        actions={
          <Button className="gap-2" onClick={() => setRecordOpen(true)}>
            <Plus className="h-4 w-4" /> Record Payment
          </Button>
        }
      />

      <PaymentFormDialog
        open={recordOpen}
        onOpenChange={setRecordOpen}
        onSuccess={fetchPayments}
      />

      {/* ── Filter ──────────────────────────────────────────────────────── */}
      <Card className="border-0 shadow-card">
        <CardContent className="p-4">
          <div className="flex items-center gap-2">
            <Select
              value={month ? month.split("-")[1] : ""}
              onValueChange={m => {
                const y = month ? month.split("-")[0] : String(new Date().getFullYear());
                setMonth(m ? `${y}-${m}` : "");
              }}
            >
              <SelectTrigger className="w-36 h-10">
                <SelectValue placeholder="All months" />
              </SelectTrigger>
              <SelectContent>
                {[
                  "01","02","03","04","05","06",
                  "07","08","09","10","11","12",
                ].map((m, i) => (
                  <SelectItem key={m} value={m}>
                    {new Date(2000, i).toLocaleString("default", { month: "long" })}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>

            <Select
              value={month ? month.split("-")[0] : ""}
              onValueChange={y => {
                const m = month ? month.split("-")[1] : "";
                setMonth(y && m ? `${y}-${m}` : "");
              }}
            >
              <SelectTrigger className="w-28 h-10">
                <SelectValue placeholder="Year" />
              </SelectTrigger>
              <SelectContent>
                {Array.from({ length: 5 }, (_, i) => String(new Date().getFullYear() - i)).map(y => (
                  <SelectItem key={y} value={y}>{y}</SelectItem>
                ))}
              </SelectContent>
            </Select>

            {month && (
              <Button variant="ghost" size="icon" className="h-10 w-10 shrink-0" onClick={() => setMonth("")}>
                <X className="h-4 w-4" />
              </Button>
            )}
          </div>
        </CardContent>
      </Card>

      {/* ── Table ───────────────────────────────────────────────────────── */}
      <Card className="border-0 shadow-card overflow-hidden">
        <CardContent className="p-0">
          <div className="overflow-x-auto">
            <Table>
              <TableHeader>
                <TableRow className="hover:bg-transparent">
                  <TableHead>Member</TableHead>
                  <TableHead>Invoice</TableHead>
                  <TableHead>Plan</TableHead>
                  <TableHead>Amount</TableHead>
                  <TableHead>Method</TableHead>
                  <TableHead>Date</TableHead>
                  <TableHead className="text-right w-16">Actions</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {loading ? (
                  [...Array(5)].map((_, i) => (
                    <TableRow key={i}>
                      <TableCell>
                        <div className="flex items-center gap-3">
                          <div className="h-8 w-8 rounded-full bg-muted animate-pulse" />
                          <div className="h-4 w-24 bg-muted rounded animate-pulse" />
                        </div>
                      </TableCell>
                      {[...Array(5)].map((_, j) => (
                        <TableCell key={j}>
                          <div className="h-4 bg-muted rounded animate-pulse" style={{ width: `${60 + j * 10}px` }} />
                        </TableCell>
                      ))}
                      <TableCell>
                        <div className="h-8 w-8 bg-muted rounded animate-pulse ml-auto" />
                      </TableCell>
                    </TableRow>
                  ))
                ) : payments.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={7} className="text-center py-12">
                      <div className="flex flex-col items-center gap-3">
                        <div className="w-12 h-12 rounded-full bg-muted flex items-center justify-center">
                          <Wallet className="h-6 w-6 text-muted-foreground" />
                        </div>
                        <div>
                          <p className="text-sm font-medium">No payments found</p>
                          <p className="text-xs text-muted-foreground mt-1">
                            {month ? "No payments in this month" : "Record a payment to get started"}
                          </p>
                        </div>
                      </div>
                    </TableCell>
                  </TableRow>
                ) : (
                  payments.map(p => {
                    const method = methodConfig[p.method] || methodConfig.other;
                    return (
                      <TableRow key={p._id} className="group hover:bg-muted/40 transition-colors">
                        <TableCell>
                          <div className="flex items-center gap-3">
                            <Avatar className="h-8 w-8 shrink-0">
                              <AvatarFallback className="bg-primary/10 text-primary text-xs font-semibold">
                                {getInitials(p.memberName)}
                              </AvatarFallback>
                            </Avatar>
                            <Link
                              href={`/dashboard/members/${p.memberId}`}
                              className="font-medium text-sm hover:underline"
                            >
                              {p.memberName}
                            </Link>
                          </div>
                        </TableCell>
                        <TableCell className="font-mono text-xs text-muted-foreground">
                          {p.invoiceNumber}
                        </TableCell>
                        <TableCell className="text-sm text-muted-foreground">
                          {p.planName || "—"}
                        </TableCell>
                        <TableCell className="font-semibold text-sm text-success font-mono">
                          {formatCurrency(p.amount, currency)}
                        </TableCell>
                        <TableCell>
                          <Badge variant={method.variant} className="text-xs">
                            {method.label}
                          </Badge>
                        </TableCell>
                        <TableCell className="text-sm text-muted-foreground">
                          {formatDate(p.paidAt)}
                        </TableCell>
                        <TableCell className="text-right">
                          <DropdownMenu modal={false}>
                            <DropdownMenuTrigger asChild>
                              <Button
                                size="icon"
                                variant="ghost"
                                className="h-8 w-8 opacity-0 group-hover:opacity-100 transition-opacity"
                              >
                                <MoreHorizontal className="h-4 w-4" />
                              </Button>
                            </DropdownMenuTrigger>
                            <DropdownMenuContent align="end" className="w-44">
                              <DropdownMenuItem asChild>
                                <Link href={`/dashboard/payments/${p._id}/invoice`}>
                                  <Download className="h-4 w-4 mr-2" />
                                  View Invoice
                                </Link>
                              </DropdownMenuItem>
                              <DropdownMenuSeparator />
                              <AlertDialog>
                                <AlertDialogTrigger asChild>
                                  <DropdownMenuItem
                                    className="text-destructive focus:text-destructive focus:bg-destructive/10"
                                    onSelect={e => e.preventDefault()}
                                  >
                                    <Trash2 className="h-4 w-4 mr-2" />
                                    Delete
                                  </DropdownMenuItem>
                                </AlertDialogTrigger>
                                <AlertDialogContent>
                                  <AlertDialogHeader>
                                    <AlertDialogTitle>Delete Payment</AlertDialogTitle>
                                    <AlertDialogDescription>
                                      Delete <strong>{p.invoiceNumber}</strong>? This cannot be undone.
                                    </AlertDialogDescription>
                                  </AlertDialogHeader>
                                  <AlertDialogFooter>
                                    <AlertDialogCancel>Cancel</AlertDialogCancel>
                                    <AlertDialogAction
                                      className="bg-destructive hover:bg-destructive/90"
                                      onClick={() => deletePayment(p._id)}
                                    >
                                      Delete
                                    </AlertDialogAction>
                                  </AlertDialogFooter>
                                </AlertDialogContent>
                              </AlertDialog>
                            </DropdownMenuContent>
                          </DropdownMenu>
                        </TableCell>
                      </TableRow>
                    );
                  })
                )}
              </TableBody>
            </Table>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
