"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { House, UsersRound, ReceiptText, LayoutGrid } from "lucide-react";
import { cn } from "@/lib/utils";

const TABS = [
  { href: "/dashboard", label: "Home", icon: House },
  { href: "/dashboard/members", label: "Members", icon: UsersRound },
  { href: "/dashboard/payments", label: "Payments", icon: ReceiptText },
  { href: "/dashboard/more", label: "More", icon: LayoutGrid },
] as const;

export function BottomTabBar() {
  const pathname = usePathname();

  return (
    <nav
      aria-label="Primary navigation"
      className="fixed inset-x-3 z-40 mx-auto flex h-[4.35rem] max-w-[27rem] items-center rounded-[1.6rem] border border-primary-foreground/10 bg-[hsl(var(--dock))]/95 px-1.5 text-[hsl(var(--dock-foreground))] shadow-2xl shadow-foreground/20 backdrop-blur-xl"
      style={{ bottom: "calc(0.5rem + env(safe-area-inset-bottom))" }}
    >
      {TABS.map((tab) => {
        const active = pathname === tab.href;
        return (
          <Link
            key={tab.href}
            href={tab.href}
            className="flex h-[3.5rem] flex-1 flex-col items-center justify-center gap-1 rounded-[1.15rem] transition-all duration-200 active:scale-95"
          >
            <tab.icon
              className={cn("h-5 w-5", active ? "text-primary" : "text-[hsl(var(--dock-foreground))]/55")}
              strokeWidth={active ? 2.5 : 2}
            />
            <span
              className={cn(
                "text-[10px] font-bold tracking-tight",
                active ? "text-primary" : "text-[hsl(var(--dock-foreground))]/55"
              )}
            >
              {tab.label}
            </span>
          </Link>
        );
      })}
    </nav>
  );
}
