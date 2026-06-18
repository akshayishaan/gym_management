"use client";

import { useEffect, useState, useRef } from "react";
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
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";
import { Plus, Pencil, Trash2, Building2 } from "lucide-react";
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
  // First admin credentials
  adminName: "",
  adminEmail: "",
  adminPassword: "",
  logo: "",
};

export default function GymsPage() {
  const [gyms, setGyms] = useState<Gym[]>([]);
  const [loading, setLoading] = useState(true);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [editGym, setEditGym] = useState<Gym | null>(null);
  const [form, setForm] = useState(emptyForm);
  const [saving, setSaving] = useState(false);
  const [deleteId, setDeleteId] = useState<string | null>(null);
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
      adminName: "",
      adminEmail: "",
      adminPassword: "",
      logo: gym.logo || "",
    });
    setLogoPreview(gym.logo || "");
    setDialogOpen(true);
  };

  const handleLogoChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    if (file.size > 500 * 1024) {
      toast.error("Logo must be less than 500KB");
      return;
    }
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
    if (!editGym && (!form.adminEmail || !form.adminPassword)) {
      return toast.error("Admin email and password are required for new gym");
    }
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
        // Create gym
        const gymRes = await fetch("/api/gyms", {
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
        if (!gymRes.ok) throw new Error("Failed to create gym");
        const gym = await gymRes.json();

        // Create gym admin
        const staffRes = await fetch("/api/staff", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            name: form.adminName || "Admin",
            email: form.adminEmail,
            password: form.adminPassword,
            role: "admin",
            gymIds: [gym._id],
            isActive: true,
          }),
        });
        if (!staffRes.ok) throw new Error("Failed to create gym admin");
        toast.success("Gym and admin created");
      }
      setDialogOpen(false);
      fetchGyms();
    } catch (e) {
      toast.error(e instanceof Error ? e.message : "Error");
    } finally {
      setSaving(false);
    }
  };

  const handleToggleActive = async (gym: Gym) => {
    await fetch(`/api/gyms/${gym._id}`, {
      method: "PUT",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ isActive: !gym.isActive }),
    });
    fetchGyms();
  };

  const handleDelete = async () => {
    if (!deleteId) return;
    const res = await fetch(`/api/gyms/${deleteId}`, { method: "DELETE" });
    if (res.ok) {
      toast.success("Gym deleted");
      fetchGyms();
    } else {
      toast.error("Failed to delete gym");
    }
    setDeleteId(null);
  };

  return (
    <div className="space-y-6">
      <PageHeader
        title="Gyms"
        description="Manage all gym locations"
        actions={
          <Button onClick={openCreate} className="gap-2">
            <Plus className="h-4 w-4" /> Add Gym
          </Button>
        }
      />

      <div className="rounded-md border overflow-x-auto">
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Gym</TableHead>
              <TableHead>Phone</TableHead>
              <TableHead>Email</TableHead>
              <TableHead>Currency</TableHead>
              <TableHead>Status</TableHead>
              <TableHead>Created</TableHead>
              <TableHead className="text-right">Actions</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {loading ? (
              <TableRow>
                <TableCell colSpan={7} className="text-center py-8 text-muted-foreground">
                  Loading...
                </TableCell>
              </TableRow>
            ) : gyms.length === 0 ? (
              <TableRow>
                <TableCell colSpan={7} className="text-center py-8 text-muted-foreground">
                  No gyms yet. Click "Add Gym" to get started.
                </TableCell>
              </TableRow>
            ) : (
              gyms.map((gym) => (
                <TableRow key={gym._id}>
                  <TableCell>
                    <div className="flex items-center gap-3">
                      <GymAvatar
                        name={gym.name}
                        logo={gym.logo}
                        primaryColor={gym.primaryColor}
                        className="h-8 w-8"
                      />
                      <span className="font-medium">{gym.name}</span>
                    </div>
                  </TableCell>
                  <TableCell>{gym.phone || "—"}</TableCell>
                  <TableCell>{gym.email || "—"}</TableCell>
                  <TableCell>{gym.currency}</TableCell>
                  <TableCell>
                    <Badge variant={gym.isActive ? "default" : "secondary"}>
                      {gym.isActive ? "Active" : "Inactive"}
                    </Badge>
                  </TableCell>
                  <TableCell>{new Date(gym.createdAt).toLocaleDateString()}</TableCell>
                  <TableCell className="text-right">
                    <div className="flex items-center justify-end gap-2">
                      <Button size="sm" variant="ghost" onClick={() => openEdit(gym)}>
                        <Pencil className="h-4 w-4" />
                      </Button>
                      <Button
                        size="sm"
                        variant="ghost"
                        onClick={() => handleToggleActive(gym)}
                      >
                        {gym.isActive ? "Deactivate" : "Activate"}
                      </Button>
                      <Button
                        size="sm"
                        variant="ghost"
                        className="text-destructive"
                        onClick={() => setDeleteId(gym._id)}
                      >
                        <Trash2 className="h-4 w-4" />
                      </Button>
                    </div>
                  </TableCell>
                </TableRow>
              ))
            )}
          </TableBody>
        </Table>
      </div>

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
              </div>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div className="col-span-2 space-y-1">
                <Label>Gym Name *</Label>
                <Input value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} placeholder="Fitness First" />
              </div>
              <div className="space-y-1">
                <Label>Phone</Label>
                <Input value={form.phone} onChange={(e) => setForm({ ...form, phone: e.target.value })} placeholder="+91 98765 43210" />
              </div>
              <div className="space-y-1">
                <Label>Email</Label>
                <Input type="email" value={form.email} onChange={(e) => setForm({ ...form, email: e.target.value })} placeholder="gym@example.com" />
              </div>
              <div className="col-span-2 space-y-1">
                <Label>Address</Label>
                <Input value={form.address} onChange={(e) => setForm({ ...form, address: e.target.value })} placeholder="123 Main St" />
              </div>
              <div className="space-y-1">
                <Label>Currency</Label>
                <Input value={form.currency} onChange={(e) => setForm({ ...form, currency: e.target.value })} placeholder="INR" />
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

            {!editGym && (
              <>
                <div className="border-t pt-4">
                  <p className="text-sm font-medium mb-3 text-muted-foreground">Gym Admin Account</p>
                  <div className="grid grid-cols-2 gap-4">
                    <div className="col-span-2 space-y-1">
                      <Label>Admin Name</Label>
                      <Input value={form.adminName} onChange={(e) => setForm({ ...form, adminName: e.target.value })} placeholder="Admin" />
                    </div>
                    <div className="space-y-1">
                      <Label>Admin Email *</Label>
                      <Input type="email" value={form.adminEmail} onChange={(e) => setForm({ ...form, adminEmail: e.target.value })} placeholder="admin@gym.com" />
                    </div>
                    <div className="space-y-1">
                      <Label>Admin Password *</Label>
                      <Input type="password" value={form.adminPassword} onChange={(e) => setForm({ ...form, adminPassword: e.target.value })} placeholder="••••••••" />
                    </div>
                  </div>
                </div>
              </>
            )}
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setDialogOpen(false)}>Cancel</Button>
            <Button onClick={handleSave} disabled={saving}>
              {saving ? "Saving..." : editGym ? "Update Gym" : "Create Gym"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Delete confirmation */}
      <Dialog open={!!deleteId} onOpenChange={() => setDeleteId(null)}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Delete Gym?</DialogTitle>
          </DialogHeader>
          <p className="text-sm text-muted-foreground">
            This will permanently delete the gym and deactivate all its staff. This action cannot be undone.
          </p>
          <DialogFooter>
            <Button variant="outline" onClick={() => setDeleteId(null)}>Cancel</Button>
            <Button variant="destructive" onClick={handleDelete}>Delete</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
