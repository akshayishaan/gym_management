"use client";

import { useState } from "react";
import { signIn } from "next-auth/react";
import { useRouter } from "next/navigation";
import { toast } from "sonner";
import { Dumbbell, ArrowUpRight } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";

export default function LoginPage() {
  const router = useRouter();
  const [tab, setTab] = useState<"signin" | "signup">("signin");

  // Sign in state
  const [loginEmail, setLoginEmail] = useState("");
  const [loginPassword, setLoginPassword] = useState("");
  const [loginLoading, setLoginLoading] = useState(false);

  // Sign up state
  const [signupName, setSignupName] = useState("");
  const [signupEmail, setSignupEmail] = useState("");
  const [signupPassword, setSignupPassword] = useState("");
  const [signupConfirm, setSignupConfirm] = useState("");
  const [signupLoading, setSignupLoading] = useState(false);

  async function handleSignIn(e: React.FormEvent) {
    e.preventDefault();
    setLoginLoading(true);
    const res = await signIn("credentials", { email: loginEmail, password: loginPassword, redirect: false });
    setLoginLoading(false);
    if (res?.error) {
      toast.error("Invalid email or password");
    } else {
      router.push("/dashboard");
    }
  }

  async function handleSignUp(e: React.FormEvent) {
    e.preventDefault();
    if (signupPassword !== signupConfirm) {
      toast.error("Passwords do not match");
      return;
    }
    setSignupLoading(true);
    try {
      const res = await fetch("/api/auth/signup", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ name: signupName, email: signupEmail, password: signupPassword }),
      });
      const data = await res.json();
      if (!res.ok) {
        toast.error(typeof data.error === "string" ? data.error : "Failed to create account");
      } else {
        toast.success("Account created! Please sign in.");
        setLoginEmail(signupEmail);
        setLoginPassword("");
        setTab("signin");
      }
    } catch {
      toast.error("Something went wrong");
    } finally {
      setSignupLoading(false);
    }
  }

  return (
    <div className="app-canvas relative min-h-svh overflow-hidden">
      <div className="pointer-events-none absolute -right-24 -top-16 h-72 w-72 rounded-full bg-primary/15 blur-3xl" />
      <div className="pointer-events-none absolute -left-24 top-1/3 h-56 w-56 rounded-full bg-accent blur-3xl" />

      <div
        className="relative mx-auto flex min-h-svh w-full max-w-md flex-col px-5"
        style={{
          paddingTop: "calc(1.25rem + env(safe-area-inset-top))",
          paddingBottom: "calc(1.25rem + env(safe-area-inset-bottom))",
        }}
      >
      <div className="pb-8 pt-2">
        <div className="flex items-center gap-2 text-primary">
          <div className="flex h-9 w-9 items-center justify-center rounded-2xl bg-primary text-primary-foreground shadow-lg shadow-primary/25">
            <Dumbbell className="h-4 w-4" />
          </div>
          <span className="text-[11px] font-extrabold uppercase tracking-[0.2em]">Gym Manager</span>
        </div>
        <div className="mt-7 max-w-xs">
          <div className="mb-3 flex items-center gap-2 text-xs font-bold text-success">
            <span className="h-2 w-2 rounded-full bg-success shadow-[0_0_0_4px_hsl(var(--success)/0.12)]" />
            Your floor, in your pocket
          </div>
          <h1 className="font-display text-[2.65rem] font-extrabold leading-[0.95] tracking-[-0.06em] text-balance">
            Run the gym. Keep moving.
          </h1>
        </div>
      </div>

      <div className="app-surface flex-1 rounded-[2rem] p-5">
      <Tabs value={tab} onValueChange={(v) => setTab(v as "signin" | "signup")} className="w-full">
        <TabsList className="grid h-11 w-full grid-cols-2">
          <TabsTrigger value="signin">Sign In</TabsTrigger>
          <TabsTrigger value="signup">Sign Up</TabsTrigger>
        </TabsList>

        {/* ── Sign In ── */}
        <TabsContent value="signin" className="mt-6">
          <div className="mb-5">
            <h2 className="font-display text-xl font-bold">Welcome back</h2>
            <p className="mt-1 text-sm text-muted-foreground">Pick up where your team left off.</p>
          </div>
          <form onSubmit={handleSignIn} className="space-y-4">
            <div className="space-y-1.5">
              <Label htmlFor="login-email">Email</Label>
              <Input
                id="login-email"
                type="email"
                inputMode="email"
                autoComplete="email"
                placeholder="admin@gym.com"
                value={loginEmail}
                onChange={(e) => setLoginEmail(e.target.value)}
                required
                className="h-12 text-base"
              />
            </div>
            <div className="space-y-1.5">
              <Label htmlFor="login-password">Password</Label>
              <Input
                id="login-password"
                type="password"
                autoComplete="current-password"
                placeholder="••••••••"
                value={loginPassword}
                onChange={(e) => setLoginPassword(e.target.value)}
                required
                className="h-12 text-base"
              />
            </div>
            <Button type="submit" className="h-12 w-full text-base font-bold" disabled={loginLoading}>
              {loginLoading ? "Signing in…" : <><span>Enter workspace</span><ArrowUpRight className="h-4 w-4" /></>}
            </Button>
          </form>
        </TabsContent>

        {/* ── Sign Up ── */}
        <TabsContent value="signup" className="mt-6">
          <div className="mb-5">
            <h2 className="font-display text-xl font-bold">Build your workspace</h2>
            <p className="mt-1 text-sm text-muted-foreground">Start with your admin account.</p>
          </div>
          <form onSubmit={handleSignUp} className="space-y-4">
            <div className="space-y-1.5">
              <Label htmlFor="signup-name">Full Name</Label>
              <Input
                id="signup-name"
                autoComplete="name"
                placeholder="John Doe"
                value={signupName}
                onChange={(e) => setSignupName(e.target.value)}
                required
                className="h-12 text-base"
              />
            </div>
            <div className="space-y-1.5">
              <Label htmlFor="signup-email">Email</Label>
              <Input
                id="signup-email"
                type="email"
                inputMode="email"
                autoComplete="email"
                placeholder="admin@gym.com"
                value={signupEmail}
                onChange={(e) => setSignupEmail(e.target.value)}
                required
                className="h-12 text-base"
              />
            </div>
            <div className="space-y-1.5">
              <Label htmlFor="signup-password">Password</Label>
              <Input
                id="signup-password"
                type="password"
                autoComplete="new-password"
                placeholder="Min. 6 characters"
                value={signupPassword}
                onChange={(e) => setSignupPassword(e.target.value)}
                required
                className="h-12 text-base"
              />
            </div>
            <div className="space-y-1.5">
              <Label htmlFor="signup-confirm">Confirm Password</Label>
              <Input
                id="signup-confirm"
                type="password"
                autoComplete="new-password"
                placeholder="Re-enter password"
                value={signupConfirm}
                onChange={(e) => setSignupConfirm(e.target.value)}
                required
                className="h-12 text-base"
              />
            </div>
            <Button type="submit" className="h-12 w-full text-base font-semibold" disabled={signupLoading}>
              {signupLoading ? "Creating account…" : "Create Account"}
            </Button>
          </form>
        </TabsContent>
      </Tabs>
      </div>
      <p className="pt-4 text-center text-[10px] font-semibold uppercase tracking-[0.16em] text-muted-foreground">
        Built for the training floor
      </p>
      </div>
    </div>
  );
}
