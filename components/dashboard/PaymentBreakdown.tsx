import { Badge } from "@/components/ui/badge";
import { cn, formatCurrency } from "@/lib/utils";

interface BreakdownItem {
  label: string;
  value: number;
}

interface PaymentBreakdownProps {
  /** The charges / dues being settled, rendered as centered columns. */
  items: BreakdownItem[];
  amountPaid: number;
  currency: string;
  /** Label for the trailing balance cell. Default "Due after". */
  balanceLabel?: string;
  /** Badge text shown when the balance is fully cleared. Default "Paid in full". */
  settledLabel?: string;
  className?: string;
}

function Cell({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex-1 space-y-0.5 text-center">
      <p className="text-muted-foreground text-xs">{label}</p>
      <p className="font-medium">{value}</p>
    </div>
  );
}

/**
 * Shared breakdown card used by the add-member and record-payment dialogs.
 * Renders a row of "owed" items, the amount paid, and the resulting balance
 * (warning badge when money is still owed, success badge when settled).
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
    <div
      className={cn(
        "rounded-lg bg-muted/50 border px-4 py-3 flex items-center gap-3 text-sm",
        className
      )}
    >
      {items.map((item) => (
        <Cell
          key={item.label}
          label={item.label}
          value={formatCurrency(item.value, currency)}
        />
      ))}
      <Cell label="Amount paid" value={formatCurrency(amountPaid, currency)} />
      <div className="flex-1 space-y-0.5 text-center">
        <p className="text-muted-foreground text-xs">{balanceLabel}</p>
        {balance > 0 ? (
          <Badge variant="warning" className="font-semibold">
            {formatCurrency(balance, currency)}
          </Badge>
        ) : (
          <Badge variant="success" className="font-semibold">{settledLabel}</Badge>
        )}
      </div>
    </div>
  );
}
