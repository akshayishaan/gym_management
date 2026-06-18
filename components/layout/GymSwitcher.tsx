"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { useSession } from "next-auth/react";
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

interface Gym {
  _id: string;
  name: string;
  logo?: string;
  primaryColor?: string;
}

export function GymSwitcher() {
  const { data: session } = useSession();
  const router = useRouter();
  const { state } = useSidebar();
  const [gyms, setGyms] = useState<Gym[]>([]);
  const [selectedGymId, setSelectedGymId] = useState<string | null>(null);
  const [open, setOpen] = useState(false);
  const [loading, setLoading] = useState(false);

  const role = (session?.user as { role?: string })?.role;
  const isSuperAdmin = role === "superadmin";
  const gymIds = (session?.user as { gymIds?: string[] })?.gymIds ?? [];

  // Fetch gyms this admin has access to
  useEffect(() => {
    if (isSuperAdmin) return; // Superadmins don't switch gyms
    if (gymIds.length === 0) return;

    fetch("/api/gyms")
      .then((r) => r.json())
      .then((data) => {
        const gymList = Array.isArray(data) ? data : [];
        setGyms(gymList);
        // Set initial selected gym from cookie
        const cookieGymId = document.cookie
          .split("; ")
          .find((row) => row.startsWith("selectedGymId="))
          ?.split("=")[1];
        if (cookieGymId) {
          setSelectedGymId(cookieGymId);
        } else if (gymList.length > 0) {
          setSelectedGymId(gymList[0]._id);
        }
      })
      .catch(() => {});
  }, [isSuperAdmin, gymIds.length]);

  const selectedGym = gyms.find((g) => g._id === selectedGymId);

  const handleSelectGym = async (gymId: string) => {
    if (gymId === selectedGymId) {
      setOpen(false);
      return;
    }

    setLoading(true);
    try {
      const res = await fetch("/api/auth/select-gym", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ gymId }),
      });

      if (!res.ok) {
        const data = await res.json();
        throw new Error(data.error || "Failed to switch gym");
      }

      setSelectedGymId(gymId);
      setOpen(false);
      // Refresh the page to reload all data for the new gym
      router.refresh();
      toast.success(`Switched to ${gyms.find((g) => g._id === gymId)?.name || "gym"}`);
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "Failed to switch gym");
    } finally {
      setLoading(false);
    }
  };

  // Superadmins don't see the gym switcher
  if (isSuperAdmin) {
    return (
      <div className="flex items-center gap-3 px-2 py-2">
        <div className="bg-gradient-to-br from-orange-500 to-red-500 rounded-xl p-2 shrink-0 shadow-lg shadow-orange-500/20">
          <div className="h-4 w-4 text-white flex items-center justify-center text-xs font-bold">S</div>
        </div>
        {state === "expanded" && (
          <span className="font-bold text-sm truncate">SuperAdmin</span>
        )}
      </div>
    );
  }

  // No gyms yet
  if (gyms.length === 0 && !loading) {
    return (
      <Button
        variant="outline"
        className="w-full justify-start gap-2"
        onClick={() => router.push("/dashboard/gyms")}
      >
        <Plus className="h-4 w-4" />
        {state === "expanded" && <span>Add Your First Gym</span>}
      </Button>
    );
  }

  return (
    <Popover open={open} onOpenChange={setOpen}>
      <PopoverTrigger asChild>
        <Button
          variant="ghost"
          size="sm"
          className={cn(
            "w-full justify-start gap-2 px-2 py-2 h-auto",
            state === "collapsed" && "justify-center px-0"
          )}
          disabled={loading}
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
                  {gym._id === selectedGymId && (
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
                  router.push("/dashboard/gyms");
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
