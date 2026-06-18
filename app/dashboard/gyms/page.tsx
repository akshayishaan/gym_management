"use client";

import { useEffect, useState, useRef } from "react";
import { useRouter } from "next/navigation";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
} from "@/components/ui/dialog";
import { Card, CardContent } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Plus, Pencil, Building2, MapPin, Phone, Mail } from "lucide-react";
import { motion } from "framer-motion";
import { toast } from "sonner";
import { PageHeader } from "@/components/layout/PageHeader";
import { GymAvatar } from "@/components/ui/gym-avatar";

interface Gym {
  _id: string;
  name: string;
  logo?: string;
  primaryColor?: string;
  address?: string;
  phone?: string;
  email?: string;
  currency: string;
  isActive: boolean;
  createdAt: string;
}

const emptyForm = {
  name: "",
  address: "",
  phone: "",
  email: "",
  currency: "INR",
  primaryColor: "#f97316",
  expiryReminderDays: 7,
  logo: "",
};

export default function GymsPage() {
  const router = useRouter();
  const [gyms, setGyms] = useState<Gym[]>([]);
  const [loading, setLoading] = useState(true);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [editGym, setEditGym] = useState<Gym | null>(null);
  const [form, setForm] = useState(emptyForm);
  const [saving, setSaving] = useState(false);
  const fileInputRef = useRef<HTMLInputElement>(null);
  const [logoPreview, setLogoPreview] = useState<string>("");

  const fetchGyms = () => {
    setLoading(true);
    fetch("/api/gyms")
      .then((r) => r.json())
      .then((data) => setGyms(Array.isArray(data) ? data : []))
      .finally(() => setLoading(false));
  };

  useEffect(() => { fetchGyms(); }, []);

  const openCreate = () => {
    setEditGym(null);
    setForm(emptyForm);
    setLogoPreview("");
    setDialogOpen(true);
  };

  const openEdit = (gym: Gym) => {
    setEditGym(gym);
    setForm({
      name: gym.name,
      address: gym.address || "",
      phone: gym.phone || "",
      email: gym.email || "",
      currency: gym.currency,
      primaryColor: gym.primaryColor || "#f97316",
      expiryReminderDays: 7,
      logo: gym.logo || "",
    });
    setLogoPreview(gym.logo || "");
    setDialogOpen(true);
  };

  const handleLogoChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    // Validate file size (max 500KB)
    if (file.size > 500 * 1024) {
      toast.error("Logo must be less than 500KB");
      return;
    }

    // Convert to base64
    const reader = new FileReader();
    reader.onloadend = () => {
      const base64 = reader.result as string;
      setLogoPreview(base64);
      setForm({ ...form, logo: base64 });
    };
    reader.readAsDataURL(file);
  };

  const handleSave = async () => {
    if (!form.name) return toast.error("Gym name is required");
    setSaving(true);
    try {
      if (editGym) {
        const res = await fetch(`/api/gyms/${editGym._id}`, {
          method: "PUT",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            name: form.name,
            address: form.address,
            phone: form.phone,
            email: form.email,
            currency: form.currency,
            primaryColor: form.primaryColor,
            expiryReminderDays: form.expiryReminderDays,
            logo: form.logo || undefined,
          }),
        });
        if (!res.ok) throw new Error("Failed to update gym");
        toast.success("Gym updated");
      } else {
        const res = await fetch("/api/gyms", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            name: form.name,
            address: form.address,
            phone: form.phone,
            email: form.email,
            currency: form.currency,
            primaryColor: form.primaryColor,
            expiryReminderDays: form.expiryReminderDays,
            logo: form.logo || undefined,
          }),
        });
        if (!res.ok) throw new Error("Failed to create gym");
        toast.success("Gym created! You can now switch to it from the sidebar.");
      }
      setDialogOpen(false);
      fetchGyms();
    } catch (e) {
      toast.error(e instanceof Error ? e.message : "Error");
    } finally {
      setSaving(false);
    }
  };

  const handleSwitchToGym = async (gymId: string) => {
    try {
      const res = await fetch("/api/auth/select-gym", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ gymId }),
      });
      if (!res.ok) throw new Error("Failed to switch gym");
      toast.success("Gym switched!");
      router.refresh();
    } catch (e) {
      toast.error(e instanceof Error ? e.message : "Failed to switch gym");
    }
  };

  return (
    <div className="space-y-6">
      <PageHeader
        title="My Gyms"
        description="Manage your gym locations"
        actions={
          <Button onClick={openCreate} className="gap-2">
            <Plus className="h-4 w-4" /> Add Gym
          </Button>
        }
      />

      {loading ? (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {[1, 2, 3].map((i) => (
            <Card key={i} className="border-0 shadow-card">
              <CardContent className="p-6">
                <div className="animate-pulse space-y-3">
                  <div className="h-12 w-12 rounded-full bg-muted" />
                  <div className="h-4 w-32 bg-muted rounded" />
                  <div className="h-3 w-24 bg-muted rounded" />
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      ) : gyms.length === 0 ? (
        <Card className="border-0 shadow-card">
          <CardContent className="py-16 text-center">
            <Building2 className="h-12 w-12 mx-auto text-muted-foreground/50 mb-4" />
            <h3 className="text-lg font-medium mb-1">No gyms yet</h3>
            <p className="text-sm text-muted-foreground mb-4">
              Create your first gym to start managing members and payments.
            </p>
            <Button onClick={openCreate} className="gap-2">
              <Plus className="h-4 w-4" /> Add Your First Gym
            </Button>
          </CardContent>
        </Card>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {gyms.map((gym, i) => (
            <motion.div
              key={gym._id}
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: i * 0.05 }}
            >
              <Card className="border-0 shadow-card hover:shadow-card-hover transition-shadow duration-300 group">
                <CardContent className="p-6">
                  <div className="flex items-start gap-4">
                    <GymAvatar
                      name={gym.name}
                      logo={gym.logo}
                      primaryColor={gym.primaryColor}
                      className="h-12 w-12"
                    />
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2 mb-1">
                        <h3 className="font-semibold truncate">{gym.name}</h3>
                        <Badge variant={gym.isActive ? "default" : "secondary"} className="text-xs shrink-0">
                          {gym.isActive ? "Active" : "Inactive"}
                        </Badge>
                      </div>
                      {gym.address && (
                        <p className="text-sm text-muted-foreground flex items-center gap-1 mb-1">
                          <MapPin className="h-3 w-3 shrink-0" /> {gym.address}
                        </p>
                      )}
                      <div className="flex items-center gap-3 text-xs text-muted-foreground">
                        {gym.phone && (
                          <span className="flex items-center gap-1">
                            <Phone className="h-3 w-3" /> {gym.phone}
                          </span>
                        )}
                        {gym.email && (
                          <span className="flex items-center gap-1">
                            <Mail className="h-3 w-3" /> {gym.email}
                          </span>
                        )}
                      </div>
                    </div>
                  </div>
                  <div className="flex items-center gap-2 mt-4 pt-4 border-t">
                    <Button
                      size="sm"
                      variant="outline"
                      className="flex-1"
                      onClick={() => handleSwitchToGym(gym._id)}
                    >
                      Switch to Gym
                    </Button>
                    <Button
                      size="sm"
                      variant="ghost"
                      onClick={() => openEdit(gym)}
                    >
                      <Pencil className="h-4 w-4" />
                    </Button>
                  </div>
                </CardContent>
              </Card>
            </motion.div>
          ))}
        </div>
      )}

      {/* Create/Edit Dialog */}
      <Dialog open={dialogOpen} onOpenChange={setDialogOpen}>
        <DialogContent className="max-w-lg">
          <DialogHeader>
            <DialogTitle>{editGym ? "Edit Gym" : "Add New Gym"}</DialogTitle>
          </DialogHeader>
          <div className="space-y-4 py-2">
            {/* Logo upload */}
            <div className="flex items-center gap-4">
              <div className="relative">
                {logoPreview ? (
                  <img
                    src={logoPreview}
                    alt="Logo preview"
                    className="h-16 w-16 rounded-xl object-cover border-2 border-border"
                  />
                ) : (
                  <div className="h-16 w-16 rounded-xl bg-muted flex items-center justify-center">
                    <Building2 className="h-6 w-6 text-muted-foreground" />
                  </div>
                )}
                <button
                  type="button"
                  onClick={() => fileInputRef.current?.click()}
                  className="absolute -bottom-1 -right-1 bg-primary text-primary-foreground rounded-full p-1 shadow-sm hover:bg-primary/90 transition-colors"
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
                <p>Click to upload. Max 500KB.</p>
                <p>If no logo, first letter of gym name will be used.</p>
              </div>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div className="col-span-2 space-y-1">
                <Label>Gym Name *</Label>
                <Input
                  value={form.name}
                  onChange={(e) => setForm({ ...form, name: e.target.value })}
                  placeholder="Fitness First"
                />
              </div>
              <div className="space-y-1">
                <Label>Phone</Label>
                <Input
                  value={form.phone}
                  onChange={(e) => setForm({ ...form, phone: e.target.value })}
                  placeholder="+91 98765 43210"
                />
              </div>
              <div className="space-y-1">
                <Label>Email</Label>
                <Input
                  type="email"
                  value={form.email}
                  onChange={(e) => setForm({ ...form, email: e.target.value })}
                  placeholder="gym@example.com"
                />
              </div>
              <div className="col-span-2 space-y-1">
                <Label>Address</Label>
                <Input
                  value={form.address}
                  onChange={(e) => setForm({ ...form, address: e.target.value })}
                  placeholder="123 Main St"
                />
              </div>
              <div className="space-y-1">
                <Label>Currency</Label>
                <Input
                  value={form.currency}
                  onChange={(e) => setForm({ ...form, currency: e.target.value })}
                  placeholder="INR"
                />
              </div>
              <div className="space-y-1">
                <Label>Primary Color</Label>
                <div className="flex items-center gap-2">
                  <input
                    type="color"
                    value={form.primaryColor}
                    onChange={(e) => setForm({ ...form, primaryColor: e.target.value })}
                    className="h-9 w-9 rounded border cursor-pointer"
                  />
                  <Input
                    value={form.primaryColor}
                    onChange={(e) => setForm({ ...form, primaryColor: e.target.value })}
                    placeholder="#f97316"
                    className="flex-1"
                  />
                </div>
              </div>
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setDialogOpen(false)}>Cancel</Button>
            <Button onClick={handleSave} disabled={saving}>
              {saving ? "Saving..." : editGym ? "Update Gym" : "Create Gym"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
