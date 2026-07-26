"use client";

import Link from "next/link";
import { Ban, Download, MoreHorizontal, RotateCcw, Undo2 } from "lucide-react";
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
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
import { formatDate, formatCurrency } from "@/lib/utils";
import { useGymSettings } from "@/lib/useGymSettings";
import type { PaymentListItem } from "@/lib/hooks/usePayments";
import { cn } from "@/lib/utils";

const methodConfig: Record<string, {
  label: string;
  variant: "default" | "secondary" | "success" | "warning" | "destructive" | "outline";
}> = {
  cash: { label: "Cash", variant: "success" },
  card: { label: "Card", variant: "secondary" },
  upi: { label: "UPI", variant: "default" },
  bank_transfer: { label: "Bank", variant: "warning" },
  other: { label: "Other", variant: "outline" },
};

function getInitials(name: string) {
  return name.split(" ").map((part) => part[0]).join("").toUpperCase().slice(0, 2);
}

interface PaymentCardProps {
  payment: PaymentListItem;
  onVoid: (id: string) => void;
  onRefund: (id: string) => void;
  onReversePurchase: (membershipId: string) => void;
}

export function PaymentCard({
  payment,
  onVoid,
  onRefund,
  onReversePurchase,
}: PaymentCardProps) {
  const { currency } = useGymSettings();
  const method = methodConfig[payment.method] || methodConfig.other;
  const isPaid = payment.status === "paid";
  const canReversePurchase = isPaid
    && payment.kind === "plan_purchase"
    && payment.membershipId
    && payment.membershipStatus !== "reversed";

  return (
    <div className={cn("app-surface rounded-[1.6rem] p-4", !isPaid && "bg-muted/35")}>
      <div className="flex items-center gap-3">
        <Link
          href={`/dashboard/members/${payment.memberId}`}
          className="flex min-w-0 flex-1 items-center gap-3 active:opacity-70"
        >
          <Avatar className="h-12 w-12 shrink-0 ring-4 ring-success/5">
            <AvatarFallback className="bg-success/10 text-sm font-extrabold text-success">
              {getInitials(payment.memberName)}
            </AvatarFallback>
          </Avatar>
          <div className="min-w-0 flex-1">
            <div className="flex flex-wrap items-center gap-1.5">
              <p className="truncate text-[15px] font-bold">{payment.memberName}</p>
              {payment.status === "voided" && <Badge variant="secondary">Voided</Badge>}
              {payment.status === "refunded" && <Badge variant="warning">Refunded</Badge>}
            </div>
            <p className="mt-0.5 truncate text-xs font-medium text-muted-foreground">
              {payment.planName || "Dues payment"}
            </p>
          </div>
        </Link>

        <span className={cn(
          "shrink-0 font-display text-base font-extrabold",
          isPaid ? "text-success" : "text-muted-foreground line-through"
        )}>
          {formatCurrency(payment.amount, currency)}
        </span>
      </div>

      <div className="mt-3 flex items-center justify-between gap-3 border-t border-border/60 pt-3">
        <div className="min-w-0 truncate text-xs font-medium text-muted-foreground">
          {payment.invoiceNumber} · {formatDate(payment.paidAt)}
        </div>
        <div className="flex shrink-0 items-center gap-1">
          <Badge variant={method.variant}>{method.label}</Badge>
          <DropdownMenu>
            <DropdownMenuTrigger asChild>
              <Button size="icon" variant="ghost" className="h-9 w-9 rounded-xl">
                <MoreHorizontal className="h-3.5 w-3.5" />
              </Button>
            </DropdownMenuTrigger>
            <DropdownMenuContent align="end" className="w-52">
              <DropdownMenuItem asChild>
                <Link href={`/dashboard/payments/${payment._id}/invoice`}>
                  <Download className="mr-2 h-4 w-4" />
                  View invoice
                </Link>
              </DropdownMenuItem>
              {isPaid && <DropdownMenuSeparator />}
              {isPaid && (
                <AlertDialog>
                  <AlertDialogTrigger asChild>
                    <DropdownMenuItem onSelect={(event) => event.preventDefault()}>
                      <Ban className="mr-2 h-4 w-4" />
                      Void payment
                    </DropdownMenuItem>
                  </AlertDialogTrigger>
                  <AlertDialogContent>
                    <AlertDialogHeader>
                      <AlertDialogTitle>Void this payment?</AlertDialogTitle>
                      <AlertDialogDescription>
                        The invoice remains in the audit history. {payment.kind === "plan_purchase"
                          ? "Membership access stays active and the amount becomes due."
                          : "The amount returns to outstanding dues."}
                      </AlertDialogDescription>
                    </AlertDialogHeader>
                    <AlertDialogFooter>
                      <AlertDialogCancel>Keep payment</AlertDialogCancel>
                      <AlertDialogAction onClick={() => onVoid(payment._id)}>Void payment</AlertDialogAction>
                    </AlertDialogFooter>
                  </AlertDialogContent>
                </AlertDialog>
              )}
              {isPaid && (
                <AlertDialog>
                  <AlertDialogTrigger asChild>
                    <DropdownMenuItem onSelect={(event) => event.preventDefault()}>
                      <RotateCcw className="mr-2 h-4 w-4" />
                      Refund payment
                    </DropdownMenuItem>
                  </AlertDialogTrigger>
                  <AlertDialogContent>
                    <AlertDialogHeader>
                      <AlertDialogTitle>Refund this payment?</AlertDialogTitle>
                      <AlertDialogDescription>
                        Record a full refund of {formatCurrency(payment.amount, currency)}. Membership access remains unchanged and the amount becomes due again.
                      </AlertDialogDescription>
                    </AlertDialogHeader>
                    <AlertDialogFooter>
                      <AlertDialogCancel>Cancel</AlertDialogCancel>
                      <AlertDialogAction onClick={() => onRefund(payment._id)}>Record refund</AlertDialogAction>
                    </AlertDialogFooter>
                  </AlertDialogContent>
                </AlertDialog>
              )}
              {canReversePurchase && (
                <AlertDialog>
                  <AlertDialogTrigger asChild>
                    <DropdownMenuItem
                      className="text-destructive focus:bg-destructive/10 focus:text-destructive"
                      onSelect={(event) => event.preventDefault()}
                    >
                      <Undo2 className="mr-2 h-4 w-4" />
                      Reverse plan purchase
                    </DropdownMenuItem>
                  </AlertDialogTrigger>
                  <AlertDialogContent>
                    <AlertDialogHeader>
                      <AlertDialogTitle>Reverse this Plan purchase?</AlertDialogTitle>
                      <AlertDialogDescription>
                        The Membership period will be reversed and this Payment will be voided. Newer Membership transactions must be reversed first.
                      </AlertDialogDescription>
                    </AlertDialogHeader>
                    <AlertDialogFooter>
                      <AlertDialogCancel>Cancel</AlertDialogCancel>
                      <AlertDialogAction
                        className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
                        onClick={() => onReversePurchase(payment.membershipId!)}
                      >
                        Reverse purchase
                      </AlertDialogAction>
                    </AlertDialogFooter>
                  </AlertDialogContent>
                </AlertDialog>
              )}
            </DropdownMenuContent>
          </DropdownMenu>
        </div>
      </div>
    </div>
  );
}
