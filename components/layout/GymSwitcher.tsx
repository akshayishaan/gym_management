"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { ChevronsUpDown, Plus, Check } from "lucide-react";
import { cn } from "@/lib/utils";
import { Button } from "@/components/ui/button";
import {
  Popover,
  PopoverContent,
  PopoverTrigger,
} from "@/components/ui/popover";
import {
  Command,
  CommandEmpty,
  CommandGroup,
  CommandInput,
  CommandItem,
  CommandList,
  CommandSeparator,
} from "@/components/ui/command";
import { GymAvatar } from "@/components/ui/gym-avatar";
import { useSidebar } from "@/components/ui/sidebar";
import { toast } from "sonner";
import { Skeleton } from "@/components/ui/skeleton";
import { useGyms } from "@/lib/hooks/useGyms";
import { useGymSettings } from "@/lib/useGymSettings";
import { GymFormDialog } from "@/components/dashboard/GymFormDialog";

export function GymSwitcher() {
  const router = useRouter();
  const { state } = useSidebar();
  const [open, setOpen] = useState(false);
  const [gymFormOpen, setGymFormOpen] = useState(false);

  // Shared cache — GymGuard and gyms/page draw from the same ["gyms"] entry
  const { data: gyms = [], isLoading } = useGyms();

  // selectedGymId and switchGym come from context (persisted in cookie,
  // shared across all components — switching from the gyms page updates here too)
  const { selectedGymId, switchGym } = useGymSettings();
  const selectedGym = gyms.find((g) => g._id === selectedGymId) ?? gyms[0] ?? null;

  const handleSelectGym = (gymId: string) => {
    if (gymId === selectedGymId) {
      setOpen(false);
      return;
    }
    switchGym(gymId);
    setOpen(false);
    router.refresh();
    toast.success(`Switched to ${gyms.find((g) => g._id === gymId)?.name || "gym"}`);
  };

  // ── Derived content (avoids multiple early returns that would prevent
  //    GymFormDialog from always being in the tree) ────────────────────────
  let gymContent: React.ReactNode;

  if (isLoading) {
    gymContent = (
      <div className="flex items-center gap-2 px-2 py-2">
        <Skeleton className="h-6 w-6 rounded-full shrink-0" />
        {state === "expanded" && (
          <div className="flex-1 space-y-1.5">
            <Skeleton className="h-3.5 w-24" />
          </div>
        )}
      </div>
    );
  } else if (gyms.length === 0) {
    gymContent = (
      <Button
        variant="outline"
        className="w-full justify-start gap-2"
        onClick={() => setGymFormOpen(true)}
      >
        <Plus className="h-4 w-4" />
        {state === "expanded" && <span>Add Your First Gym</span>}
      </Button>
    );
  } else {
    gymContent = (
      <Popover open={open} onOpenChange={setOpen}>
        <PopoverTrigger asChild>
          <Button
            variant="ghost"
            size="sm"
            className={cn(
              "w-full justify-start gap-2 px-2 py-2 h-auto",
              state === "collapsed" && "justify-center px-0"
            )}
            disabled={isLoading}
          >
            {selectedGym ? (
              <GymAvatar
                name={selectedGym.name}
                logo={selectedGym.logo}
                primaryColor={selectedGym.primaryColor}
                className="h-6 w-6"
              />
            ) : (
              <div className="h-6 w-6 rounded-full bg-muted flex items-center justify-center text-xs font-bold">
                ?
              </div>
            )}
            {state === "expanded" && (
              <>
                <span className="flex-1 text-left text-sm font-medium truncate">
                  {selectedGym?.name || "Select Gym"}
                </span>
                <ChevronsUpDown className="h-3.5 w-3.5 text-muted-foreground shrink-0" />
              </>
            )}
          </Button>
        </PopoverTrigger>
        <PopoverContent className="w-64 p-0" align="start">
          <Command>
            <CommandInput placeholder="Search gyms..." />
            <CommandList>
              <CommandEmpty>No gyms found.</CommandEmpty>
              <CommandGroup heading="Your Gyms">
                {gyms.map((gym) => (
                  <CommandItem
                    key={gym._id}
                    value={gym.name}
                    onSelect={() => handleSelectGym(gym._id)}
                    className="gap-2 cursor-pointer"
                  >
                    <GymAvatar
                      name={gym.name}
                      logo={gym.logo}
                      primaryColor={gym.primaryColor}
                      className="h-6 w-6"
                    />
                    <span className="flex-1 truncate">{gym.name}</span>
                    {gym._id === selectedGym?._id && (
                      <Check className="h-4 w-4 text-primary shrink-0" />
                    )}
                  </CommandItem>
                ))}
              </CommandGroup>
              <CommandSeparator />
              <CommandGroup>
                <CommandItem
                  onSelect={() => {
                    setOpen(false);
                    setGymFormOpen(true);
                  }}
                  className="gap-2 cursor-pointer"
                >
                  <Plus className="h-4 w-4" />
                  <span>Add New Gym</span>
                </CommandItem>
              </CommandGroup>
            </CommandList>
          </Command>
        </PopoverContent>
      </Popover>
    );
  }

  return (
    <>
      {gymContent}
      <GymFormDialog
        open={gymFormOpen}
        onOpenChange={setGymFormOpen}
        onSuccess={(newGym) => {
          switchGym(newGym._id);
          router.refresh();
        }}
      />
    </>
  );
}
