"use client";

import * as React from "react";
import { ChevronDown, ChevronLeft, ChevronRight } from "lucide-react";
import { DayButton, DayPicker, getDefaultClassNames } from "react-day-picker";
import { Button, buttonVariants } from "@/components/ui/button";
import { cn } from "@/lib/utils";

type CalendarProps = React.ComponentProps<typeof DayPicker> & {
  buttonVariant?: React.ComponentProps<typeof Button>["variant"];
};

export function Calendar({
  className,
  classNames,
  showOutsideDays = true,
  captionLayout = "label",
  buttonVariant = "ghost",
  components,
  formatters,
  ...props
}: CalendarProps) {
  const defaults = getDefaultClassNames();

  return (
    <DayPicker
      showOutsideDays={showOutsideDays}
      captionLayout={captionLayout}
      className={cn("w-full bg-transparent [--cell-size:2.65rem]", className)}
      formatters={{
        formatMonthDropdown: (date) => date.toLocaleString("default", { month: "short" }),
        ...formatters,
      }}
      classNames={{
        root: cn("mx-auto w-full max-w-[22rem]", defaults.root),
        months: cn("relative flex w-full flex-col", defaults.months),
        month: cn("flex w-full flex-col gap-3", defaults.month),
        nav: cn(
          "pointer-events-none absolute inset-x-0 top-0 z-10 flex w-full items-center justify-between",
          defaults.nav
        ),
        button_previous: cn(
          buttonVariants({ variant: buttonVariant }),
          "pointer-events-auto h-10 w-10 rounded-2xl p-0 aria-disabled:opacity-30",
          defaults.button_previous
        ),
        button_next: cn(
          buttonVariants({ variant: buttonVariant }),
          "pointer-events-auto h-10 w-10 rounded-2xl p-0 aria-disabled:opacity-30",
          defaults.button_next
        ),
        month_caption: cn(
          "flex h-10 w-full items-center justify-center px-11",
          defaults.month_caption
        ),
        caption_label: cn(
          "font-display text-sm font-extrabold tracking-tight",
          captionLayout !== "label" &&
            "flex h-9 items-center gap-1 rounded-xl border border-border/60 bg-muted/60 px-2 [&>svg]:h-3.5 [&>svg]:w-3.5 [&>svg]:text-muted-foreground",
          defaults.caption_label
        ),
        dropdowns: cn(
          "relative z-20 flex h-10 w-full items-center justify-center gap-2 text-sm font-bold",
          defaults.dropdowns
        ),
        dropdown_root: cn("relative z-20 rounded-xl", defaults.dropdown_root),
        dropdown: cn("absolute inset-0 z-20 cursor-pointer bg-popover opacity-0", defaults.dropdown),
        month_grid: cn("w-full border-collapse", defaults.month_grid),
        weekdays: cn("flex", defaults.weekdays),
        weekday: cn(
          "flex-1 select-none py-2 text-center text-[10px] font-extrabold uppercase tracking-wider text-muted-foreground",
          defaults.weekday
        ),
        weeks: cn("block", defaults.weeks),
        week: cn("mt-1 flex w-full", defaults.week),
        day: cn("relative aspect-square h-full w-full flex-1 p-0 text-center", defaults.day),
        today: cn("rounded-2xl bg-primary/10 text-primary", defaults.today),
        outside: cn("text-muted-foreground/35", defaults.outside),
        disabled: cn("pointer-events-none opacity-25", defaults.disabled),
        hidden: cn("invisible", defaults.hidden),
        ...classNames,
      }}
      components={{
        Chevron: ({ className: chevronClassName, orientation, ...chevronProps }) => {
          if (orientation === "left") {
            return <ChevronLeft className={cn("h-4 w-4", chevronClassName)} {...chevronProps} />;
          }
          if (orientation === "right") {
            return <ChevronRight className={cn("h-4 w-4", chevronClassName)} {...chevronProps} />;
          }
          return <ChevronDown className={cn("h-4 w-4", chevronClassName)} {...chevronProps} />;
        },
        DayButton: CalendarDayButton,
        ...components,
      }}
      {...props}
    />
  );
}

function CalendarDayButton({
  className,
  day,
  modifiers,
  ...props
}: React.ComponentProps<typeof DayButton>) {
  const buttonRef = React.useRef<HTMLButtonElement>(null);

  React.useEffect(() => {
    if (modifiers.focused) buttonRef.current?.focus();
  }, [modifiers.focused]);

  return (
    <Button
      ref={buttonRef}
      variant="ghost"
      size="icon"
      data-selected={modifiers.selected}
      className={cn(
        "aspect-square h-auto min-h-10 w-full rounded-2xl p-0 text-sm font-bold shadow-none data-[selected=true]:bg-primary data-[selected=true]:text-primary-foreground data-[selected=true]:shadow-md data-[selected=true]:shadow-primary/20",
        className
      )}
      {...props}
    />
  );
}
