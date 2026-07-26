"use client";

import { useState, useRef, useEffect } from "react";
import { useRouter } from "next/navigation";
import { Building2, Pencil } from "lucide-react";
import { cn } from "@/lib/utils";
import { toast } from "sonner";
import { StackHeader } from "@/components/layout/StackHeader";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { BottomSheetForm } from "@/components/dashboard/BottomSheetForm";
import { useInvalidateGyms, type Gym } from "@/lib/hooks/useGyms";

const PRESET_COLORS = [
  "#6366f1", "#f97316", "#10b981", "#ef4444", "#8b5cf6",
  "#06b6d4", "#f59e0b", "#ec4899", "#14b8a6", "#6d28d9",
];

const TIMEZONES = [
  "Asia/Kolkata",
  "Asia/Dubai",
  "Asia/Singapore",
  "Europe/London",
  "America/New_York",
  "America/Los_Angeles",
  "Australia/Sydney",
];

const selectClass =
  "flex h-12 w-full rounded-2xl border border-border/70 bg-card px-4 text-base focus-visible:border-primary/40 focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-primary/10";

const DEFAULT_FORM = {
  name: "",
  address: "",
  phone: "",
  email: "",
  currency: "INR",
  timezone: "Asia/Kolkata",
  primaryColor: "#6366f1",
  logo: "",
};

interface GymFormProps {
  mode: "create" | "edit";
  /** "page" (default) renders a full-screen StackHeader page; "sheet" renders
   *  inside a BottomSheetForm. */
  variant?: "page" | "sheet";
  /** Required when variant="sheet". */
  open?: boolean;
  onOpenChange?: (open: boolean) => void;
  /** Required for edit mode. */
  gym?: Gym | null;
  onSuccess: (gym: Gym) => void;
}

