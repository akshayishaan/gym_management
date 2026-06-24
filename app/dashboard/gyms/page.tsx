"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { Button } from "@/components/ui/button";
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
import { Card, CardContent } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Plus, Pencil, Building2, MapPin, Phone, Mail, Trash2, Check } from "lucide-react";
import { motion } from "framer-motion";
import { toast } from "sonner";
import { PageHeader } from "@/components/layout/PageHeader";
import { GymAvatar } from "@/components/ui/gym-avatar";
import { useGyms, useInvalidateGyms, type Gym } from "@/lib/hooks/useGyms";
import { useGymSettings } from "@/lib/useGymSettings";
import { GymFormDialog } from "@/components/dashboard/GymFormDialog";
import { cn } from "@/lib/utils";

export default function GymsPage() {
  const router = useRouter();

  const { data: gyms = [], isLoading } = useGyms();
  const invalidateGyms = useInvalidateGyms();
  const { switchGym, selectedGymId } = useGymSettings();

  // ── Form dialog (create + edit) ───────────────────────────────────────────
  const [dialogOpen, setDialogOpen] = useState(false);
  const [editGym, setEditGym] = useState<Gym | null>(null);

  const openCreate = () => { setEditGym(null); setDialogOpen(true); };
  const openEdit = (gym: Gym) => { setEditGym(gym); setDialogOpen(true); };

  // ── Delete dialog ─────────────────────────────────────────────────────────
  const [deleteGym, setDeleteGym] = useState<Gym | null>(null);
  const [deleting, setDeleting] = useState(false);

  const handleDeleteGym = async () => {
    if (!deleteGym) return;
    setDeleting(true);
    try {
      const res = await fetch(`/api/gyms/${deleteGym._id}`, { method: "DELETE" });
      if (!res.ok) {
        const data = await res.json();
        throw new Error(data.error || "Failed to delete gym");
      }
      toast.success(`Gym "${deleteGym.name}" deleted`);
      setDeleteGym(null);
      await invalidateGyms();
      router.refresh();
    } catch (e) {
      toast.error(e instanceof Error ? e.message : "Failed to delete gym");
    } finally {
      setDeleting(false);
    }
  };

  const handleSwitchToGym = (gymId: string) => {
    switchGym(gymId);
    toast.success("Gym switched!");
    router.refresh();
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

      {isLoading ? (
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
              <Card className={cn(
                "border-0 shadow-card hover:shadow-card-hover transition-all duration-200 overflow-hidden",
                gym._id === selectedGymId && "ring-2 ring-primary/50"
              )}>
                <CardContent className="p-5">
                  {/* Header: avatar + name + badges */}
                  <div className="flex items-start gap-3">
                    <GymAvatar
                      name={gym.name}
                      logo={gym.logo}
                      primaryColor={gym.primaryColor}
                      className="h-10 w-10 shrink-0 mt-0.5"
                    />
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-1.5 flex-wrap mb-2">
                        <h3 className="font-semibold text-sm truncate">{gym.name}</h3>
                        <Badge variant={gym.isActive ? "default" : "secondary"} className="text-xs shrink-0">
                          {gym.isActive ? "Active" : "Inactive"}
                        </Badge>
                        {gym._id === selectedGymId && (
                          <Badge variant="outline" className="text-xs shrink-0 gap-1 text-primary border-primary/40">
                            <Check className="h-3 w-3" /> Current
                          </Badge>
                        )}
                      </div>

                      {/* Contact details — one per line so nothing overflows */}
                      <div className="space-y-1">
                        {gym.address && (
                          <p className="flex items-center gap-1.5 text-xs text-muted-foreground min-w-0">
                            <MapPin className="h-3 w-3 shrink-0" />
                            <span className="truncate">{gym.address}</span>
                          </p>
                        )}
                        {gym.phone && (
                          <p className="flex items-center gap-1.5 text-xs text-muted-foreground min-w-0">
                            <Phone className="h-3 w-3 shrink-0" />
                            <span className="truncate">{gym.phone}</span>
                          </p>
                        )}
                        {gym.email && (
                          <p className="flex items-center gap-1.5 text-xs text-muted-foreground min-w-0">
                            <Mail className="h-3 w-3 shrink-0" />
                            <span className="truncate">{gym.email}</span>
                          </p>
                        )}
                      </div>
                    </div>
                  </div>

                  {/* Actions */}
                  <div className="flex items-center gap-2 mt-4 pt-3 border-t">
                    <Button
                      size="sm"
                      variant={gym._id === selectedGymId ? "secondary" : "outline"}
                      className="flex-1"
                      disabled={gym._id === selectedGymId}
                      onClick={() => handleSwitchToGym(gym._id)}
                    >
                      {gym._id === selectedGymId ? "Current Gym" : "Switch to Gym"}
                    </Button>
                    <Button size="sm" variant="ghost" className="shrink-0" onClick={() => openEdit(gym)}>
                      <Pencil className="h-4 w-4" />
                    </Button>
                    <Button
                      size="sm"
                      variant="ghost"
                      className="shrink-0 text-muted-foreground hover:text-destructive hover:bg-destructive/10"
                      onClick={() => setDeleteGym(gym)}
                    >
                      <Trash2 className="h-4 w-4" />
                    </Button>
                  </div>
                </CardContent>
              </Card>
            </motion.div>
          ))}
        </div>
      )}

      {/* ── Shared create/edit dialog ───────────────────────────────────────── */}
      <GymFormDialog
        open={dialogOpen}
        onOpenChange={setDialogOpen}
        gym={editGym}
        onSuccess={() => router.refresh()}
      />

      {/* ── Delete confirmation ─────────────────────────────────────────────── */}
      <AlertDialog open={!!deleteGym} onOpenChange={(open) => !open && setDeleteGym(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Delete "{deleteGym?.name}"?</AlertDialogTitle>
            <AlertDialogDescription>
              This will permanently delete this gym and all its members, plans, payments, and
              activity logs. This action cannot be undone.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel disabled={deleting}>Cancel</AlertDialogCancel>
            <AlertDialogAction
              onClick={handleDeleteGym}
              disabled={deleting}
              className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
            >
              {deleting ? "Deleting..." : "Delete Gym"}
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  );
}
