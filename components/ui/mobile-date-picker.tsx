"use client";

import * as React from "react";
import { CalendarDays, ChevronDown } from "lucide-react";
import { format, isValid, parseISO } from "date-fns";
import { Calendar } from "@/components/ui/calendar";
import { Button } from "@/components/ui/button";
import {
  Sheet,
  SheetContent,
  SheetDescription,
  SheetHeader,
  SheetTitle,
} from "@/components/ui/sheet";
import { cn } from "@/lib/utils";

interface MobileDatePickerProps {
  id?: string;
  value: string;
  onChange: (value: string) => void;
  title: string;
  placeholder?: string;
  disabled?: boolean;
  readOnly?: boolean;
  className?: string;
  variant?: "date" | "birth-date";
}

const now = new Date();

function parseValue(value: string) {
  if (!value) return undefined;
  const parsed = parseISO(value);
  return isValid(parsed) ? parsed : undefined;
}

export function MobileDatePicker({
  id,
  value,
  onChange,
  title,
  placeholder = "Select date",
  disabled = false,
  readOnly = false,
  className,
  variant = "date",
}: MobileDatePickerProps) {
  const [open, setOpen] = React.useState(false);
  const selected = parseValue(value);
  const [draft, setDraft] = React.useState<Date | undefined>(selected);
  const [month, setMonth] = React.useState(selected ?? now);
  const isBirthDate = variant === "birth-date";

  function handleOpenChange(nextOpen: boolean) {
    if (nextOpen) {
      const current = parseValue(value);
      setDraft(current);
      setMonth(current ?? now);
    }
    setOpen(nextOpen);
  }

  function commit(date: Date | undefined) {
    onChange(date ? format(date, "yyyy-MM-dd") : "");
    setOpen(false);
  }

  const startMonth = isBirthDate ? new Date(1920, 0) : new Date(now.getFullYear() - 5, 0);
  const endMonth = isBirthDate ? now : new Date(now.getFullYear() + 10, 11);

  if (readOnly) {
    return (
      <div
        id={id}
        role="textbox"
        aria-readonly="true"
        className={cn(
          "flex h-12 w-full items-center gap-3 rounded-2xl border border-border/60 bg-muted/60 px-4 text-base text-muted-foreground",
          className
        )}
      >
        <CalendarDays className="h-4 w-4 shrink-0" />
        <span className="min-w-0 flex-1 truncate">
          {selected ? format(selected, "dd MMM yyyy") : placeholder}
        </span>
        <span className="text-[10px] font-bold uppercase tracking-wider">Calculated</span>
      </div>
    );
  }

  return (
    <Sheet open={open} onOpenChange={handleOpenChange} modal>
      <button
        id={id}
        type="button"
        disabled={disabled}
        aria-haspopup="dialog"
        aria-expanded={open}
        onClick={() => handleOpenChange(true)}
        className={cn(
          "flex h-12 w-full items-center gap-3 rounded-2xl border border-border/70 bg-card px-4 text-left text-base shadow-[0_1px_0_hsl(var(--foreground)/0.03)] transition-all active:scale-[0.99] focus-visible:border-primary/40 focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-primary/10 disabled:pointer-events-none disabled:opacity-50",
          !selected && "text-muted-foreground/75",
          className
        )}
      >
        <CalendarDays className="h-4 w-4 shrink-0 text-primary" />
        <span className="min-w-0 flex-1 truncate">
          {selected ? format(selected, "dd MMM yyyy") : placeholder}
        </span>
        <ChevronDown className="h-4 w-4 shrink-0 text-muted-foreground" />
      </button>

      <SheetContent side="bottom" className="flex max-h-[92svh] flex-col gap-0 rounded-t-[2rem] p-0">
        <div className="mx-auto mt-2.5 h-1.5 w-10 shrink-0 rounded-full bg-muted" />
        <SheetHeader className="px-5 pb-3 pt-5 text-left">
          <SheetDescription className="app-section-label">Select date</SheetDescription>
          <SheetTitle>{title}</SheetTitle>
          {draft && (
            <p className="text-sm font-semibold text-primary">{format(draft, "EEEE, dd MMMM yyyy")}</p>
          )}
        </SheetHeader>

        <div className="overflow-y-auto px-4 pb-3">
          <Calendar
            mode="single"
            selected={draft}
            onSelect={setDraft}
            month={month}
            onMonthChange={setMonth}
            captionLayout={isBirthDate ? "dropdown" : "label"}
            reverseYears={isBirthDate}
            startMonth={startMonth}
            endMonth={endMonth}
            disabled={isBirthDate ? { after: now } : undefined}
            showOutsideDays
            fixedWeeks
          />
        </div>

        <div
          className="grid shrink-0 grid-cols-2 gap-3 border-t border-border/60 bg-card/95 px-5 pt-3 backdrop-blur"
          style={{ paddingBottom: "calc(1rem + env(safe-area-inset-bottom))" }}
        >
          {isBirthDate ? (
            <Button variant="outline" onClick={() => commit(undefined)} disabled={!value}>
              Clear
            </Button>
          ) : (
            <Button
              variant="outline"
              onClick={() => {
                setDraft(now);
                setMonth(now);
              }}
            >
              Today
            </Button>
          )}
          <Button onClick={() => commit(draft)} disabled={!draft}>
            Use this date
          </Button>
        </div>
      </SheetContent>
    </Sheet>
  );
}
