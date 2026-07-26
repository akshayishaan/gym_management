"use client";

import { useSession, signOut } from "next-auth/react";
import { LogOut, Mail, User } from "lucide-react";
import { StackHeader } from "@/components/layout/StackHeader";
import { ThemeToggle } from "@/components/layout/ThemeToggle";

export default function SettingsPage() {
  const { data: session } = useSession();

  return (
    <div className="app-canvas flex min-h-svh flex-col">
      <StackHeader title="Settings" />
      <div
        className="app-screen flex-1 space-y-7 px-5 py-5"
        style={{ paddingBottom: "calc(1rem + env(safe-area-inset-bottom))" }}
      >
        <section className="relative overflow-hidden rounded-[2rem] bg-foreground p-5 text-background shadow-xl shadow-foreground/15">
          <div className="absolute -right-12 -top-12 h-32 w-32 rounded-full bg-primary/50 blur-2xl" />
          <div className="relative flex items-center gap-4">
            <div className="flex h-14 w-14 items-center justify-center rounded-[1.25rem] bg-background/10">
              <User className="h-6 w-6 text-primary" />
            </div>
            <div className="min-w-0 flex-1">
              <p className="text-[10px] font-bold uppercase tracking-[0.16em] text-background/50">Signed in as</p>
              <p className="mt-1 truncate font-display text-lg font-bold">{session?.user?.name}</p>
              <p className="truncate text-xs text-background/55">{session?.user?.email}</p>
            </div>
          </div>
        </section>

        <section className="space-y-3">
          <p className="app-section-label px-1">Account details</p>
          <div className="app-surface divide-y divide-border/60 overflow-hidden rounded-[1.6rem]">
            <div className="flex items-center gap-3 px-4 py-4">
              <span className="flex h-10 w-10 items-center justify-center rounded-2xl bg-primary/10 text-primary"><User className="h-4 w-4" /></span>
              <div className="min-w-0 flex-1">
                <p className="text-xs font-medium text-muted-foreground">Name</p>
                <p className="truncate text-sm font-bold">{session?.user?.name}</p>
              </div>
            </div>
            <div className="flex items-center gap-3 px-4 py-4">
              <span className="flex h-10 w-10 items-center justify-center rounded-2xl bg-accent text-accent-foreground"><Mail className="h-4 w-4" /></span>
              <div className="min-w-0 flex-1">
                <p className="text-xs font-medium text-muted-foreground">Email</p>
                <p className="truncate text-sm font-bold">{session?.user?.email}</p>
              </div>
            </div>
          </div>
        </section>

        <section className="space-y-3">
          <p className="app-section-label px-1">Preferences</p>
          <div className="app-surface overflow-hidden rounded-[1.6rem]">
            <ThemeToggle />
          </div>
        </section>

        <button
          type="button"
          onClick={() => signOut({ callbackUrl: "/login" })}
          className="flex h-12 w-full items-center justify-center gap-2 rounded-2xl bg-destructive/10 text-sm font-bold text-destructive transition-all active:scale-[0.98]"
        >
          <LogOut className="h-4 w-4" /> Sign Out
        </button>
      </div>
    </div>
  );
}
