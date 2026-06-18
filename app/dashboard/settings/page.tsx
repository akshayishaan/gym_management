"use client";

import { useEffect, useState } from "react";
import { useForm } from "react-hook-form";
import { toast } from "sonner";
import { motion } from "framer-motion";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { PageHeader } from "@/components/layout/PageHeader";
import { Settings, Palette, Bell } from "lucide-react";

interface SettingsData {
  gymName: string; address?: string; phone?: string; email?: string;
  primaryColor?: string; currency?: string; expiryReminderDays?: number;
}

export default function SettingsPage() {
  const [loading, setLoading] = useState(false);
  const { register, handleSubmit, reset, setValue } = useForm<SettingsData>();

  useEffect(() => {
    fetch("/api/settings").then(r => r.json()).then(d => { if (d) reset(d); });
  }, [reset]);

  async function onSubmit(data: SettingsData) {
    setLoading(true);
    const res = await fetch("/api/settings", {
      method: "PUT",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(data),
    });
    setLoading(false);
    if (res.ok) toast.success("Settings saved!");
    else toast.error("Failed to save settings");
  }

  return (
    <div className="space-y-6 max-w-2xl">
      <PageHeader
        title="Settings"
        description="Configure your gym branding and preferences"
      />

      <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.4 }}
        >
          <Card className="border-0 shadow-card">
            <CardHeader className="pb-3">
              <div className="flex items-center gap-2">
                <div className="p-1.5 rounded-lg bg-primary/10">
                  <Settings className="h-4 w-4 text-primary" />
                </div>
                <CardTitle className="text-base font-semibold">Gym Branding</CardTitle>
              </div>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="space-y-2">
                <Label>Gym Name *</Label>
                <Input {...register("gymName", { required: true })} placeholder="My Awesome Gym" className="h-10" />
              </div>
              <div className="space-y-2">
                <Label>Address</Label>
                <Input {...register("address")} placeholder="123 Fitness Street, Mumbai" className="h-10" />
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label>Phone</Label>
                  <Input {...register("phone")} placeholder="+91 98765 43210" className="h-10" />
                </div>
                <div className="space-y-2">
                  <Label>Email</Label>
                  <Input type="email" {...register("email")} placeholder="gym@example.com" className="h-10" />
                </div>
              </div>
            </CardContent>
          </Card>
        </motion.div>

        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.4, delay: 0.1 }}
        >
          <Card className="border-0 shadow-card">
            <CardHeader className="pb-3">
              <div className="flex items-center gap-2">
                <div className="p-1.5 rounded-lg bg-violet-500/10">
                  <Palette className="h-4 w-4 text-violet-500" />
                </div>
                <CardTitle className="text-base font-semibold">Preferences</CardTitle>
              </div>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label>Currency</Label>
                  <Select defaultValue="INR" onValueChange={(v) => setValue("currency", v)}>
                    <SelectTrigger className="h-10"><SelectValue /></SelectTrigger>
                    <SelectContent>
                      <SelectItem value="INR">₹ INR (Indian Rupee)</SelectItem>
                      <SelectItem value="USD">$ USD (US Dollar)</SelectItem>
                      <SelectItem value="EUR">€ EUR (Euro)</SelectItem>
                      <SelectItem value="GBP">£ GBP (British Pound)</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
                <div className="space-y-2">
                  <Label>Expiry Reminder (days before)</Label>
                  <Input type="number" {...register("expiryReminderDays")} placeholder="7" className="h-10" />
                </div>
              </div>
            </CardContent>
          </Card>
        </motion.div>

        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.4, delay: 0.2 }}
        >
          <Button
            type="submit"
            disabled={loading}
            className="h-11 px-6 bg-gradient-to-r from-orange-500 to-red-500 hover:from-orange-600 hover:to-red-600 transition-all hover:shadow-lg hover:shadow-orange-500/20"
          >
            {loading ? (
              <span className="flex items-center gap-2">
                <span className="h-4 w-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                Saving...
              </span>
            ) : (
              "Save Settings"
            )}
          </Button>
        </motion.div>
      </form>
    </div>
  );
}
