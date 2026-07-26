import { Dumbbell, Smartphone } from "lucide-react";

export const metadata = {
  title: "Please use a mobile device",
};

export default function UnsupportedDevicePage() {
  return (
    <div className="app-canvas flex min-h-svh items-center justify-center px-6">
      <div className="app-surface relative w-full max-w-sm overflow-hidden rounded-[2rem] p-8 text-center">
        <div className="absolute -right-16 -top-16 h-40 w-40 rounded-full bg-primary/15 blur-2xl" />
        <div className="relative">
          <div className="mx-auto flex h-12 w-12 items-center justify-center rounded-2xl bg-foreground text-background">
            <Dumbbell className="h-5 w-5" />
          </div>
          <div className="mx-auto mt-8 flex h-20 w-20 items-center justify-center rounded-[1.75rem] bg-primary/10 text-primary">
            <Smartphone className="h-9 w-9" />
          </div>
          <div className="mt-6 space-y-2">
            <p className="app-section-label">Gym Manager</p>
            <h1 className="font-display text-2xl font-extrabold tracking-tight text-foreground">
              Made for your phone
            </h1>
            <p className="mx-auto max-w-xs text-sm leading-6 text-muted-foreground">
              Open Gym Manager on a mobile device to use the training-floor experience.
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}
