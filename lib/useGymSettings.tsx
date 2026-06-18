"use client";

import { createContext, useContext, useEffect, useState, useCallback, ReactNode } from "react";

interface GymInfo {
  _id: string;
  name: string;
  logo?: string;
  primaryColor: string;
  address?: string;
  phone?: string;
  email?: string;
  currency: string;
}

interface GymSettings {
  gymName: string;
  currency: string;
  primaryColor: string;
  address?: string;
  phone?: string;
  email?: string;
  selectedGymId?: string;
}

const defaultSettings: GymSettings = {
  gymName: "My Gym",
  currency: "INR",
  primaryColor: "#6366f1",
};

const GymSettingsContext = createContext<GymSettings>(defaultSettings);

export function GymSettingsProvider({ children }: { children: ReactNode }) {
  const [settings, setSettings] = useState<GymSettings>(defaultSettings);

  const fetchSettings = useCallback(() => {
    fetch("/api/settings")
      .then((r) => r.json())
      .then((data) => {
        if (data && data.currency) {
          setSettings({
            gymName: data.gymName || data.name || defaultSettings.gymName,
            currency: data.currency || defaultSettings.currency,
            primaryColor: data.primaryColor || defaultSettings.primaryColor,
            address: data.address,
            phone: data.phone,
            email: data.email,
            selectedGymId: data._id,
          });
        }
      })
      .catch(() => {
        // Keep defaults on error
      });
  }, []);

  useEffect(() => {
    fetchSettings();
  }, [fetchSettings]);

  return (
    <GymSettingsContext.Provider value={settings}>
      {children}
    </GymSettingsContext.Provider>
  );
}

export function useGymSettings() {
  return useContext(GymSettingsContext);
}

/**
 * Returns the currency symbol for the current gym's currency setting.
 * Use this instead of hardcoding ₹ in the UI.
 */
export function useCurrencySymbol(): string {
  const { currency } = useGymSettings();
  const symbols: Record<string, string> = {
    INR: "₹",
    USD: "$",
    EUR: "€",
    GBP: "£",
  };
  return symbols[currency] || currency;
}
