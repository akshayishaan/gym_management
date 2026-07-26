"use client";

import { useRouter } from "next/navigation";
import {
  MoreHorizontal,
  Phone,
  MessageCircle,
  Edit,
  Trash2,
  Eye,
  RefreshCw,
} from "lucide-react";
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
  AlertDialogTrigger,
} from "@/components/ui/alert-dialog";
import {
  formatDate,
  getMemberStatus,
  buildWhatsAppLink,
  buildSmsLink,
  daysUntilExpiry,
} from "@/lib/utils";
import { useCurrencySymbol, useGymSettings } from "@/lib/useGymSettings";

interface Member {
  _id: string;
  name: string;
  phone: string;
  email?: string;
  planName?: string;
  membershipExpiry?: string;
  membershipStart?: string;
  dueAmount?: number;
}

const statusVariant = {
  active: "success" as const,
  expiring: "warning" as const,
  expired: "destructive" as const,
};

const statusDot = {
  active: "bg-success",
  expiring: "bg-warning",
  expired: "bg-destructive",
};

function getInitials(name: string) {
  return name.split(" ").map((n) => n[0]).join("").toUpperCase().slice(0, 2);
}

interface MemberCardProps {
  member: Member;
  onDelete: (id: string) => void;
  onRenew: (member: { id: string; name: string }) => void;
  onEdit: (id: string) => void;
}

export function MemberCard({ member: m, onDelete, onRenew, onEdit }: MemberCardProps) {
  const router = useRouter();
  const currencySymbol = useCurrencySymbol();
  const { timezone } = useGymSettings();
  const st = m.membershipExpiry ? getMemberStatus(m.membershipExpiry, timezone) : null;
  const days = m.membershipExpiry ? daysUntilExpiry(m.membershipExpiry, timezone) : null;
  const msg = `Hi ${m.name}, your gym membership expires on ${
    m.membershipExpiry ? formatDate(m.membershipExpiry) : "soon"
  }. Please renew to continue! 💪`;

  return (
    <div
      role="button"
      tabIndex={0}
      onClick={() => router.push(`/dashboard/members/${m._id}`)}
      onKeyDown={(e) => e.key === "Enter" && router.push(`/dashboard/members/${m._id}`)}
      className="app-surface rounded-[1.6rem] p-4 transition-all active:scale-[0.985] active:bg-muted/50"
    >
      <div className="flex items-center gap-3">
        <Avatar className="h-12 w-12 shrink-0 ring-4 ring-primary/5">
          <AvatarFallback className="bg-gradient-to-br from-primary/20 to-warning/20 text-sm font-extrabold text-primary">
            {getInitials(m.name)}
          </AvatarFallback>
        </Avatar>

        <div className="min-w-0 flex-1">
          <p className="truncate text-[15px] font-bold">{m.name}</p>
          <p className="mt-0.5 truncate text-xs font-medium text-muted-foreground">
            {m.planName || "No plan assigned"}
          </p>
        </div>

        <div className="flex shrink-0 items-center gap-1">
          {st && (
            <Badge variant={statusVariant[st]} className="gap-1 capitalize">
              <span className={`h-1.5 w-1.5 rounded-full ${statusDot[st]}`} />
              {days !== null && days >= 0 && days <= 7 ? `${days}d` : st}
            </Badge>
          )}

          <div onClick={(e) => e.stopPropagation()}>
            <DropdownMenu>
            <DropdownMenuTrigger asChild>
              <Button size="icon" variant="ghost" className="h-9 w-9 rounded-xl">
                <MoreHorizontal className="h-4 w-4" />
              </Button>
            </DropdownMenuTrigger>
            <DropdownMenuContent align="end" className="w-48">
              <DropdownMenuItem onClick={() => router.push(`/dashboard/members/${m._id}`)}>
                <Eye className="mr-2 h-4 w-4" />
                View Details
              </DropdownMenuItem>
              {(st === "expired" || st === "expiring") && (
                <DropdownMenuItem
                  onClick={() => onRenew({ id: m._id, name: m.name })}
                  className="text-primary focus:text-primary"
                >
                  <RefreshCw className="mr-2 h-4 w-4" />
                  Renew Membership
                </DropdownMenuItem>
              )}
              <DropdownMenuItem onClick={() => onEdit(m._id)}>
                <Edit className="mr-2 h-4 w-4" />
                Edit
              </DropdownMenuItem>
              {m.phone && (
                <>
                  <DropdownMenuSeparator />
                  <DropdownMenuItem asChild>
                    <a href={buildWhatsAppLink(m.phone, msg)} target="_blank" rel="noreferrer">
                      <MessageCircle className="mr-2 h-4 w-4 text-success" />
                      WhatsApp
                    </a>
                  </DropdownMenuItem>
                  <DropdownMenuItem asChild>
                    <a href={buildSmsLink(m.phone, msg)}>
                      <Phone className="mr-2 h-4 w-4 text-primary" />
                      SMS
                    </a>
                  </DropdownMenuItem>
                  <DropdownMenuSeparator />
                </>
              )}
              <AlertDialog>
                <AlertDialogTrigger asChild>
                  <DropdownMenuItem
                    className="text-destructive focus:bg-destructive/10 focus:text-destructive"
                    onSelect={(e) => e.preventDefault()}
                  >
                    <Trash2 className="mr-2 h-4 w-4" />
                    Delete
                  </DropdownMenuItem>
                </AlertDialogTrigger>
                <AlertDialogContent>
                  <AlertDialogHeader>
                    <AlertDialogTitle>Delete Member</AlertDialogTitle>
                    <AlertDialogDescription>
                      Are you sure you want to delete <strong>{m.name}</strong>? This action cannot
                      be undone.
                    </AlertDialogDescription>
                  </AlertDialogHeader>
                  <AlertDialogFooter>
                    <AlertDialogCancel>Cancel</AlertDialogCancel>
                    <AlertDialogAction
                      className="bg-destructive hover:bg-destructive/90"
                      onClick={() => onDelete(m._id)}
                    >
                      Delete
                    </AlertDialogAction>
                  </AlertDialogFooter>
                </AlertDialogContent>
              </AlertDialog>
            </DropdownMenuContent>
            </DropdownMenu>
          </div>
        </div>
      </div>

      <div className="mt-3 flex items-center justify-between gap-3 border-t border-border/60 pt-3 text-xs">
        <span className="truncate font-medium text-muted-foreground">
          {m.phone || "No phone number"}
          {m.membershipExpiry && <> · until {formatDate(m.membershipExpiry)}</>}
        </span>
        {(m.dueAmount ?? 0) > 0 ? (
          <span className="shrink-0 font-bold text-warning-foreground dark:text-warning">
            {currencySymbol}{m.dueAmount?.toLocaleString()} due
          </span>
        ) : (
          <span className="shrink-0 font-bold text-success">Paid</span>
        )}
      </div>
    </div>
  );
}
