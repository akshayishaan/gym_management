"use client";

import {
  createContext,
  useContext,
  useEffect,
  useState,
  useCallback,
  ReactNode,
} from "react";
import { getGymCookie, setGymCookie } from "@/lib/gymCookie";

interface GymSettings {
  gymName: string;
  currency: string;
  primaryColor: string;
  address?: string;
  phone?: string;
  email?: string;
}

interface GymContextValue extends GymSettings {
  /** Currently selected gym ID. Initialised from the browser cookie so it
   *  survives page refresh. Null until the first fetch resolves (or no gym
   *  has ever been selected). */
  selectedGymId: string | null;
  /** Switch to a different gym. Writes the cookie, updates context state,
   *  and re-fetches gym settings — all synchronously / without an API call
   *  for the switch itself. Call router.refresh() in the component if server
   *  components need to re-render with the new gym's data. */
  switchGym: (gymId: string) => void;
}

const defaultSettings: GymContextValue = {
  gymName: "My Gym",
  currency: "INR",
  primaryColor: "#6366f1",
  selectedGymId: null,
  switchGym: () => {},
};

const GymSettingsContext = createContext<GymContextValue>(defaultSettings);

export function GymSettingsProvider({ children }: { children: ReactNode }) {
  const [settings, setSettings] = useState<GymSettings>({
    gymName: defaultSettings.gymName,
    currency: defaultSettings.currency,
    primaryColor: defaultSettings.primaryColor,
  });

  // Always null on the server (no document). Populated on the client via the
  // cookie effect below — kept separate from fetchSettings so that an in-flight
  // settings fetch can never overwrite the user's explicit gym selection.
  const [selectedGymId, setSelectedGymId] = useState<string | null>(null);

  // Restore selected gym from cookie on client mount — synchronous, no API call.
  // Runs before fetchSettings so the sidebar shows the right gym immediately.
  useEffect(() => {
    const id = getGymCookie();
    if (id) setSelectedGymId(id);
  }, []);

  const fetchSettings = useCallback(() => {
    fetch("/api/gyms")
      .then((r) => r.json())
      .then((data) => {
        const gyms: Array<Record<string, unknown>> = data.gyms || [];
        if (!gyms.length) return;
        // Prefer the gym matching the current cookie; fall back to first.
        const cookieId = getGymCookie();
        const gym = (cookieId && gyms.find((g) => g._id === cookieId)) || gyms[0];
        if (!gym) return;
        setSettings({
          gymName: (gym.name as string) || defaultSettings.gymName,
          currency: (gym.currency as string) || defaultSettings.currency,
          primaryColor: (gym.primaryColor as string) || defaultSettings.primaryColor,
          address: gym.address as string | undefined,
          phone: gym.phone as string | undefined,
          email: gym.email as string | undefined,
        });
        // Only initialise the cookie on first visit (no cookie set yet).
        if (gym._id && !getGymCookie()) {
          setGymCookie(gym._id as string);
          setSelectedGymId(gym._id as string);
        }
      })
      .catch(() => {
        // Keep defaults on error
      });
  }, []);

  useEffect(() => {
    fetchSettings();
  }, [fetchSettings]);

  /** Pure client-side switch — no API call needed.
   *  The cookie is read by the server on every request (lib/selectedGym.ts)
   *  to scope data queries to the correct gym. */
  const switchGym = useCallback(
    (gymId: string) => {
      setGymCookie(gymId);     // persist across refresh
      setSelectedGymId(gymId); // update context → all subscribers re-render instantly
      fetchSettings();         // update gymName / currency / color for the new gym
    },
    [fetchSettings]
  );

  return (
    <GymSettingsContext.Provider value={{ ...settings, selectedGymId, switchGym }}>
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
