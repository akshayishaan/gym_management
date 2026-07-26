import { Dumbbell } from "lucide-react";
import { GymPickerSheet } from "@/components/layout/GymPickerSheet";

/**
 * Top app bar shown only on tab-root screens (Dashboard/Members/Payments/
 * More). Drill-in pages use StackHeader instead.
 */
export function TopAppBar({ title }: { title: string }) {
  return (
    <header
      className="sticky top-0 z-30 shrink-0 bg-background/80 px-5 pb-3 backdrop-blur-xl"
      style={{ paddingTop: "calc(0.75rem + env(safe-area-inset-top))" }}
    >
      <div className="flex items-center justify-between gap-3">
        <div className="flex items-center gap-2 text-primary">
          <span className="flex h-7 w-7 items-center justify-center rounded-xl bg-primary text-primary-foreground shadow-sm shadow-primary/30">
            <Dumbbell className="h-3.5 w-3.5" />
          </span>
          <span className="text-[10px] font-extrabold uppercase tracking-[0.2em]">Gym Manager</span>
        </div>
        <GymPickerSheet />
      </div>
      <h1 className="mt-2 font-display text-[2rem] font-extrabold leading-none tracking-[-0.045em]">
        {title}
      </h1>
    </header>
  );
}
