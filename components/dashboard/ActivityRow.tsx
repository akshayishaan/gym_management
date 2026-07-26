import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import { Badge } from "@/components/ui/badge";
import { formatDate } from "@/lib/utils";

interface Log {
  _id: string;
  staffName: string;
  action: string;
  entity: string;
  details?: string;
  createdAt: string;
}

const actionConfig: Record<string, {
  variant: "default" | "secondary" | "success" | "warning" | "destructive" | "outline";
  dot: string;
}> = {
  created: { variant: "success", dot: "bg-success" },
  updated: { variant: "secondary", dot: "bg-primary" },
  deleted: { variant: "destructive", dot: "bg-destructive" },
  voided: { variant: "secondary", dot: "bg-muted-foreground" },
  refunded: { variant: "warning", dot: "bg-warning" },
  reversed: { variant: "destructive", dot: "bg-destructive" },
  migrated: { variant: "outline", dot: "bg-primary" },
};

function getInitials(name: string) {
  return name.split(" ").map((n) => n[0]).join("").toUpperCase().slice(0, 2);
}

export function ActivityRow({ log }: { log: Log }) {
  const action = actionConfig[log.action] || { variant: "outline" as const, dot: "bg-muted-foreground" };

  return (
    <div className="flex items-start gap-3 px-1 py-4">
      <Avatar className="h-10 w-10 shrink-0 ring-4 ring-secondary/60">
        <AvatarFallback className="bg-secondary text-xs font-bold text-secondary-foreground">
          {getInitials(log.staffName)}
        </AvatarFallback>
      </Avatar>
      <div className="min-w-0 flex-1">
        <div className="flex items-center justify-between gap-2">
          <p className="truncate text-sm font-bold">{log.staffName}</p>
          <span className="shrink-0 text-xs text-muted-foreground">{formatDate(log.createdAt)}</span>
        </div>
        <div className="mt-1.5 flex items-center gap-2">
          <Badge variant={action.variant} className="gap-1.5 text-xs capitalize">
            <span className={`h-1.5 w-1.5 rounded-full ${action.dot}`} />
            {log.action}
          </Badge>
          <span className="truncate text-xs capitalize text-muted-foreground">{log.entity}</span>
        </div>
        {log.details && (
          <p className="mt-1.5 line-clamp-2 text-xs leading-5 text-muted-foreground">{log.details}</p>
        )}
      </div>
    </div>
  );
}
