"use client";

import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { cn } from "@/lib/utils";

interface GymAvatarProps {
  name: string;
  logo?: string | null;
  primaryColor?: string | null;
  className?: string;
}

/**
 * Displays a gym logo or falls back to the first letter of the gym name
 * with the gym's primaryColor as background.
 */
export function GymAvatar({ name, logo, primaryColor, className }: GymAvatarProps) {
  const initial = name?.charAt(0)?.toUpperCase() || "G";
  const bgColor = primaryColor || "#f97316"; // default orange

  return (
    <Avatar className={cn("border-2 border-sidebar-border shadow-sm", className)}>
      {logo && <AvatarImage src={logo} alt={name} />}
      <AvatarFallback
        style={{ backgroundColor: bgColor }}
        className="text-white font-bold text-xs"
      >
        {initial}
      </AvatarFallback>
    </Avatar>
  );
}