export function GymForm({ mode, variant = "page", open, onOpenChange, gym, onSuccess }: GymFormProps) {
  const router = useRouter();
  const invalidateGyms = useInvalidateGyms();
  const fileInputRef = useRef<HTMLInputElement>(null);
  const isEdit = mode === "edit";

  const [form, setForm] = useState(() =>
    gym
      ? {
          name: gym.name,
          address: gym.address ?? "",
          phone: gym.phone ?? "",
          email: gym.email ?? "",
          currency: gym.currency ?? "INR",
          timezone: gym.timezone ?? "Asia/Kolkata",
          primaryColor: gym.primaryColor ?? "#6366f1",
          logo: gym.logo ?? "",
        }
      : DEFAULT_FORM
  );
  const [logoPreview, setLogoPreview] = useState(gym?.logo ?? "");
  const [saving, setSaving] = useState(false);

  // If the gym prop resolves after mount (edit page fetches it), sync once.
  useEffect(() => {
    if (!gym) return;
    setForm({
      name: gym.name,
      address: gym.address ?? "",
      phone: gym.phone ?? "",
      email: gym.email ?? "",
      currency: gym.currency ?? "INR",
      timezone: gym.timezone ?? "Asia/Kolkata",
      primaryColor: gym.primaryColor ?? "#6366f1",
      logo: gym.logo ?? "",
    });
    setLogoPreview(gym.logo ?? "");
  }, [gym?._id]); // eslint-disable-line react-hooks/exhaustive-deps

  const handleLogoChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    if (file.size > 500 * 1024) {
      toast.error("Logo must be less than 500 KB");
      return;
    }
    const reader = new FileReader();
    reader.onloadend = () => {
      const base64 = reader.result as string;
      setLogoPreview(base64);
      setForm((f) => ({ ...f, logo: base64 }));
    };
    reader.readAsDataURL(file);
  };

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!form.name.trim()) {
      toast.error("Gym name is required");
      return;
    }
    if (form.currency && form.currency.length !== 3) {
      toast.error("Currency must be 3 characters (e.g. INR)");
      return;
    }
    if (form.primaryColor && !/^#[0-9a-fA-F]{6}$/.test(form.primaryColor)) {
      toast.error("Theme color must be a valid 6-digit hex (e.g. #6366f1)");
      return;
    }

    setSaving(true);
    try {
      const payload = {
        name: form.name.trim(),
        ...(form.address && { address: form.address }),
        ...(form.phone && { phone: form.phone }),
        ...(form.email && { email: form.email }),
        currency: form.currency || "INR",
        timezone: form.timezone || "Asia/Kolkata",
        primaryColor: form.primaryColor || "#6366f1",
        ...(!isEdit && { expiryReminderDays: 7 }),
        ...(form.logo && { logo: form.logo }),
      };

      const res = await fetch(
        isEdit ? `/api/gyms/${gym!._id}` : "/api/gyms",
        {
          method: isEdit ? "PUT" : "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(payload),
        }
      );

      if (!res.ok) {
        const data = await res.json();
        throw new Error(data.error || (isEdit ? "Failed to update gym" : "Failed to create gym"));
      }

      const saved: Gym = await res.json();
      toast.success(isEdit ? "Gym updated" : `Gym "${saved.name}" created!`);
      await invalidateGyms();
      onSuccess(saved);
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "Something went wrong");
    } finally {
      setSaving(false);
    }
  }

  const formFields = (
    <>
      {/* ── Logo ─────────────────────────────────────────────── */}
      <div className="flex items-center gap-4">
            <div className="relative shrink-0">
              {logoPreview ? (
                <img
                  src={logoPreview}
                  alt="Logo preview"
                  className="h-16 w-16 rounded-xl border border-border object-cover"
                />
              ) : (
                <div className="flex h-16 w-16 items-center justify-center rounded-xl bg-muted">
                  <Building2 className="h-7 w-7 text-muted-foreground" />
                </div>
              )}
              <button
                type="button"
                onClick={() => fileInputRef.current?.click()}
                className="absolute -bottom-1.5 -right-1.5 rounded-full bg-primary p-1.5 text-primary-foreground shadow-sm transition-colors hover:bg-primary/90"
              >
                <Pencil className="h-3 w-3" />
              </button>
              <input
                ref={fileInputRef}
                type="file"
                accept="image/*"
                className="hidden"
                onChange={handleLogoChange}
              />
            </div>
            <div className="text-sm text-muted-foreground">
              <p className="font-medium text-foreground">Gym Logo</p>
              <p className="text-xs">Tap to upload · Max 500 KB</p>
              <p className="text-xs">Falls back to gym initials if not set</p>
            </div>
          </div>

          {/* ── Name ─────────────────────────────────────────────── */}
          <div className="space-y-1.5">
            <Label htmlFor="gfd-name">
              Name <span className="text-destructive">*</span>
            </Label>
            <Input
              id="gfd-name"
              className="h-12"
              placeholder="e.g. FitZone Gym"
              value={form.name}
              onChange={(e) => setForm((f) => ({ ...f, name: e.target.value }))}
            />
          </div>

          {/* ── Phone + Email ─────────────────────────────────────── */}
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
            <div className="space-y-1.5">
              <Label htmlFor="gfd-phone">Phone</Label>
              <Input
                id="gfd-phone"
                className="h-12"
                placeholder="+91 98765 43210"
                value={form.phone}
                onChange={(e) => setForm((f) => ({ ...f, phone: e.target.value }))}
              />
            </div>
            <div className="space-y-1.5">
              <Label htmlFor="gfd-email">Email</Label>
              <Input
                id="gfd-email"
                type="email"
                className="h-12"
                placeholder="gym@example.com"
                value={form.email}
                onChange={(e) => setForm((f) => ({ ...f, email: e.target.value }))}
              />
            </div>
          </div>

          {/* ── Address ──────────────────────────────────────────── */}
          <div className="space-y-1.5">
            <Label htmlFor="gfd-address">Address</Label>
            <Input
              id="gfd-address"
              className="h-12"
              placeholder="123 Main St, City"
              value={form.address}
              onChange={(e) => setForm((f) => ({ ...f, address: e.target.value }))}
            />
          </div>

          {/* ── Currency + Color ─────────────────────────────────── */}
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
            <div className="space-y-1.5">
              <Label htmlFor="gfd-currency">Currency</Label>
              <Input
                id="gfd-currency"
                className="h-12"
                placeholder="INR"
                maxLength={3}
                value={form.currency}
                onChange={(e) => setForm((f) => ({ ...f, currency: e.target.value.toUpperCase() }))}
              />
            </div>
            <div className="space-y-1.5">
              <Label>Theme Color</Label>
              <div className="flex items-center gap-2">
                <input
                  type="color"
                  value={form.primaryColor}
                  onChange={(e) => setForm((f) => ({ ...f, primaryColor: e.target.value }))}
                  className="h-12 w-12 shrink-0 cursor-pointer rounded-2xl border border-border/70 bg-card p-1"
                />
                <Input
                  className="h-12 font-mono text-sm"
                  value={form.primaryColor}
                  onChange={(e) => setForm((f) => ({ ...f, primaryColor: e.target.value }))}
                  placeholder="#6366f1"
                />
              </div>
            </div>
          </div>

          <div className="space-y-1.5">
            <Label htmlFor="gfd-timezone">Gym timezone</Label>
            <select
              id="gfd-timezone"
              className={selectClass}
              value={form.timezone}
              onChange={(event) => setForm((current) => ({ ...current, timezone: event.target.value }))}
            >
              {TIMEZONES.map((timeZone) => (
                <option key={timeZone} value={timeZone}>{timeZone.replaceAll("_", " ")}</option>
              ))}
            </select>
            <p className="text-xs text-muted-foreground">Membership dates and reports use this timezone.</p>
          </div>

          {/* ── Preset swatches ───────────────────────────────────── */}
          <div className="space-y-1.5">
            <Label className="text-xs text-muted-foreground">Quick colors</Label>
            <div className="flex flex-wrap gap-2">
              {PRESET_COLORS.map((color) => (
                <button
                  key={color}
                  type="button"
                  title={color}
                  onClick={() => setForm((f) => ({ ...f, primaryColor: color }))}
                  className={cn(
                    "h-8 w-8 rounded-full border-2 transition-all",
                    form.primaryColor === color
                      ? "scale-110 border-foreground shadow-sm"
                      : "border-transparent"
                  )}
                  style={{ backgroundColor: color }}
                />
              ))}
            </div>
          </div>
    </>
  );

  const submitLabel = saving
    ? isEdit
      ? "Saving…"
      : "Creating…"
    : isEdit
    ? "Save Changes"
    : "Create Gym";

  if (variant === "sheet") {
    return (
      <BottomSheetForm
        open={open ?? false}
        onOpenChange={onOpenChange ?? (() => {})}
        title={isEdit ? "Edit Gym" : "Add New Gym"}
        footer={
          <Button
            type="submit"
            form="gym-form"
            className="h-12 w-full text-base font-semibold"
            disabled={saving || !form.name.trim()}
          >
            {submitLabel}
          </Button>
        }
      >
        <form id="gym-form" onSubmit={handleSubmit} className="space-y-5 pb-4">
          {formFields}
        </form>
      </BottomSheetForm>
    );
  }

  return (
    <div className="app-canvas flex min-h-svh flex-col">
      <StackHeader title={isEdit ? "Edit Gym" : "Add New Gym"} onBack={() => router.back()} />
      <form onSubmit={handleSubmit} className="flex flex-1 flex-col">
        <div className="flex-1 space-y-5 px-5 py-5">{formFields}</div>
        <div
          className="shrink-0 border-t px-4 py-3"
          style={{ paddingBottom: "calc(0.75rem + env(safe-area-inset-bottom))" }}
        >
          <Button
            type="submit"
            className="h-12 w-full text-base font-semibold"
            disabled={saving || !form.name.trim()}
          >
            {submitLabel}
          </Button>
        </div>
      </form>
    </div>
  );
}
