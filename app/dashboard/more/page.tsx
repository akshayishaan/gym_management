"use client";

import Link from "next/link";
import { useSession, signOut } from "next-auth/react";
import {
  Dumbbell,
  BarChart3,
  ClipboardList,
  Building2,
  Settings as SettingsIcon,
  LogOut,
  ChevronRight,
} from "lucide-react";

const MENU_ITEMS = [
  { href: "/dashboard/plans", label: "Plans", description: "Pricing & access", icon: Dumbbell, tone: "bg-primary/10 text-primary" },
  { href: "/dashboard/reports", label: "Reports", description: "Growth & revenue", icon: BarChart3, tone: "bg-success/10 text-success" },
  { href: "/dashboard/activity", label: "Activity", description: "Team timeline", icon: ClipboardList, tone: "bg-warning/15 text-warning-foreground dark:text-warning" },
  { href: "/dashboard/gyms", label: "My Gyms", description: "Locations", icon: Building2, tone: "bg-accent text-accent-foreground" },
  { href: "/dashboard/settings", label: "Settings", description: "Account & theme", icon: SettingsIcon, tone: "bg-muted text-muted-foreground" },
] as const;

function getInitials(name?: string | null) {
  if (!name) return "U";
  return name.split(" ").map((n) => n[0]).join("").toUpperCase().slice(0, 2);
}

export default function MorePage() {
  const { data: session } = useSession();

  return (
    <div className="space-y-6">
      <div className="relative overflow-hidden rounded-[2rem] bg-foreground p-5 text-background shadow-xl shadow-foreground/15">
        <div className="absolute -right-8 -top-12 h-32 w-32 rounded-full bg-primary/50 blur-2xl" />
        <div className="relative flex items-center gap-4">
        <div className="flex h-14 w-14 shrink-0 items-center justify-center rounded-[1.25rem] bg-background/10 text-base font-extrabold ring-1 ring-background/10">
          {getInitials(session?.user?.name)}
        </div>
        <div className="min-w-0 flex-1">
          <p className="text-[10px] font-bold uppercase tracking-[0.16em] text-background/50">Workspace owner</p>
          <p className="mt-1 truncate font-display text-xl font-bold">{session?.user?.name}</p>
          <p className="truncate text-xs text-background/55">{session?.user?.email}</p>
        </div>
        </div>
      </div>

      <section className="space-y-3">
        <p className="app-section-label px-1">Manage</p>
      <div className="grid grid-cols-2 gap-3">
        {MENU_ITEMS.map((item) => (
          <Link
            key={item.href}
            href={item.href}
            className="app-surface group min-h-32 rounded-[1.6rem] p-4 transition-all active:scale-[0.97] first:col-span-2 first:min-h-28"
          >
            <span className="flex items-start justify-between gap-2">
            <span className={`flex h-11 w-11 shrink-0 items-center justify-center rounded-2xl ${item.tone}`}>
              <item.icon className="h-5 w-5" />
            </span>
            <ChevronRight className="mt-1 h-4 w-4 text-muted-foreground/50" />
            </span>
            <span className="mt-4 block text-sm font-bold">{item.label}</span>
            <span className="mt-0.5 block text-xs text-muted-foreground">{item.description}</span>
          </Link>
        ))}
      </div>
      </section>

      <button
        type="button"
        onClick={() => signOut({ callbackUrl: "/login" })}
        className="flex h-12 w-full items-center justify-center gap-2 rounded-2xl bg-destructive/10 text-sm font-bold text-destructive transition-all active:scale-[0.98]"
      >
        <LogOut className="h-4 w-4" />
        Sign Out
      </button>
    </div>
  );
}
