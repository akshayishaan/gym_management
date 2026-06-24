"use client";

import { useState } from "react";
import { signIn } from "next-auth/react";
import { useRouter } from "next/navigation";
import { toast } from "sonner";
import { motion } from "framer-motion";
import { Dumbbell, Zap, Shield, TrendingUp } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
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

  const features = [
    { icon: Zap, text: "Lightning fast member management" },
    { icon: Shield, text: "Secure payment tracking" },
    { icon: TrendingUp, text: "Real-time analytics & insights" },
  ];

  return (
    <div className="min-h-screen flex">
      {/* Left Panel - Brand */}
      <div className="hidden lg:flex lg:w-1/2 relative overflow-hidden bg-slate-900">
        <div className="absolute inset-0 opacity-20">
          <div className="absolute top-0 left-0 w-96 h-96 bg-orange-500 rounded-full blur-3xl -translate-x-1/2 -translate-y-1/2" />
          <div className="absolute bottom-0 right-0 w-96 h-96 bg-red-500 rounded-full blur-3xl translate-x-1/2 translate-y-1/2" />
          <div className="absolute top-1/2 left-1/2 w-64 h-64 bg-amber-500 rounded-full blur-3xl -translate-x-1/2 -translate-y-1/2" />
        </div>
        <div className="relative z-10 flex flex-col justify-between p-12 w-full">
          <motion.div initial={{ opacity: 0, y: -20 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.6 }} className="flex items-center gap-3">
            <div className="bg-gradient-to-br from-orange-500 to-red-500 rounded-xl p-2.5 shadow-lg shadow-orange-500/20">
              <Dumbbell className="h-6 w-6 text-white" />
            </div>
            <span className="text-white font-bold text-xl">Gym Manager</span>
          </motion.div>

          <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.6, delay: 0.2 }} className="space-y-8">
            <div>
              <h2 className="text-4xl font-bold text-white tracking-tight leading-tight">
                Manage your gym<br />
                <span className="text-orange-400">with power & precision</span>
              </h2>
              <p className="text-slate-400 mt-4 text-lg max-w-md">
                The all-in-one platform for modern gym management. Track members, payments, and growth effortlessly.
              </p>
            </div>
            <div className="space-y-4">
              {features.map((feature, i) => (
                <motion.div key={feature.text} initial={{ opacity: 0, x: -20 }} animate={{ opacity: 1, x: 0 }} transition={{ delay: 0.4 + i * 0.1 }} className="flex items-center gap-3 text-slate-300">
                  <div className="p-1.5 rounded-lg bg-white/10">
                    <feature.icon className="h-4 w-4 text-orange-400" />
                  </div>
                  <span className="text-sm">{feature.text}</span>
                </motion.div>
              ))}
            </div>
          </motion.div>

          <motion.p initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ delay: 0.8 }} className="text-slate-500 text-sm">
            Trusted by 500+ gyms worldwide
          </motion.p>
        </div>
      </div>

      {/* Right Panel - Forms */}
      <div className="flex-1 flex items-center justify-center p-6 bg-background">
        <motion.div
          initial={{ opacity: 0, y: 30 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, type: "spring", stiffness: 300, damping: 24 }}
          className="w-full max-w-md"
        >
          {/* Mobile logo */}
          <div className="lg:hidden flex items-center justify-center gap-3 mb-8">
            <div className="bg-gradient-to-br from-orange-500 to-red-500 rounded-xl p-2.5 shadow-lg shadow-orange-500/20">
              <Dumbbell className="h-6 w-6 text-white" />
            </div>
            <span className="font-bold text-xl">Gym Manager</span>
          </div>

          <Card className="border-0 shadow-soft">
            <CardHeader className="space-y-1 pb-4">
              <CardTitle className="text-2xl font-bold tracking-tight">
                {tab === "signin" ? "Welcome back" : "Create account"}
              </CardTitle>
              <CardDescription>
                {tab === "signin" ? "Sign in to your gym dashboard" : "Sign up to start managing your gym"}
              </CardDescription>
            </CardHeader>
            <CardContent>
              <Tabs value={tab} onValueChange={(v) => setTab(v as "signin" | "signup")}>
                <TabsList className="w-full mb-6">
                  <TabsTrigger value="signin" className="flex-1">Sign In</TabsTrigger>
                  <TabsTrigger value="signup" className="flex-1">Sign Up</TabsTrigger>
                </TabsList>

                {/* ── Sign In ── */}
                <TabsContent value="signin">
                  <form onSubmit={handleSignIn} className="space-y-4">
                    <div className="space-y-2">
                      <Label htmlFor="login-email">Email</Label>
                      <Input id="login-email" type="email" placeholder="admin@gym.com" value={loginEmail} onChange={e => setLoginEmail(e.target.value)} required className="h-11" />
                    </div>
                    <div className="space-y-2">
                      <Label htmlFor="login-password">Password</Label>
                      <Input id="login-password" type="password" placeholder="••••••••" value={loginPassword} onChange={e => setLoginPassword(e.target.value)} required className="h-11" />
                    </div>
                    <Button type="submit" className="w-full h-11 text-base font-semibold bg-gradient-to-r from-orange-500 to-red-500 hover:from-orange-600 hover:to-red-600 transition-all" disabled={loginLoading}>
                      {loginLoading ? <span className="flex items-center gap-2"><span className="h-4 w-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />Signing in...</span> : "Sign In"}
                    </Button>
                  </form>
                </TabsContent>

                {/* ── Sign Up ── */}
                <TabsContent value="signup">
                  <form onSubmit={handleSignUp} className="space-y-4">
                    <div className="space-y-2">
                      <Label htmlFor="signup-name">Full Name</Label>
                      <Input id="signup-name" placeholder="John Doe" value={signupName} onChange={e => setSignupName(e.target.value)} required className="h-11" />
                    </div>
                    <div className="space-y-2">
                      <Label htmlFor="signup-email">Email</Label>
                      <Input id="signup-email" type="email" placeholder="admin@gym.com" value={signupEmail} onChange={e => setSignupEmail(e.target.value)} required className="h-11" />
                    </div>
                    <div className="space-y-2">
                      <Label htmlFor="signup-password">Password</Label>
                      <Input id="signup-password" type="password" placeholder="Min. 6 characters" value={signupPassword} onChange={e => setSignupPassword(e.target.value)} required className="h-11" />
                    </div>
                    <div className="space-y-2">
                      <Label htmlFor="signup-confirm">Confirm Password</Label>
                      <Input id="signup-confirm" type="password" placeholder="Re-enter password" value={signupConfirm} onChange={e => setSignupConfirm(e.target.value)} required className="h-11" />
                    </div>
                    <Button type="submit" className="w-full h-11 text-base font-semibold bg-gradient-to-r from-orange-500 to-red-500 hover:from-orange-600 hover:to-red-600 transition-all" disabled={signupLoading}>
                      {signupLoading ? <span className="flex items-center gap-2"><span className="h-4 w-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />Creating account...</span> : "Create Account"}
                    </Button>
                  </form>
                </TabsContent>
              </Tabs>
            </CardContent>
          </Card>
        </motion.div>
      </div>
    </div>
  );
}
