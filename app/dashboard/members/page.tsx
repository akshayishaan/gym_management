"use client";

import { useEffect, useState, useCallback } from "react";
import { toast } from "sonner";
import { MemberFormDialog } from "@/components/dashboard/MemberFormDialog";
import { PaymentFormDialog } from "@/components/dashboard/PaymentFormDialog";
import {
  Plus,
  Search,
  MessageCircle,
  Phone,
  Edit,
  Trash2,
  Eye,
  MoreHorizontal,
  Users,
  RefreshCw,
} from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import { Card, CardContent } from "@/components/ui/card";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
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
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { PageHeader } from "@/components/layout/PageHeader";
import {
  formatDate,
  getMemberStatus,
  buildWhatsAppLink,
  buildSmsLink,
  daysUntilExpiry,
  formatCurrency,
} from "@/lib/utils";
import { useCurrencySymbol } from "@/lib/useGymSettings";
import { useSearchParams, useRouter } from "next/navigation";

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
  return name
    .split(" ")
    .map((n) => n[0])
    .join("")
    .toUpperCase()
    .slice(0, 2);
}

export default function MembersPage() {
  const [members, setMembers] = useState<Member[]>([]);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [status, setStatus] = useState("all");
  const [addOpen, setAddOpen] = useState(false);
  const [editMember, setEditMember] = useState<import("@/components/dashboard/MemberFormDialog").MemberFormInitialData | null>(null);
  const [renewMember, setRenewMember] = useState<{ id: string; name: string } | null>(null);
  const currencySymbol = useCurrencySymbol();
  const router = useRouter();
  const searchParams = useSearchParams();

  const fetchMembers = useCallback(async () => {
    setLoading(true);
    const params = new URLSearchParams();
    if (search) params.set("search", search);
    if (status && status !== "all") params.set("status", status);
    const res = await fetch(`/api/members?${params}`);
    const data = await res.json();
    setMembers(data.members);
    setTotal(data.total);
    setLoading(false);
  }, [search, status]);

  useEffect(() => {
    const s = searchParams.get("status");
    if (s) setStatus(s);
  }, [searchParams]);

  useEffect(() => {
    const timer = setTimeout(fetchMembers, 300);
    return () => clearTimeout(timer);
  }, [fetchMembers]);

  async function deleteMember(id: string) {
    const res = await fetch(`/api/members/${id}`, { method: "DELETE" });
    if (res.ok) {
      toast.success("Member deleted");
      fetchMembers();
    } else {
      toast.error("Failed to delete member");
    }
  }

  const reminderMsg = (m: Member) =>
    `Hi ${m.name}, your gym membership expires on ${m.membershipExpiry ? formatDate(m.membershipExpiry) : "soon"}. Please renew to continue! 💪`;

  return (
    <div className="space-y-6">
      <PageHeader
        title="Members"
        description={`${total} total members`}
        actions={
          <Button className="gap-2" onClick={() => setAddOpen(true)}>
            <Plus className="h-4 w-4" />
            Add Member
          </Button>
        }
      />

      {/* Filters */}
      <Card className="border-0 shadow-card">
        <CardContent className="p-4">
          <div className="flex gap-3 flex-wrap">
            <div className="relative flex-1 min-w-48">
              <Search className="absolute left-3 top-2.5 h-4 w-4 text-muted-foreground" />
              <Input
                placeholder="Search by name, phone, email..."
                className="pl-9 h-10"
                value={search}
                onChange={(e) => setSearch(e.target.value)}
              />
            </div>
            <Select value={status} onValueChange={setStatus}>
              <SelectTrigger className="w-40 h-10">
                <SelectValue placeholder="Status" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All Members</SelectItem>
                <SelectItem value="active">Active</SelectItem>
                <SelectItem value="expiring">Expiring Soon</SelectItem>
                <SelectItem value="expired">Expired</SelectItem>
              </SelectContent>
            </Select>
          </div>
        </CardContent>
      </Card>

      <MemberFormDialog
        open={addOpen}
        onOpenChange={setAddOpen}
        onSuccess={fetchMembers}
      />

      <MemberFormDialog
        open={!!editMember}
        onOpenChange={open => { if (!open) setEditMember(null); }}
        initialData={editMember ?? undefined}
        showMembership={false}
        onSuccess={() => { setEditMember(null); fetchMembers(); }}
      />

      <PaymentFormDialog
        open={!!renewMember}
        onOpenChange={open => { if (!open) setRenewMember(null); }}
        prefillMemberId={renewMember?.id}
        prefillMemberName={renewMember?.name}
        onSuccess={() => { setRenewMember(null); fetchMembers(); }}
      />

      {/* Table */}
      <Card className="border-0 shadow-card overflow-hidden">
        <CardContent className="p-0">
          <div className="overflow-x-auto">
            <Table>
              <TableHeader>
                <TableRow className="hover:bg-transparent">
                  <TableHead>Member</TableHead>
                  <TableHead>Contact</TableHead>
                  <TableHead>Plan</TableHead>
                  <TableHead>Expiry</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead className="text-right w-16">Actions</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {loading ? (
                  [...Array(5)].map((_, i) => (
                    <TableRow key={i}>
                      <TableCell>
                        <div className="flex items-center gap-3">
                          <div className="h-9 w-9 rounded-full bg-muted animate-pulse" />
                          <div className="h-4 w-24 bg-muted rounded animate-pulse" />
                        </div>
                      </TableCell>
                      <TableCell>
                        <div className="h-4 w-28 bg-muted rounded animate-pulse" />
                      </TableCell>
                      <TableCell>
                        <div className="h-4 w-20 bg-muted rounded animate-pulse" />
                      </TableCell>
                      <TableCell>
                        <div className="h-4 w-24 bg-muted rounded animate-pulse" />
                      </TableCell>
                      <TableCell>
                        <div className="h-5 w-16 bg-muted rounded-full animate-pulse" />
                      </TableCell>
                      <TableCell>
                        <div className="h-8 w-8 bg-muted rounded animate-pulse ml-auto" />
                      </TableCell>
                    </TableRow>
                  ))
                ) : members.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={6} className="text-center py-12">
                      <div className="flex flex-col items-center gap-3">
                        <div className="inline-flex items-center justify-center w-12 h-12 rounded-full bg-muted text-muted-foreground">
                          <Users className="h-6 w-6" />
                        </div>
                        <div>
                          <p className="text-sm font-medium">No members found</p>
                          <p className="text-xs text-muted-foreground mt-1">
                            Try adjusting your search or filters
                          </p>
                        </div>
                      </div>
                    </TableCell>
                  </TableRow>
                ) : (
                  members.map((m) => {
                    const st = m.membershipExpiry
                      ? getMemberStatus(m.membershipExpiry)
                      : null;
                    const days = m.membershipExpiry
                      ? daysUntilExpiry(m.membershipExpiry)
                      : null;
                    const msg = reminderMsg(m);
                    return (
                      <TableRow
                        key={m._id}
                        className="group cursor-pointer hover:bg-muted/40 transition-colors"
                        onClick={() => router.push(`/dashboard/members/${m._id}`)}
                      >
                        <TableCell>
                          <div className="flex items-center gap-3">
                            <Avatar className="h-9 w-9 border-2 border-background shadow-sm">
                              <AvatarFallback className="bg-primary/10 text-primary text-xs font-bold">
                                {getInitials(m.name)}
                              </AvatarFallback>
                            </Avatar>
                            <div>
                              <span className="font-medium text-sm">{m.name}</span>
                              {(m.dueAmount ?? 0) > 0 && (
                                <div className="mt-0.5">
                                  <Badge variant="warning" className="text-xs px-1.5 py-0 h-4">
                                    {currencySymbol}{m.dueAmount} due
                                  </Badge>
                                </div>
                              )}
                            </div>
                          </div>
                        </TableCell>
                        <TableCell>
                          <a
                            href={`tel:${m.phone}`}
                            className="flex items-center gap-1 text-sm hover:underline"
                            onClick={(e) => e.stopPropagation()}
                          >
                            <Phone className="h-3 w-3 text-muted-foreground" />
                            {m.phone}
                          </a>
                        </TableCell>
                        <TableCell className="text-sm">
                          {m.planName || "—"}
                        </TableCell>
                        <TableCell className="text-sm">
                          {m.membershipExpiry ? formatDate(m.membershipExpiry) : "—"}
                          {days !== null && days >= 0 && days <= 7 && (
                            <span className="ml-1.5 text-xs text-warning font-medium">
                              ({days}d left)
                            </span>
                          )}
                        </TableCell>
                        <TableCell>
                          {st ? (
                            <Badge variant={statusVariant[st]} className="gap-1.5 capitalize">
                              <span className={`h-1.5 w-1.5 rounded-full ${statusDot[st]}`} />
                              {st}
                            </Badge>
                          ) : (
                            "—"
                          )}
                        </TableCell>
                        <TableCell className="text-right">
                          <DropdownMenu>
                            <DropdownMenuTrigger asChild>
                              <Button
                                size="icon"
                                variant="ghost"
                                className="h-8 w-8 opacity-0 group-hover:opacity-100 transition-opacity"
                                onClick={(e) => e.stopPropagation()}
                              >
                                <MoreHorizontal className="h-4 w-4" />
                              </Button>
                            </DropdownMenuTrigger>
                            <DropdownMenuContent align="end" className="w-48">
                              <DropdownMenuItem
                                onClick={(e) => {
                                  e.stopPropagation();
                                  router.push(`/dashboard/members/${m._id}`);
                                }}
                              >
                                <Eye className="h-4 w-4 mr-2" />
                                View Details
                              </DropdownMenuItem>
                              {(st === "expired" || st === "expiring") && (
                                <DropdownMenuItem
                                  onClick={(e) => {
                                    e.stopPropagation();
                                    setRenewMember({ id: m._id, name: m.name });
                                  }}
                                  className="text-primary focus:text-primary"
                                >
                                  <RefreshCw className="h-4 w-4 mr-2" />
                                  Renew Membership
                                </DropdownMenuItem>
                              )}
                              <DropdownMenuItem
                                onClick={(e) => {
                                  e.stopPropagation();
                                  // Fetch full member to pre-fill all fields in the dialog
                                  fetch(`/api/members/${m._id}`)
                                    .then(r => r.json())
                                    .then(full => setEditMember(full));
                                }}
                              >
                                <Edit className="h-4 w-4 mr-2" />
                                Edit
                              </DropdownMenuItem>
                              <DropdownMenuSeparator />
                              {m.phone && (
                                <>
                                  <DropdownMenuItem
                                    onClick={(e) => {
                                      e.stopPropagation();
                                      window.open(buildWhatsAppLink(m.phone, msg), "_blank");
                                    }}
                                  >
                                    <MessageCircle className="h-4 w-4 mr-2 text-success" />
                                    WhatsApp
                                  </DropdownMenuItem>
                                  <DropdownMenuItem
                                    onClick={(e) => {
                                      e.stopPropagation();
                                      window.location.href = buildSmsLink(m.phone, msg);
                                    }}
                                  >
                                    <Phone className="h-4 w-4 mr-2 text-primary" />
                                    SMS
                                  </DropdownMenuItem>
                                  <DropdownMenuSeparator />
                                </>
                              )}
                              <AlertDialog>
                                <AlertDialogTrigger asChild>
                                  <DropdownMenuItem
                                    className="text-destructive focus:text-destructive focus:bg-destructive/10"
                                    onSelect={(e) => e.preventDefault()}
                                    onClick={(e) => e.stopPropagation()}
                                  >
                                    <Trash2 className="h-4 w-4 mr-2" />
                                    Delete
                                  </DropdownMenuItem>
                                </AlertDialogTrigger>
                                <AlertDialogContent>
                                  <AlertDialogHeader>
                                    <AlertDialogTitle>Delete Member</AlertDialogTitle>
                                    <AlertDialogDescription>
                                      Are you sure you want to delete{" "}
                                      <strong>{m.name}</strong>? This action cannot be undone.
                                    </AlertDialogDescription>
                                  </AlertDialogHeader>
                                  <AlertDialogFooter>
                                    <AlertDialogCancel>Cancel</AlertDialogCancel>
                                    <AlertDialogAction
                                      className="bg-destructive hover:bg-destructive/90"
                                      onClick={() => deleteMember(m._id)}
                                    >
                                      Delete
                                    </AlertDialogAction>
                                  </AlertDialogFooter>
                                </AlertDialogContent>
                              </AlertDialog>
                            </DropdownMenuContent>
                          </DropdownMenu>
                        </TableCell>
                      </TableRow>
                    );
                  })
                )}
              </TableBody>
            </Table>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
