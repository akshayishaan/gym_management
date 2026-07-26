import { Badge } from "@/components/ui/badge";
import { cn, formatCurrency } from "@/lib/utils";

interface BreakdownItem {
  label: string;
  value: number;
}

interface PaymentBreakdownProps {
  /** The charges / dues being settled. */
  items: BreakdownItem[];
  amountPaid: number;
  currency: string;
  /** Label for the trailing balance row. Default "Due after". */
  balanceLabel?: string;
  /** Badge text shown when the balance is fully cleared. Default "Paid in full". */
  settledLabel?: string;
  className?: string;
}

function Row({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex items-center justify-between py-1.5 text-sm">
      <span className="text-muted-foreground">{label}</span>
      <span className="font-medium">{value}</span>
    </div>
  );
}

/**
 * Shared breakdown card used by the member form and payment sheet. Stacked
 * vertically (label left, value right) — the old 3-across flex row didn't
 * fit a 375px screen with more than two items.
 */
export function PaymentBreakdown({
  items,
  amountPaid,
  currency,
  balanceLabel = "Due after",
  settledLabel = "Paid in full",
  className,
}: PaymentBreakdownProps) {
  const total = items.reduce((sum, i) => sum + i.value, 0);
  const balance = Math.max(0, total - amountPaid);

  return (
    <div className={cn("rounded-2xl border border-border/60 bg-muted/50 px-4 py-3", className)}>
      {items.map((item) => (
        <Row key={item.label} label={item.label} value={formatCurrency(item.value, currency)} />
      ))}
      <Row label="Amount paid" value={formatCurrency(amountPaid, currency)} />
      <div className="mt-1 flex items-center justify-between border-t pt-2 text-sm">
        <span className="text-muted-foreground">{balanceLabel}</span>
        {balance > 0 ? (
          <Badge variant="warning" className="font-semibold">
            {formatCurrency(balance, currency)}
          </Badge>
        ) : (
          <Badge variant="success" className="font-semibold">
            {settledLabel}
          </Badge>
        )}
      </div>
    </div>
  );
}
