"use client";

import { useState, useRef, useEffect } from "react";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
  DialogFooter,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Building2, Pencil } from "lucide-react";
import { cn } from "@/lib/utils";
import { toast } from "sonner";
import { useInvalidateGyms, type Gym } from "@/lib/hooks/useGyms";

const PRESET_COLORS = [
  "#6366f1", "#f97316", "#10b981", "#ef4444", "#8b5cf6",
  "#06b6d4", "#f59e0b", "#ec4899", "#14b8a6", "#6d28d9",
];

const DEFAULT_FORM = {
  name: "",
  address: "",
  phone: "",
  email: "",
  currency: "INR",
  primaryColor: "#6366f1",
  logo: "",
};

interface GymFormDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  /** Omit for create mode; pass a Gym to edit it. */
  gym?: Gym | null;
  onSuccess?: (gym: Gym) => void;
}

export function GymFormDialog({ open, onOpenChange, gym, onSuccess }: GymFormDialogProps) {
  const invalidateGyms = useInvalidateGyms();
  const fileInputRef = useRef<HTMLInputElement>(null);
  const [form, setForm] = useState(DEFAULT_FORM);
  const [logoPreview, setLogoPreview] = useState("");
  const [saving, setSaving] = useState(false);

  // Sync form whenever the dialog opens or the target gym changes
  useEffect(() => {
    if (!open) return;
    if (gym) {
      setForm({
        name: gym.name,
        address: gym.address ?? "",
        phone: gym.phone ?? "",
        email: gym.email ?? "",
        currency: gym.currency ?? "INR",
        primaryColor: gym.primaryColor ?? "#6366f1",
        logo: gym.logo ?? "",
      });
      setLogoPreview(gym.logo ?? "");
    } else {
      setForm(DEFAULT_FORM);
      setLogoPreview("");
    }
  }, [open, gym]);

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
      setForm(f => ({ ...f, logo: base64 }));
    };
    reader.readAsDataURL(file);
  };

  const handleSave = async () => {
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
        primaryColor: form.primaryColor || "#6366f1",
        // Only include on create; updates preserve the existing value
        ...(!gym && { expiryReminderDays: 7 }),
        ...(form.logo && { logo: form.logo }),
      };

      const res = await fetch(
        gym ? `/api/gyms/${gym._id}` : "/api/gyms",
        {
          method: gym ? "PUT" : "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(payload),
        }
      );

      if (!res.ok) {
        const data = await res.json();
        throw new Error(data.error || (gym ? "Failed to update gym" : "Failed to create gym"));
      }

      const saved: Gym = await res.json();
      toast.success(gym ? "Gym updated" : `Gym "${saved.name}" created!`);
      await invalidateGyms();
      onOpenChange(false);
      onSuccess?.(saved);
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "Something went wrong");
    } finally {
      setSaving(false);
    }
  };

  const isEdit = !!gym;

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-md max-h-[90vh] flex flex-col gap-0 p-0">
        <DialogHeader className="px-6 pt-6 pb-4 shrink-0">
          <DialogTitle>{isEdit ? "Edit Gym" : "Add New Gym"}</DialogTitle>
          <DialogDescription>
            {isEdit
              ? "Update your gym's details below."
              : "Fill in the details to create a new gym location."}
          </DialogDescription>
        </DialogHeader>

        <div className="flex-1 overflow-y-auto px-6 space-y-4 pb-2">
          {/* ── Logo ─────────────────────────────────────────────── */}
          <div className="flex items-center gap-4">
            <div className="relative shrink-0">
              {logoPreview ? (
                <img
                  src={logoPreview}
                  alt="Logo preview"
                  className="h-14 w-14 rounded-xl object-cover border border-border"
                />
              ) : (
                <div className="h-14 w-14 rounded-xl bg-muted flex items-center justify-center">
                  <Building2 className="h-6 w-6 text-muted-foreground" />
                </div>
              )}
              <button
                type="button"
                onClick={() => fileInputRef.current?.click()}
                className="absolute -bottom-1.5 -right-1.5 rounded-full bg-primary text-primary-foreground p-1 shadow-sm hover:bg-primary/90 transition-colors"
              >
                <Pencil className="h-2.5 w-2.5" />
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
              <p className="text-xs">Click to upload · Max 500 KB</p>
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
              placeholder="e.g. FitZone Gym"
              value={form.name}
              onChange={e => setForm(f => ({ ...f, name: e.target.value }))}
              onKeyDown={e => e.key === "Enter" && !saving && handleSave()}
            />
          </div>

          {/* ── Phone + Email ─────────────────────────────────────── */}
          <div className="grid grid-cols-2 gap-3">
            <div className="space-y-1.5">
              <Label htmlFor="gfd-phone">Phone</Label>
              <Input
                id="gfd-phone"
                placeholder="+91 98765 43210"
                value={form.phone}
                onChange={e => setForm(f => ({ ...f, phone: e.target.value }))}
              />
            </div>
            <div className="space-y-1.5">
              <Label htmlFor="gfd-email">Email</Label>
              <Input
                id="gfd-email"
                type="email"
                placeholder="gym@example.com"
                value={form.email}
                onChange={e => setForm(f => ({ ...f, email: e.target.value }))}
              />
            </div>
          </div>

          {/* ── Address ──────────────────────────────────────────── */}
          <div className="space-y-1.5">
            <Label htmlFor="gfd-address">Address</Label>
            <Input
              id="gfd-address"
              placeholder="123 Main St, City"
              value={form.address}
              onChange={e => setForm(f => ({ ...f, address: e.target.value }))}
            />
          </div>

          {/* ── Currency + Color ─────────────────────────────────── */}
          <div className="grid grid-cols-2 gap-3">
            <div className="space-y-1.5">
              <Label htmlFor="gfd-currency">Currency</Label>
              <Input
                id="gfd-currency"
                placeholder="INR"
                maxLength={3}
                value={form.currency}
                onChange={e => setForm(f => ({ ...f, currency: e.target.value.toUpperCase() }))}
              />
            </div>
            <div className="space-y-1.5">
              <Label>Theme Color</Label>
              <div className="flex items-center gap-2">
                <input
                  type="color"
                  value={form.primaryColor}
                  onChange={e => setForm(f => ({ ...f, primaryColor: e.target.value }))}
                  className="h-9 w-9 shrink-0 rounded-md border border-input cursor-pointer p-0.5 bg-background"
                />
                <Input
                  value={form.primaryColor}
                  onChange={e => setForm(f => ({ ...f, primaryColor: e.target.value }))}
                  placeholder="#6366f1"
                  className="font-mono text-sm"
                />
              </div>
            </div>
          </div>

          {/* ── Preset swatches ───────────────────────────────────── */}
          <div className="space-y-1.5">
            <Label className="text-xs text-muted-foreground">Quick colors</Label>
            <div className="flex flex-wrap gap-2">
              {PRESET_COLORS.map(color => (
                <button
                  key={color}
                  type="button"
                  title={color}
                  onClick={() => setForm(f => ({ ...f, primaryColor: color }))}
                  className={cn(
                    "h-6 w-6 rounded-full border-2 transition-all hover:scale-110",
                    form.primaryColor === color
                      ? "border-foreground scale-110 shadow-sm"
                      : "border-transparent"
                  )}
                  style={{ backgroundColor: color }}
                />
              ))}
            </div>
          </div>
        </div>

        <DialogFooter className="px-6 py-4 border-t shrink-0">
          <Button variant="outline" onClick={() => onOpenChange(false)} disabled={saving}>
            Cancel
          </Button>
          <Button onClick={handleSave} disabled={saving || !form.name.trim()}>
            {saving
              ? isEdit ? "Saving..." : "Creating..."
              : isEdit ? "Save Changes" : "Create Gym"}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
