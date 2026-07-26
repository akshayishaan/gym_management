"use client";

import { useDeferredValue, useEffect, useState } from "react";
import { toast } from "sonner";
import { Search, SlidersHorizontal, Check, Users } from "lucide-react";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { Fab } from "@/components/ui/fab";
import { BottomSheetForm } from "@/components/dashboard/BottomSheetForm";
import { MemberCard } from "@/components/dashboard/MemberCard";
import { MemberForm, type MemberFormInitialData } from "@/components/dashboard/MemberForm";
import { PaymentFormDialog } from "@/components/dashboard/PaymentFormDialog";
import { cn } from "@/lib/utils";
import { useSearchParams } from "next/navigation";
import { useMembers } from "@/lib/hooks/useMembers";
import { useInvalidateGymScope } from "@/lib/hooks/useGymScope";

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

const STATUS_OPTIONS = [
  { value: "all", label: "All Members" },
  { value: "active", label: "Active" },
  { value: "expiring", label: "Expiring Soon" },
  { value: "expiring30", label: "Expiring in 30 Days" },
  { value: "expired", label: "Expired" },
  { value: "due", label: "Payment Due" },
];

export default function MembersPage() {
  const [search, setSearch] = useState("");
  const deferredSearch = useDeferredValue(search);
  const [status, setStatus] = useState("all");
  const [filterOpen, setFilterOpen] = useState(false);
  const [addOpen, setAddOpen] = useState(false);
  const [editMember, setEditMember] = useState<MemberFormInitialData | null>(null);
  const [renewMember, setRenewMember] = useState<{ id: string; name: string } | null>(null);
  const searchParams = useSearchParams();
  const membersQuery = useMembers({ search: deferredSearch, status });
  const invalidateGymScope = useInvalidateGymScope();
  const members = membersQuery.data?.members ?? [];
  const total = membersQuery.data?.total ?? 0;
  const loading = membersQuery.isLoading;

  useEffect(() => {
    const s = searchParams.get("status");
    if (s) setStatus(s);
  }, [searchParams]);

  async function deleteMember(id: string) {
    const res = await fetch(`/api/members/${id}`, { method: "DELETE" });
    if (res.ok) {
      toast.success("Member deleted");
      void invalidateGymScope();
    } else {
      toast.error("Failed to delete member");
    }
  }

  function handleEditClick(id: string) {
    fetch(`/api/members/${id}`)
      .then((r) => r.json())
      .then(setEditMember);
  }

  return (
    <div className="space-y-5">
      <div className="app-surface flex items-center gap-2 rounded-[1.5rem] p-2">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" strokeWidth={2.5} />
          <Input
            placeholder="Search members…"
            className="h-11 border-0 bg-transparent pl-9 shadow-none focus-visible:ring-0"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
        </div>
        <Button
          aria-label="Filter members"
          variant="outline"
          size="icon"
          className={cn("h-11 w-11 shrink-0 border-0 bg-muted", status !== "all" && "bg-primary text-primary-foreground")}
          onClick={() => setFilterOpen(true)}
        >
          <SlidersHorizontal className="h-4 w-4" />
        </Button>
      </div>

      <div className="flex items-center justify-between px-1">
        <p className="app-section-label">Your community</p>
        <p className="text-xs font-semibold text-muted-foreground">
          {total} member{total !== 1 ? "s" : ""}
        </p>
      </div>

      {loading ? (
        <div className="space-y-2">
          {[...Array(6)].map((_, i) => (
            <div key={i} className="h-[112px] animate-pulse rounded-[1.5rem] bg-card" />
          ))}
        </div>
      ) : members.length === 0 ? (
        <div className="app-surface flex flex-col items-center gap-4 rounded-[2rem] px-6 py-16 text-center">
          <div className="inline-flex h-16 w-16 items-center justify-center rounded-[1.4rem] bg-primary/10 text-primary">
            <Users className="h-7 w-7" />
          </div>
          <div>
            <p className="font-display text-lg font-bold">No members found</p>
            <p className="mt-1 text-sm text-muted-foreground">Try a different name or membership status.</p>
          </div>
        </div>
      ) : (
        <div className="space-y-3">
          {members.map((m) => (
            <MemberCard
              key={m._id}
              member={m}
              onDelete={deleteMember}
              onRenew={setRenewMember}
              onEdit={handleEditClick}
            />
          ))}
        </div>
      )}

      <Fab onClick={() => setAddOpen(true)} />

      <MemberForm
        mode="create"
        variant="sheet"
        open={addOpen}
        onOpenChange={setAddOpen}
        onSuccess={() => {
          setAddOpen(false);
          void invalidateGymScope();
        }}
      />

      <MemberForm
        mode="edit"
        variant="sheet"
        open={!!editMember}
        onOpenChange={(open) => {
          if (!open) setEditMember(null);
        }}
        initialData={editMember ?? undefined}
        onSuccess={() => {
          setEditMember(null);
          void invalidateGymScope();
        }}
      />

      <BottomSheetForm
        open={filterOpen}
        onOpenChange={setFilterOpen}
        title="Filter Members"
        footer={
          <Button variant="outline" className="w-full" onClick={() => setFilterOpen(false)}>
            Close
          </Button>
        }
      >
        <div className="space-y-1 py-2">
          {STATUS_OPTIONS.map((opt) => (
            <button
              key={opt.value}
              type="button"
              onClick={() => {
                setStatus(opt.value);
                setFilterOpen(false);
              }}
              className={cn(
                "flex min-h-12 w-full items-center justify-between rounded-2xl px-4 py-3 text-sm font-semibold transition-colors",
                status === opt.value ? "bg-primary/10 text-primary" : "active:bg-muted"
              )}
            >
              {opt.label}
              {status === opt.value && <Check className="h-4 w-4" />}
            </button>
          ))}
        </div>
      </BottomSheetForm>

      <PaymentFormDialog
        open={!!renewMember}
        onOpenChange={(open) => {
          if (!open) setRenewMember(null);
        }}
        prefillMemberId={renewMember?.id}
        prefillMemberName={renewMember?.name}
        onSuccess={() => {
          setRenewMember(null);
          void invalidateGymScope();
        }}
      />
    </div>
  );
}
