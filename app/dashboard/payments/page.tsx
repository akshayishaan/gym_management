"use client";

import { useEffect, useState, useCallback } from "react";
import { useSearchParams } from "next/navigation";
import Link from "next/link";
import { toast } from "sonner";
import { motion } from "framer-motion";
import {
  Plus,
  Search,
  Download,
  MoreHorizontal,
  Trash2,
  Eye,
  Wallet,
} from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Card, CardContent } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
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
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { PageHeader } from "@/components/layout/PageHeader";
import { formatDate, formatCurrency } from "@/lib/utils";

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

const methodConfig: Record<
  string,
  { label: string; variant: "default" | "secondary" | "success" | "warning" | "destructive" | "outline" }
> = {
  cash: { label: "Cash", variant: "success" },
  card: { label: "Card", variant: "secondary" },
  upi: { label: "UPI", variant: "default" },
  bank_transfer: { label: "Bank", variant: "warning" },
  other: { label: "Other", variant: "outline" },
};

function getInitials(name: string) {
  return name
    .split(" ")
    .map((n) => n[0])
    .join("")
    .toUpperCase()
    .slice(0, 2);
}

export default function PaymentsPage() {
  const [payments, setPayments] = useState<Payment[]>([]);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(true);
  const [month, setMonth] = useState("");
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
  }, [memberId, month]);

  useEffect(() => {
    fetchPayments();
  }, [fetchPayments]);

  async function deletePayment(id: string) {
    const res = await fetch(`/api/payments/${id}`, { method: "DELETE" });
    if (res.ok) {
      toast.success("Payment deleted");
      fetchPayments();
    } else toast.error("Failed to delete payment");
  }

  const totalAmount = payments.reduce((s, p) => s + p.amount, 0);

  return (
    <div className="space-y-6">
      <PageHeader
        title="Payments"
        description={`${total} records · Total: ${formatCurrency(totalAmount)}`}
        actions={
          <Link href="/dashboard/payments/new">
            <Button className="gap-2">
              <Plus className="h-4 w-4" />
              Record Payment
            </Button>
          </Link>
        }
      />

      <Card className="border-0 shadow-card">
        <CardContent className="pt-4 pb-4">
          <div className="flex gap-3 flex-wrap">
            <div className="relative flex-1 min-w-48">
              <Search className="absolute left-3 top-2.5 h-4 w-4 text-muted-foreground" />
              <Input
                placeholder="Filter by month (YYYY-MM)"
                className="pl-9 h-10"
                value={month}
                onChange={(e) => setMonth(e.target.value)}
              />
            </div>
          </div>
        </CardContent>
      </Card>

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
                          <div className="h-9 w-9 rounded-full bg-muted animate-pulse" />
                          <div className="h-4 w-24 bg-muted rounded animate-pulse" />
                        </div>
                      </TableCell>
                      <TableCell>
                        <div className="h-4 w-20 bg-muted rounded animate-pulse" />
                      </TableCell>
                      <TableCell>
                        <div className="h-4 w-20 bg-muted rounded animate-pulse" />
                      </TableCell>
                      <TableCell>
                        <div className="h-4 w-16 bg-muted rounded animate-pulse" />
                      </TableCell>
                      <TableCell>
                        <div className="h-5 w-14 bg-muted rounded-full animate-pulse" />
                      </TableCell>
                      <TableCell>
                        <div className="h-4 w-24 bg-muted rounded animate-pulse" />
                      </TableCell>
                      <TableCell>
                        <div className="h-8 w-8 bg-muted rounded animate-pulse ml-auto" />
                      </TableCell>
                    </TableRow>
                  ))
                ) : payments.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={7} className="text-center py-12">
                      <div className="flex flex-col items-center gap-3">
                        <div className="inline-flex items-center justify-center w-12 h-12 rounded-full bg-muted text-muted-foreground">
                          <Wallet className="h-6 w-6" />
                        </div>
                        <div>
                          <p className="text-sm font-medium text-muted-foreground">
                            No payments found
                          </p>
                          <p className="text-xs text-muted-foreground mt-1">
                            Record a payment to get started
                          </p>
                        </div>
                      </div>
                    </TableCell>
                  </TableRow>
                ) : (
                  payments.map((p) => {
                    const method = methodConfig[p.method] || methodConfig.other;
                    return (
                      <TableRow
                        key={p._id}
                        className="group hover:bg-muted/40 transition-colors"
                      >
                        <TableCell>
                          <div className="flex items-center gap-3">
                            <Avatar className="h-9 w-9 border-2 border-background shadow-sm">
                              <AvatarFallback className="bg-emerald-100 text-emerald-700 text-xs font-bold">
                                {getInitials(p.memberName)}
                              </AvatarFallback>
                            </Avatar>
                            <Link
                              href={`/dashboard/members/${p.memberId}`}
                              className="font-medium text-sm hover:underline"
                              onClick={(e) => e.stopPropagation()}
                            >
                              {p.memberName}
                            </Link>
                          </div>
                        </TableCell>
                        <TableCell className="font-mono text-xs text-muted-foreground">
                          {p.invoiceNumber}
                        </TableCell>
                        <TableCell className="text-sm">
                          {p.planName || "—"}
                        </TableCell>
                        <TableCell className="font-semibold text-sm text-emerald-600 font-mono">
                          {formatCurrency(p.amount)}
                        </TableCell>
                        <TableCell>
                          <Badge variant={method.variant} className="capitalize text-xs">
                            {method.label}
                          </Badge>
                        </TableCell>
                        <TableCell className="text-sm text-muted-foreground">
                          {formatDate(p.paidAt)}
                        </TableCell>
                        <TableCell className="text-right">
                          <DropdownMenu>
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
                                    onSelect={(e) => e.preventDefault()}
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
