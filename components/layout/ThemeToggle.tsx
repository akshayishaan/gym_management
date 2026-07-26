"use client";

import { useTheme } from "next-themes";
import { useEffect, useState } from "react";
import { Moon, Sun } from "lucide-react";

/**
 * Standalone theme toggle row for the Settings/More screen — no longer
 * coupled to the sidebar's menu-button primitives.
 */
export function ThemeToggle() {
  const { resolvedTheme, setTheme } = useTheme();
  const [mounted, setMounted] = useState(false);

  useEffect(() => setMounted(true), []);

  const isDark = mounted && resolvedTheme === "dark";

  return (
    <button
      type="button"
      disabled={!mounted}
      onClick={() => setTheme(isDark ? "light" : "dark")}
      className="flex w-full items-center gap-3 px-4 py-4 text-left transition-colors active:bg-muted disabled:opacity-50"
    >
      <span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-2xl bg-muted">
        {isDark ? (
          <Sun className="h-4 w-4 text-warning" />
        ) : (
          <Moon className="h-4 w-4 text-primary" />
        )}
      </span>
      <span className="flex-1">
        <span className="block text-sm font-bold">Appearance</span>
        <span className="block text-xs text-muted-foreground">{isDark ? "Dark theme" : "Light theme"}</span>
      </span>
      <span className={`relative h-7 w-12 rounded-full transition-colors ${isDark ? "bg-primary" : "bg-muted"}`}>
        <span className={`absolute top-1 h-5 w-5 rounded-full bg-card shadow-sm transition-transform ${isDark ? "translate-x-6" : "translate-x-1"}`} />
      </span>
    </button>
  );
}
