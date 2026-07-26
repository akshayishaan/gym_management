"use client";

import { useState } from "react";
import { ChevronDown, Plus, Check } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Sheet, SheetContent, SheetHeader, SheetTitle } from "@/components/ui/sheet";
import {
  Command,
  CommandEmpty,
  CommandGroup,
  CommandInput,
  CommandItem,
  CommandList,
} from "@/components/ui/command";
import { GymAvatar } from "@/components/ui/gym-avatar";
import { Skeleton } from "@/components/ui/skeleton";
import { GymForm } from "@/components/dashboard/GymForm";
import { useGyms } from "@/lib/hooks/useGyms";
import { useGymSettings } from "@/lib/useGymSettings";
import { cn } from "@/lib/utils";

/**
 * Tap-to-switch gym picker, triggered from the top app bar. Replaces the old
 * sidebar-popover GymSwitcher with a bottom sheet — same underlying
 * useGyms()/useGymSettings() data and switchGym() cookie behavior.
 */
export function GymPickerSheet() {
  const [open, setOpen] = useState(false);
  const [addGymOpen, setAddGymOpen] = useState(false);

  const { data: gyms = [], isLoading } = useGyms();
  const { selectedGymId, switchGym } = useGymSettings();
  const selectedGym = gyms.find((g) => g._id === selectedGymId) ?? gyms[0] ?? null;

  function handleSelectGym(gymId: string) {
    if (gymId !== selectedGymId) {
      switchGym(gymId);
    }
    setOpen(false);
  }

  function handleAddGymSuccess(newGym: { _id: string }) {
    setAddGymOpen(false);
    switchGym(newGym._id);
  }

  if (isLoading) {
    return <Skeleton className="h-8 w-8 rounded-full" />;
  }

  if (gyms.length === 0) {
    return (
      <>
        <Button variant="ghost" size="icon" onClick={() => setAddGymOpen(true)}>
          <Plus className="h-5 w-5" />
        </Button>
        <GymForm
          mode="create"
          variant="sheet"
          open={addGymOpen}
          onOpenChange={setAddGymOpen}
          onSuccess={handleAddGymSuccess}
        />
      </>
    );
  }

  return (
    <>
      <button
        type="button"
        aria-label="Switch gym"
        aria-expanded={open}
        onClick={() => setOpen(true)}
        className="flex max-w-[11rem] items-center gap-2 rounded-2xl border border-border/60 bg-card py-1.5 pl-1.5 pr-2.5 shadow-card transition-all active:scale-[0.98] active:bg-muted"
      >
        {selectedGym ? (
          <GymAvatar
            name={selectedGym.name}
            logo={selectedGym.logo}
            primaryColor={selectedGym.primaryColor}
            className="h-8 w-8"
          />
        ) : (
          <div className="h-8 w-8 rounded-full bg-muted" />
        )}
        <span className="min-w-0 flex-1 truncate text-left text-xs font-bold">
          {selectedGym?.name ?? "Choose gym"}
        </span>
        <ChevronDown className="h-3.5 w-3.5 shrink-0 text-muted-foreground" />
      </button>

      <Sheet open={open} onOpenChange={setOpen}>
        <SheetContent side="bottom" className="flex max-h-[78svh] flex-col gap-0 rounded-t-[2rem] p-0">
          <div className="mx-auto mt-2.5 h-1.5 w-10 rounded-full bg-muted" />
          <SheetHeader className="px-5 pb-2 pt-5 text-left">
            <SheetTitle>Switch Gym</SheetTitle>
          </SheetHeader>
          <Command
            key={selectedGym?._id ?? "no-active-gym"}
            defaultValue={selectedGym?._id}
            className="flex-1 overflow-hidden bg-transparent px-2"
          >
            <CommandInput placeholder="Search gyms..." />
            <CommandList className="max-h-[50vh]">
              <CommandEmpty>No gyms found.</CommandEmpty>
              <CommandGroup heading="Your Gyms">
                {gyms.map((gym) => {
                  const isActive = gym._id === selectedGym?._id;
                  return (
                    <CommandItem
                      key={gym._id}
                      value={gym._id}
                      keywords={[gym.name]}
                      aria-current={isActive ? "true" : undefined}
                      onSelect={() => handleSelectGym(gym._id)}
                      className={cn(
                        "my-1 gap-3 rounded-2xl py-3 data-[selected=true]:bg-transparent data-[selected=true]:text-foreground data-[selected=true]:ring-2 data-[selected=true]:ring-primary/25",
                        isActive && "bg-primary/10 text-primary data-[selected=true]:bg-primary/10 data-[selected=true]:text-primary"
                      )}
                    >
                      <GymAvatar
                        name={gym.name}
                        logo={gym.logo}
                        primaryColor={gym.primaryColor}
                        className="h-8 w-8"
                      />
                      <span className={cn("flex-1 truncate text-base", isActive && "font-bold")}>
                        {gym.name}
                      </span>
                      {isActive && <Check className="h-4 w-4 shrink-0 text-primary" />}
                    </CommandItem>
                  );
                })}
              </CommandGroup>
            </CommandList>
          </Command>
          <div
            className="border-t p-3"
            style={{ paddingBottom: "calc(0.75rem + env(safe-area-inset-bottom))" }}
          >
            <Button
              variant="outline"
              className="w-full gap-2"
              onClick={() => {
                setOpen(false);
                setAddGymOpen(true);
              }}
            >
              <Plus className="h-4 w-4" /> Add New Gym
            </Button>
          </div>
        </SheetContent>
      </Sheet>

      <GymForm
        mode="create"
        variant="sheet"
        open={addGymOpen}
        onOpenChange={setAddGymOpen}
        onSuccess={handleAddGymSuccess}
      />
    </>
  );
}
