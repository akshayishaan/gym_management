"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { signOut, useSession } from "next-auth/react";
import {
  LayoutDashboard,
  Users,
  CreditCard,
  BarChart3,
  Settings,
  ClipboardList,
  Dumbbell,
  LogOut,
  UserCog,
  Building2,
} from "lucide-react";
import { cn } from "@/lib/utils";
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import { ThemeToggle } from "@/components/layout/ThemeToggle";
import { GymSwitcher } from "@/components/layout/GymSwitcher";

import {
  Sidebar,
  SidebarContent,
  SidebarFooter,
  SidebarGroup,
  SidebarGroupContent,
  SidebarGroupLabel,
  SidebarHeader,
  SidebarMenu,
  SidebarMenuButton,
  SidebarMenuItem,
  SidebarRail,
} from "@/components/ui/sidebar";

const gymNavItems = [
  { href: "/dashboard", label: "Dashboard", icon: LayoutDashboard },
  { href: "/dashboard/gyms", label: "My Gyms", icon: Building2 },
  { href: "/dashboard/members", label: "Members", icon: Users },
  { href: "/dashboard/plans", label: "Plans", icon: Dumbbell },
  { href: "/dashboard/payments", label: "Payments", icon: CreditCard },
  { href: "/dashboard/reports", label: "Reports", icon: BarChart3 },
  { href: "/dashboard/staff", label: "Staff", icon: UserCog, adminOnly: true },
  { href: "/dashboard/activity", label: "Activity Log", icon: ClipboardList, adminOnly: true },
  { href: "/dashboard/settings", label: "Settings", icon: Settings, adminOnly: true },
];

const superadminNavItems = [
  { href: "/dashboard/superadmin", label: "Overview", icon: LayoutDashboard },
  { href: "/dashboard/superadmin/gyms", label: "Gyms", icon: Building2 },
  { href: "/dashboard/activity", label: "Activity Log", icon: ClipboardList },
];

export function AppSidebar() {
  const pathname = usePathname();
  const { data: session } = useSession();
  const role = (session?.user as { role?: string })?.role;
  const isSuperAdmin = role === "superadmin";
  const navItems = isSuperAdmin ? superadminNavItems : gymNavItems;

  const userInitials = session?.user?.name
    ?.split(" ")
    .map((n) => n[0])
    .join("")
    .toUpperCase()
    .slice(0, 2) || "U";

  return (
    <Sidebar collapsible="icon" className="border-r">
      {/* Header: Gym Switcher (sticky) */}
      <SidebarHeader className="border-b p-2">
        <GymSwitcher />
      </SidebarHeader>

      {/* Nav: Scrollable */}
      <SidebarContent>
        <SidebarGroup>
          <SidebarGroupLabel>Navigation</SidebarGroupLabel>
          <SidebarGroupContent>
            <SidebarMenu>
              {navItems.map((item) => {
                if ("adminOnly" in item && item.adminOnly && role !== "admin") return null;

                const active =
                  pathname === item.href ||
                  (item.href !== "/dashboard" &&
                    item.href !== "/dashboard/superadmin" &&
                    pathname.startsWith(item.href));

                return (
                  <SidebarMenuItem key={item.href}>
                    <SidebarMenuButton
                      asChild
                      isActive={active}
                      tooltip={item.label}
                    >
                      <Link href={item.href}>
                        <div
                          className={cn(
                            "p-1 rounded-lg transition-colors",
                            active
                              ? "bg-primary text-primary-foreground"
                              : "bg-transparent"
                          )}
                        >
                          <item.icon className="h-4 w-4 shrink-0" />
                        </div>
                        <span>{item.label}</span>
                        {active && (
                          <span className="ml-auto w-1.5 h-1.5 rounded-full bg-primary" />
                        )}
                      </Link>
                    </SidebarMenuButton>
                  </SidebarMenuItem>
                );
              })}
            </SidebarMenu>
          </SidebarGroupContent>
        </SidebarGroup>
      </SidebarContent>

      {/* Footer: User info, theme toggle, logout (sticky) */}
      <SidebarFooter className="border-t p-2 space-y-1">
        <div className="flex items-center gap-3 px-2 py-1 group-data-[collapsible=icon]:justify-center group-data-[collapsible=icon]:px-0">
          <Avatar className="h-8 w-8 border-2 border-primary/20 shrink-0">
            <AvatarFallback className="bg-primary/10 text-primary text-xs font-bold">
              {userInitials}
            </AvatarFallback>
          </Avatar>
          <div className="min-w-0 flex-1 group-data-[collapsible=icon]:hidden">
            <p className="text-sm font-medium truncate">{session?.user?.name}</p>
            <p className="text-xs text-muted-foreground capitalize">{role}</p>
          </div>
        </div>
        <ThemeToggle />
        <SidebarMenu>
          <SidebarMenuItem>
            <SidebarMenuButton
              tooltip="Sign Out"
              className="text-muted-foreground hover:text-destructive hover:bg-destructive/10"
              onClick={() => signOut({ callbackUrl: "/login" })}
            >
              <LogOut className="h-4 w-4" />
              <span>Sign Out</span>
            </SidebarMenuButton>
          </SidebarMenuItem>
        </SidebarMenu>
      </SidebarFooter>

      {/* Rail for resize (optional) */}
      <SidebarRail />
    </Sidebar>
  );
}
