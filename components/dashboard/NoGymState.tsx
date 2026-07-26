"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { Building2, Plus } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { GymForm } from "@/components/dashboard/GymForm";
import { useGymSettings } from "@/lib/useGymSettings";

export function NoGymState() {
  const router = useRouter();
  const { switchGym } = useGymSettings();
  const [open, setOpen] = useState(false);

  return (
    <>
      <div className="w-full">
        <Card className="relative w-full overflow-hidden rounded-[2rem] border-0 shadow-card">
          <div className="absolute -right-14 -top-14 h-40 w-40 rounded-full bg-primary/10 blur-2xl" />
          <CardContent className="relative flex flex-col items-center space-y-6 px-6 py-20 text-center">
            <div className="rounded-[1.5rem] bg-primary/10 p-5 ring-1 ring-primary/20">
              <Building2 className="h-10 w-10 text-primary" />
            </div>

            <div className="space-y-2">
              <p className="app-section-label">First things first</p>
              <h2 className="font-display text-2xl font-extrabold tracking-tight">Create your home base</h2>
              <p className="text-sm leading-relaxed text-muted-foreground">
                Create your first gym to start managing members, plans, and payments.
              </p>
            </div>

            <Button onClick={() => setOpen(true)} className="h-12 gap-2 rounded-2xl px-5">
              <Plus className="h-4 w-4" />
              Add Your First Gym
            </Button>
          </CardContent>
        </Card>
      </div>

      <GymForm
        mode="create"
        variant="sheet"
        open={open}
        onOpenChange={setOpen}
        onSuccess={(newGym) => {
          setOpen(false);
          switchGym(newGym._id);
          router.refresh();
        }}
      />
    </>
  );
}
