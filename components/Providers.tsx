"use client";

import { SessionProvider } from "next-auth/react";
import { ThemeProvider } from "next-themes";
import { GymSettingsProvider } from "@/lib/useGymSettings";
import { SWRConfig } from "swr";

export function Providers({ children }: { children: React.ReactNode }) {
  return (
    <SessionProvider>
      <ThemeProvider attribute="class" defaultTheme="system" enableSystem>
        <GymSettingsProvider>
          <SWRConfig
            value={{
              revalidateOnFocus: false,
              dedupingInterval: 5000,
            }}
          >
            {children}
          </SWRConfig>
        </GymSettingsProvider>
      </ThemeProvider>
    </SessionProvider>
  );
}
