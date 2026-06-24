"use client";

import { motion } from "framer-motion";
import Link from "next/link";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { Users, CreditCard, MessageCircle, BarChart3 } from "lucide-react";
import { cn } from "@/lib/utils";

const actions = [
  {
    label: "Add Member",
    href: "/dashboard/members/new",
    icon: Users,
    iconClass: "bg-primary/10 text-primary",
  },
  {
    label: "Record Payment",
    href: "/dashboard/payments",
    icon: CreditCard,
    iconClass: "bg-success/10 text-success",
  },
  {
    label: "Send Reminders",
    href: "/dashboard/members?status=expiring",
    icon: MessageCircle,
    iconClass: "bg-warning/10 text-warning",
  },
  {
    label: "View Reports",
    href: "/dashboard/reports",
    icon: BarChart3,
    iconClass: "bg-muted text-muted-foreground",
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
                    variant="outline"
                    className="gap-2 h-10 px-4"
                  >
                    <div className={cn("p-1 rounded-md", action.iconClass)}>
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
