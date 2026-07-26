"use client";

import Link from "next/link";
import { UserPlus, CreditCard, BellRing, ChartNoAxesCombined } from "lucide-react";
import { cn } from "@/lib/utils";

const LINK_ACTIONS = [
  {
    label: "Record Payment",
    href: "/dashboard/payments",
    icon: CreditCard,
    iconClass: "bg-success/10 text-success",
  },
  {
    label: "Send Reminders",
    href: "/dashboard/members?status=expiring",
    icon: BellRing,
    iconClass: "bg-warning/10 text-warning",
  },
  {
    label: "Reports",
    href: "/dashboard/reports",
    icon: ChartNoAxesCombined,
    iconClass: "bg-accent text-accent-foreground",
  },
] as const;

const tileClass = "flex min-w-0 flex-1 flex-col items-center gap-2.5 text-center active:scale-95";

interface QuickActionsProps {
  /** Opens the Add Member bottom sheet instead of navigating to a route. */
  onAddMember: () => void;
}

export function QuickActions({ onAddMember }: QuickActionsProps) {
  return (
    <div className="app-surface flex items-start justify-between rounded-[1.75rem] px-3 py-4">
      <button type="button" onClick={onAddMember} className={tileClass}>
        <span className="flex h-12 w-12 items-center justify-center rounded-[1.1rem] bg-primary text-primary-foreground shadow-md shadow-primary/20">
          <UserPlus className="h-5 w-5" />
        </span>
        <span className="text-[11px] font-bold leading-tight">Add</span>
      </button>

      {LINK_ACTIONS.map((action) => (
        <Link key={action.label} href={action.href} className={tileClass}>
          <span className={cn("flex h-12 w-12 items-center justify-center rounded-[1.1rem]", action.iconClass)}>
            <action.icon className="h-5 w-5" />
          </span>
          <span className="line-clamp-1 text-[11px] font-bold leading-tight">
            {action.label === "Record Payment" ? "Payment" : action.label === "Send Reminders" ? "Remind" : action.label}
          </span>
        </Link>
      ))}
    </div>
  );
}
