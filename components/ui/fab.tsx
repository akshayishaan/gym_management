import { Plus } from "lucide-react";
import { cn } from "@/lib/utils";
import type { ButtonHTMLAttributes, ElementType, CSSProperties } from "react";

interface FabProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  icon?: ElementType;
}

/** Floating action button for primary create actions on list screens. */
export function Fab({ icon: Icon = Plus, className, style, ...props }: FabProps) {
  const fabStyle: CSSProperties = {
    bottom: "calc(5.75rem + env(safe-area-inset-bottom))",
    ...style,
  };

  return (
    <button
      type="button"
      aria-label="Add"
      style={fabStyle}
      className={cn(
        "fixed right-5 z-30 flex h-[3.75rem] w-[3.75rem] items-center justify-center rounded-[1.35rem] border border-primary-foreground/20 bg-primary text-primary-foreground shadow-xl shadow-primary/30 transition-all active:scale-90",
        className
      )}
      {...props}
    >
      <Icon className="h-6 w-6" />
    </button>
  );
}
