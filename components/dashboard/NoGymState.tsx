"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { Building2, Plus } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { GymFormDialog } from "@/components/dashboard/GymFormDialog";
import { useGymSettings } from "@/lib/useGymSettings";

export function NoGymState() {
  const router = useRouter();
  const { switchGym } = useGymSettings();
  const [open, setOpen] = useState(false);

  return (
    <>
      <div className="w-full">
        <Card className="w-full border-0 shadow-card">
          <CardContent className="flex flex-col items-center text-center py-24 space-y-6">
            <div className="rounded-2xl bg-primary/10 p-5 ring-1 ring-primary/20">
              <Building2 className="h-10 w-10 text-primary" />
            </div>

            <div className="space-y-2">
              <h2 className="text-xl font-semibold tracking-tight">No gym yet</h2>
              <p className="text-sm text-muted-foreground leading-relaxed">
                Create your first gym to start managing members, plans, and payments.
              </p>
            </div>

            <Button onClick={() => setOpen(true)} className="gap-2">
              <Plus className="h-4 w-4" />
              Add Your First Gym
            </Button>
          </CardContent>
        </Card>
      </div>

      <GymFormDialog
        open={open}
        onOpenChange={setOpen}
        onSuccess={(newGym) => {
          switchGym(newGym._id);
          router.refresh();
        }}
      />
    </>
  );
}
