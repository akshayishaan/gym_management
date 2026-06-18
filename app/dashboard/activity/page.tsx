"use client";

import { useEffect, useState } from "react";
import { motion } from "framer-motion";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { PageHeader } from "@/components/layout/PageHeader";
import { formatDate } from "@/lib/utils";
import { ClipboardList, ChevronLeft, ChevronRight, User } from "lucide-react";

interface Log {
  _id: string;
  staffName: string;
  action: string;
  entity: string;
  details?: string;
  createdAt: string;
}

const actionConfig: Record<string, { variant: "default" | "secondary" | "success" | "warning" | "destructive" | "outline"; dot: string }> = {
  created: { variant: "success", dot: "bg-emerald-500" },
  updated: { variant: "secondary", dot: "bg-blue-500" },
  deleted: { variant: "destructive", dot: "bg-rose-500" },
};

function getInitials(name: string) {
  return name
    .split(" ")
    .map((n) => n[0])
    .join("")
    .toUpperCase()
    .slice(0, 2);
}

export default function ActivityPage() {
  const [logs, setLogs] = useState<Log[]>([]);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const limit = 50;

  useEffect(() => {
    fetch(`/api/activity?page=${page}&limit=${limit}`)
      .then(r => r.json())
      .then(d => { setLogs(d.logs || []); setTotal(d.total || 0); });
  }, [page]);

  return (
    <div className="space-y-6">
      <PageHeader
        title="Activity Log"
        description={`${total} total activities`}
      />

      <Card className="border-0 shadow-card overflow-hidden">
        <CardContent className="p-0">
          <div className="overflow-x-auto">
            <Table>
              <TableHeader>
                <TableRow className="hover:bg-transparent">
                  <TableHead>Staff</TableHead>
                  <TableHead>Action</TableHead>
                  <TableHead>Entity</TableHead>
                  <TableHead>Details</TableHead>
                  <TableHead>Time</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {logs.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={5} className="text-center py-12">
                      <div className="flex flex-col items-center gap-3">
                        <div className="inline-flex items-center justify-center w-12 h-12 rounded-full bg-muted text-muted-foreground">
                          <ClipboardList className="h-6 w-6" />
                        </div>
                        <div>
                          <p className="text-sm font-medium text-muted-foreground">No activity yet</p>
                          <p className="text-xs text-muted-foreground mt-1">Actions will appear here as they happen</p>
                        </div>
                      </div>
                    </TableCell>
                  </TableRow>
                ) : (
                  logs.map((log, i) => {
                    const action = actionConfig[log.action] || { variant: "outline", dot: "bg-gray-500" };
                    return (
                      <motion.tr
                        key={log._id}
                        initial={{ opacity: 0, y: 10 }}
                        animate={{ opacity: 1, y: 0 }}
                        transition={{ delay: i * 0.02 }}
                        className="border-b transition-colors hover:bg-muted/40 data-[state=selected]:bg-muted"
                      >
                        <TableCell>
                          <div className="flex items-center gap-3">
                            <Avatar className="h-8 w-8 border-2 border-background shadow-sm">
                              <AvatarFallback className="bg-secondary text-secondary-foreground text-xs font-bold">
                                {getInitials(log.staffName)}
                              </AvatarFallback>
                            </Avatar>
                            <span className="font-medium text-sm">{log.staffName}</span>
                          </div>
                        </TableCell>
                        <TableCell>
                          <Badge variant={action.variant} className="gap-1.5 capitalize text-xs">
                            <span className={`h-1.5 w-1.5 rounded-full ${action.dot}`} />
                            {log.action}
                          </Badge>
                        </TableCell>
                        <TableCell className="capitalize text-sm">{log.entity}</TableCell>
                        <TableCell className="text-sm text-muted-foreground max-w-xs truncate">
                          {log.details || "—"}
                        </TableCell>
                        <TableCell className="text-sm text-muted-foreground whitespace-nowrap">
                          {formatDate(log.createdAt)}
                        </TableCell>
                      </motion.tr>
                    );
                  })
                )}
              </TableBody>
            </Table>
          </div>
        </CardContent>
      </Card>

      {total > limit && (
        <div className="flex justify-center items-center gap-3">
          <Button
            variant="outline"
            size="sm"
            disabled={page === 1}
            onClick={() => setPage(p => p - 1)}
            className="gap-1"
          >
            <ChevronLeft className="h-4 w-4" />
            Previous
          </Button>
          <span className="text-sm text-muted-foreground">
            Page <span className="font-medium text-foreground">{page}</span> of{" "}
            {Math.ceil(total / limit)}
          </span>
          <Button
            variant="outline"
            size="sm"
            disabled={page * limit >= total}
            onClick={() => setPage(p => p + 1)}
            className="gap-1"
          >
            Next
            <ChevronRight className="h-4 w-4" />
          </Button>
        </div>
      )}
    </div>
  );
}
