"use client";

import { motion } from "framer-motion";
import Link from "next/link";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { Users, CreditCard, MessageCircle, BarChart3 } from "lucide-react";

const actions = [
  {
    label: "Add Member",
    href: "/dashboard/members/new",
    icon: Users,
    color: "bg-blue-500 hover:bg-blue-600",
  },
  {
    label: "Record Payment",
    href: "/dashboard/payments/new",
    icon: CreditCard,
    color: "bg-emerald-500 hover:bg-emerald-600",
  },
  {
    label: "Send Reminders",
    href: "/dashboard/members?status=expiring",
    icon: MessageCircle,
    color: "bg-amber-500 hover:bg-amber-600",
  },
  {
    label: "View Reports",
    href: "/dashboard/reports",
    icon: BarChart3,
    color: "bg-violet-500 hover:bg-violet-600",
  },
];

export function QuickActions() {
  return (
    <motion.div
      initial={{ opacity: 0, y: 10 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.4, delay: 0.1 }}
    >
      <Card className="border-0 shadow-card">
        <CardContent className="p-4">
          <div className="flex flex-wrap gap-3">
            {actions.map((action, i) => (
              <motion.div
                key={action.label}
                initial={{ opacity: 0, scale: 0.9 }}
                animate={{ opacity: 1, scale: 1 }}
                transition={{ delay: 0.15 + i * 0.05 }}
              >
                <Link href={action.href}>
                  <Button
                    variant="secondary"
                    className="gap-2 h-10 px-4 bg-secondary hover:bg-secondary/80 transition-all hover:scale-[1.02] active:scale-[0.98]"
                  >
                    <div className={`p-1 rounded-md text-white ${action.color}`}>
                      <action.icon className="h-3.5 w-3.5" />
                    </div>
                    <span className="text-sm font-medium">{action.label}</span>
                  </Button>
                </Link>
              </motion.div>
            ))}
          </div>
        </CardContent>
      </Card>
    </motion.div>
  );
}
