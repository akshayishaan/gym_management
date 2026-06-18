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

export default function LoginPage() {
  const router = useRouter();
  const [loading, setLoading] = useState(false);
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    const res = await signIn("credentials", {
      email,
      password,
      redirect: false,
    });
    setLoading(false);
    if (res?.error) {
      toast.error("Invalid email or password");
    } else {
      router.push("/dashboard");
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
        {/* Abstract pattern */}
        <div className="absolute inset-0 opacity-20">
          <div className="absolute top-0 left-0 w-96 h-96 bg-orange-500 rounded-full blur-3xl -translate-x-1/2 -translate-y-1/2" />
          <div className="absolute bottom-0 right-0 w-96 h-96 bg-red-500 rounded-full blur-3xl translate-x-1/2 translate-y-1/2" />
          <div className="absolute top-1/2 left-1/2 w-64 h-64 bg-amber-500 rounded-full blur-3xl -translate-x-1/2 -translate-y-1/2" />
        </div>

        <div className="relative z-10 flex flex-col justify-between p-12 w-full">
          <motion.div
            initial={{ opacity: 0, y: -20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6 }}
            className="flex items-center gap-3"
          >
            <div className="bg-gradient-to-br from-orange-500 to-red-500 rounded-xl p-2.5 shadow-lg shadow-orange-500/20">
              <Dumbbell className="h-6 w-6 text-white" />
            </div>
            <span className="text-white font-bold text-xl">Gym Manager</span>
          </motion.div>

          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6, delay: 0.2 }}
            className="space-y-8"
          >
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
                <motion.div
                  key={feature.text}
                  initial={{ opacity: 0, x: -20 }}
                  animate={{ opacity: 1, x: 0 }}
                  transition={{ delay: 0.4 + i * 0.1 }}
                  className="flex items-center gap-3 text-slate-300"
                >
                  <div className="p-1.5 rounded-lg bg-white/10">
                    <feature.icon className="h-4 w-4 text-orange-400" />
                  </div>
                  <span className="text-sm">{feature.text}</span>
                </motion.div>
              ))}
            </div>
          </motion.div>

          <motion.p
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ delay: 0.8 }}
            className="text-slate-500 text-sm"
          >
            Trusted by 500+ gyms worldwide
          </motion.p>
        </div>
      </div>

      {/* Right Panel - Form */}
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
              <CardTitle className="text-2xl font-bold tracking-tight">Welcome back</CardTitle>
              <CardDescription>Sign in to your gym dashboard</CardDescription>
            </CardHeader>
            <CardContent>
              <form onSubmit={handleSubmit} className="space-y-4">
                <div className="space-y-2">
                  <Label htmlFor="email" className="text-sm font-medium">Email</Label>
                  <Input
                    id="email"
                    type="email"
                    placeholder="admin@gym.com"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    required
                    className="h-11 transition-all focus:ring-2 focus:ring-primary/20"
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="password" className="text-sm font-medium">Password</Label>
                  <Input
                    id="password"
                    type="password"
                    placeholder="••••••••"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    required
                    className="h-11 transition-all focus:ring-2 focus:ring-primary/20"
                  />
                </div>
                <Button
                  type="submit"
                  className="w-full h-11 text-base font-semibold bg-gradient-to-r from-orange-500 to-red-500 hover:from-orange-600 hover:to-red-600 transition-all hover:shadow-lg hover:shadow-orange-500/20"
                  disabled={loading}
                >
                  {loading ? (
                    <span className="flex items-center gap-2">
                      <span className="h-4 w-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                      Signing in...
                    </span>
                  ) : (
                    "Sign In"
                  )}
                </Button>
              </form>
            </CardContent>
          </Card>
        </motion.div>
      </div>
    </div>
  );
}
