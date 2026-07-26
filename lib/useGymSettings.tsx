"use client";

import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useRef,
  useState,
  type ReactNode,
} from "react";
import { useQueryClient } from "@tanstack/react-query";
import { getGymCookie, setGymCookie } from "@/lib/gymCookie";
import { useGyms } from "@/lib/hooks/useGyms";
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from "@/components/ui/alert-dialog";

interface GymSettings {
  gymName: string;
  currency: string;
  timezone: string;
  primaryColor: string;
  address?: string;
  phone?: string;
  email?: string;
}

interface GymContextValue extends GymSettings {
  selectedGymId: string | null;
  switchGym: (gymId: string) => void;
  registerScopedForm: (registration: ScopedFormRegistration) => () => void;
}

interface ScopedFormRegistration {
  isDirty: () => boolean;
  reset: () => void;
}

const DEFAULT_SETTINGS: GymSettings = {
  gymName: "My Gym",
  currency: "INR",
  timezone: "Asia/Kolkata",
  primaryColor: "#6366f1",
};

const GymSettingsContext = createContext<GymContextValue>({
  ...DEFAULT_SETTINGS,
  selectedGymId: null,
  switchGym: () => {},
  registerScopedForm: () => () => {},
});

export function GymSettingsProvider({ children }: { children: ReactNode }) {
  const queryClient = useQueryClient();
  const { data: gyms = [] } = useGyms();
  const [selectedGymId, setSelectedGymId] = useState<string | null>(null);
  const [pendingGymId, setPendingGymId] = useState<string | null>(null);
  const scopedFormsRef = useRef(new Map<symbol, ScopedFormRegistration>());

  useEffect(() => {
    const cookieGymId = getGymCookie();
    if (cookieGymId) setSelectedGymId(cookieGymId);
  }, []);

  useEffect(() => {
    if (gyms.length === 0) return;
    const selectedIsAuthorized = selectedGymId
      && gyms.some((gym) => gym._id === selectedGymId);
    if (selectedIsAuthorized) return;

    const cookieGymId = getGymCookie();
    const fallback = gyms.find((gym) => gym._id === cookieGymId) ?? gyms[0];
    setGymCookie(fallback._id);
    setSelectedGymId(fallback._id);
  }, [gyms, selectedGymId]);

  const selectedGym = useMemo(
    () => gyms.find((gym) => gym._id === selectedGymId),
    [gyms, selectedGymId]
  );

  const registerScopedForm = useCallback((registration: ScopedFormRegistration) => {
    const key = Symbol("gym-scoped-form");
    scopedFormsRef.current.set(key, registration);
    return () => scopedFormsRef.current.delete(key);
  }, []);

  const performGymSwitch = useCallback((gymId: string) => {
    for (const registration of scopedFormsRef.current.values()) {
      registration.reset();
    }
    setGymCookie(gymId);
    setSelectedGymId(gymId);
    void queryClient.invalidateQueries({ queryKey: ["gym", gymId] });
  }, [queryClient]);

  const switchGym = useCallback((gymId: string) => {
    if (gymId === selectedGymId || !gyms.some((gym) => gym._id === gymId)) return;
    const hasDirtyForm = Array.from(scopedFormsRef.current.values())
      .some((registration) => registration.isDirty());
    if (hasDirtyForm) {
      setPendingGymId(gymId);
      return;
    }
    performGymSwitch(gymId);
  }, [gyms, performGymSwitch, selectedGymId]);

  const settings: GymSettings = selectedGym
    ? {
        gymName: selectedGym.name || DEFAULT_SETTINGS.gymName,
        currency: selectedGym.currency || DEFAULT_SETTINGS.currency,
        timezone: selectedGym.timezone || DEFAULT_SETTINGS.timezone,
        primaryColor: selectedGym.primaryColor || DEFAULT_SETTINGS.primaryColor,
        address: selectedGym.address,
        phone: selectedGym.phone,
        email: selectedGym.email,
      }
    : DEFAULT_SETTINGS;

  return (
    <GymSettingsContext.Provider value={{
      ...settings,
      selectedGymId,
      switchGym,
      registerScopedForm,
    }}>
      {children}
      <AlertDialog
        open={!!pendingGymId}
        onOpenChange={(open) => {
          if (!open) setPendingGymId(null);
        }}
      >
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Discard changes and switch Gym?</AlertDialogTitle>
            <AlertDialogDescription>
              An open form has unsaved changes. Switching Gym will close it and reset its fields.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Keep editing</AlertDialogCancel>
            <AlertDialogAction
              onClick={() => {
                if (pendingGymId) performGymSwitch(pendingGymId);
                setPendingGymId(null);
              }}
            >
              Discard and switch
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </GymSettingsContext.Provider>
  );
}

export function useGymSettings() {
  return useContext(GymSettingsContext);
}

export function useGymScopedFormGuard(options: {
  active: boolean;
  dirty: boolean;
  reset: () => void;
}) {
  const { registerScopedForm } = useGymSettings();
  const dirtyRef = useRef(options.dirty);
  const resetRef = useRef(options.reset);
  dirtyRef.current = options.dirty;
  resetRef.current = options.reset;

  useEffect(() => {
    if (!options.active) return;
    return registerScopedForm({
      isDirty: () => dirtyRef.current,
      reset: () => resetRef.current(),
    });
  }, [options.active, registerScopedForm]);
}

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
