"use client";

import { useTheme } from "next-themes";
import { useEffect, useState } from "react";
import { Moon, Sun } from "lucide-react";
import { SidebarMenuButton, SidebarMenuItem, SidebarMenu } from "@/components/ui/sidebar";

export function ThemeToggle() {
  const { theme, setTheme, resolvedTheme } = useTheme();
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
  }, []);

  if (!mounted) {
    return (
      <SidebarMenu>
        <SidebarMenuItem>
          <SidebarMenuButton disabled tooltip="Theme">
            <div className="h-4 w-4 rounded-full bg-muted animate-pulse" />
            <span className="h-4 w-16 bg-muted rounded animate-pulse" />
          </SidebarMenuButton>
        </SidebarMenuItem>
      </SidebarMenu>
    );
  }

  const isDark = resolvedTheme === "dark";

  return (
    <SidebarMenu>
      <SidebarMenuItem>
        <SidebarMenuButton
          tooltip={isDark ? "Light Mode" : "Dark Mode"}
          className="text-muted-foreground hover:text-foreground"
          onClick={() => setTheme(isDark ? "light" : "dark")}
        >
          {isDark ? (
            <Sun className="h-4 w-4 shrink-0 text-amber-500" />
          ) : (
            <Moon className="h-4 w-4 shrink-0 text-indigo-500" />
          )}
          <span className="text-sm font-medium">
            {isDark ? "Light Mode" : "Dark Mode"}
          </span>
        </SidebarMenuButton>
      </SidebarMenuItem>
    </SidebarMenu>
  );
}
