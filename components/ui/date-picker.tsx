"use client";

import * as React from "react";
import { format, parseISO, isValid } from "date-fns";
import { CalendarIcon } from "lucide-react";
import { cn } from "@/lib/utils";
import { Button } from "@/components/ui/button";
import { Calendar } from "@/components/ui/calendar";

const START_MONTH = new Date(1950, 0);
const END_MONTH = new Date(new Date().getFullYear() + 10, 11);

interface DatePickerProps {
  /** ISO date string (yyyy-MM-dd) or empty string */
  value: string;
  onChange: (value: string) => void;
  placeholder?: string;
  disabled?: boolean;
  className?: string;
}

export function DatePicker({
  value,
  onChange,
  placeholder = "Pick a date",
  disabled = false,
  className,
}: DatePickerProps) {
  const [open, setOpen] = React.useState(false);
  const containerRef = React.useRef<HTMLDivElement>(null);

  const date = value && isValid(parseISO(value)) ? parseISO(value) : undefined;

  function handleSelect(selected: Date | undefined) {
    onChange(selected ? format(selected, "yyyy-MM-dd") : "");
    setOpen(false);
  }

  // Close when clicking outside
  React.useEffect(() => {
    if (!open) return;
    function handleOutside(e: MouseEvent) {
      if (containerRef.current && !containerRef.current.contains(e.target as Node)) {
        setOpen(false);
      }
    }
    document.addEventListener("mousedown", handleOutside);
    return () => document.removeEventListener("mousedown", handleOutside);
  }, [open]);

  return (
    <div ref={containerRef} className={cn("relative", className)}>
      <Button
        type="button"
        variant="outline"
        disabled={disabled}
        onClick={() => setOpen(o => !o)}
        className={cn(
          "w-full justify-start text-left font-normal",
          !date && "text-muted-foreground"
        )}
      >
        <CalendarIcon className="mr-2 h-4 w-4 shrink-0" />
        {date ? format(date, "dd MMM yyyy") : <span>{placeholder}</span>}
      </Button>

      {open && (
        <div className="absolute top-full left-0 z-50 mt-1 rounded-md border bg-popover shadow-md">
          <Calendar
            mode="single"
            selected={date}
            onSelect={handleSelect}
            captionLayout="dropdown"
            startMonth={START_MONTH}
            endMonth={END_MONTH}
            defaultMonth={date ?? new Date()}
          />
        </div>
      )}
    </div>
  );
}
