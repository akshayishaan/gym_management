"use client";

import { Sheet, SheetContent, SheetHeader, SheetTitle, SheetDescription } from "@/components/ui/sheet";
import { cn } from "@/lib/utils";

interface BottomSheetFormProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  title: string;
  description?: string;
  children: React.ReactNode;
  footer: React.ReactNode;
  className?: string;
}

/**
 * Shared sticky-footer wrapper for short bottom-sheet forms (Record Payment,
 * filters, Plan form) — mirrors the shrink-0 header / flex-1 overflow-y-auto
 * body / shrink-0 footer pattern used by the full-screen forms.
 */
export function BottomSheetForm({
  open,
  onOpenChange,
  title,
  description,
  children,
  footer,
  className,
}: BottomSheetFormProps) {
  return (
    <Sheet open={open} onOpenChange={onOpenChange}>
      <SheetContent
        side="bottom"
        className={cn("flex max-h-[92svh] flex-col gap-0 rounded-t-[2rem] p-0", className)}
      >
        <div className="mx-auto mt-2.5 h-1.5 w-10 shrink-0 rounded-full bg-muted" />
        <SheetHeader className="shrink-0 px-5 pb-4 pt-5 text-left">
          <SheetTitle>{title}</SheetTitle>
          {description && <SheetDescription>{description}</SheetDescription>}
        </SheetHeader>
        <div className="hide-scrollbar flex-1 overflow-y-auto px-5">{children}</div>
        <div
          className="shrink-0 border-t border-border/60 bg-card/95 px-5 py-3 backdrop-blur"
          style={{ paddingBottom: "calc(1rem + env(safe-area-inset-bottom))" }}
        >
          {footer}
        </div>
      </SheetContent>
    </Sheet>
  );
}
