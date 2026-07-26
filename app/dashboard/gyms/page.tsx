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
import { Fab } from "@/components/ui/fab";
import { StackHeader } from "@/components/layout/StackHeader";
import { GymForm } from "@/components/dashboard/GymForm";
import { Pencil, Building2, MapPin, Phone, Mail, Trash2, Check } from "lucide-react";
import { toast } from "sonner";
import { GymAvatar } from "@/components/ui/gym-avatar";
import { useGyms, useInvalidateGyms, type Gym } from "@/lib/hooks/useGyms";
import { useGymSettings } from "@/lib/useGymSettings";
import { cn } from "@/lib/utils";

export default function GymsPage() {
  const router = useRouter();

  const { data: gyms = [], isLoading } = useGyms();
  const invalidateGyms = useInvalidateGyms();
  const { switchGym, selectedGymId } = useGymSettings();

  const [deleteGym, setDeleteGym] = useState<Gym | null>(null);
  const [deleting, setDeleting] = useState(false);
  const [addOpen, setAddOpen] = useState(false);
  const [editGym, setEditGym] = useState<Gym | null>(null);

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
  };

  return (
    <div className="app-canvas flex min-h-svh flex-col">
      <StackHeader title="My Gyms" />
      <div
        className="app-screen flex-1 space-y-5 px-5 py-5"
        style={{ paddingBottom: "calc(6rem + env(safe-area-inset-bottom))" }}
      >
        <div className="flex items-center justify-between px-1">
          <p className="app-section-label">Your locations</p>
          <p className="text-xs font-semibold text-muted-foreground">{gyms.length} total</p>
        </div>

        {isLoading ? (
          <div className="space-y-3">
            {[1, 2].map((i) => (
              <div key={i} className="h-40 animate-pulse rounded-[2rem] bg-card" />
            ))}
          </div>
        ) : gyms.length === 0 ? (
          <div className="app-surface flex flex-col items-center gap-3 rounded-[2rem] px-6 py-16 text-center">
            <div className="flex h-16 w-16 items-center justify-center rounded-[1.4rem] bg-primary/10 text-primary"><Building2 className="h-7 w-7" /></div>
            <div>
              <h3 className="mb-1 font-medium">No gyms yet</h3>
              <p className="text-sm text-muted-foreground">
                Create your first gym to start managing members and payments.
              </p>
            </div>
          </div>
        ) : (
          <div className="space-y-3">
            {gyms.map((gym) => (
              <Card
                key={gym._id}
                className={cn(
                  "overflow-hidden rounded-[2rem] border-0 shadow-card transition-all",
                  gym._id === selectedGymId && "ring-2 ring-primary/60"
                )}
              >
                <CardContent className="p-5">
                  <div className="flex items-start gap-3">
                    <GymAvatar
                      name={gym.name}
                      logo={gym.logo}
                      primaryColor={gym.primaryColor}
                      className="mt-0.5 h-12 w-12 shrink-0 rounded-2xl"
                    />
                    <div className="min-w-0 flex-1">
                      <div className="mb-1.5 flex flex-wrap items-center gap-1.5">
                        <h3 className="truncate font-display text-base font-bold">{gym.name}</h3>
                        <Badge variant={gym.isActive ? "default" : "secondary"} className="shrink-0 text-xs">
                          {gym.isActive ? "Active" : "Inactive"}
                        </Badge>
                        {gym._id === selectedGymId && (
                          <Badge variant="outline" className="shrink-0 gap-1 border-primary/40 text-xs text-primary">
                            <Check className="h-3 w-3" /> Current
                          </Badge>
                        )}
                      </div>
                      <div className="space-y-1">
                        {gym.address && (
                          <p className="flex min-w-0 items-center gap-1.5 text-xs text-muted-foreground">
                            <MapPin className="h-3 w-3 shrink-0" />
                            <span className="truncate">{gym.address}</span>
                          </p>
                        )}
                        {gym.phone && (
                          <p className="flex min-w-0 items-center gap-1.5 text-xs text-muted-foreground">
                            <Phone className="h-3 w-3 shrink-0" />
                            <span className="truncate">{gym.phone}</span>
                          </p>
                        )}
                        {gym.email && (
                          <p className="flex min-w-0 items-center gap-1.5 text-xs text-muted-foreground">
                            <Mail className="h-3 w-3 shrink-0" />
                            <span className="truncate">{gym.email}</span>
                          </p>
                        )}
                      </div>
                    </div>
                  </div>

                  <div className="mt-3 flex items-center gap-2 border-t pt-3">
                    <Button
                      size="sm"
                      variant={gym._id === selectedGymId ? "secondary" : "outline"}
                      className="flex-1"
                      disabled={gym._id === selectedGymId}
                      onClick={() => handleSwitchToGym(gym._id)}
                    >
                      {gym._id === selectedGymId ? "Current Gym" : "Switch to Gym"}
                    </Button>
                    <Button
                      size="sm"
                      variant="ghost"
                      className="shrink-0"
                      onClick={() => setEditGym(gym)}
                    >
                      <Pencil className="h-4 w-4" />
                    </Button>
                    <Button
                      size="sm"
                      variant="ghost"
                      className="shrink-0 text-muted-foreground hover:bg-destructive/10 hover:text-destructive"
                      onClick={() => setDeleteGym(gym)}
                    >
                      <Trash2 className="h-4 w-4" />
                    </Button>
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>
        )}
      </div>

      <Fab
        onClick={() => setAddOpen(true)}
        style={{ bottom: "calc(1.25rem + env(safe-area-inset-bottom))" }}
      />

      <GymForm
        mode="create"
        variant="sheet"
        open={addOpen}
        onOpenChange={setAddOpen}
        onSuccess={(newGym) => {
          setAddOpen(false);
          switchGym(newGym._id);
        }}
      />

      <GymForm
        mode="edit"
        variant="sheet"
        gym={editGym}
        open={!!editGym}
        onOpenChange={(open) => {
          if (!open) setEditGym(null);
        }}
        onSuccess={() => {
          setEditGym(null);
          router.refresh();
        }}
      />

      {/* ── Delete confirmation ─────────────────────────────────────────────── */}
      <AlertDialog open={!!deleteGym} onOpenChange={(open) => !open && setDeleteGym(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Delete &quot;{deleteGym?.name}&quot;?</AlertDialogTitle>
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
