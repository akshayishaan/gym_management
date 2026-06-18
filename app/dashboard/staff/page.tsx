"use client";

import { useEffect, useState } from "react";
import { toast } from "sonner";
import { motion } from "framer-motion";
import {
  Plus,
  Edit,
  Trash2,
  UserCog,
  MoreHorizontal,
  Users,
} from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Card, CardContent } from "@/components/ui/card";
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
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
} from "@/components/ui/dialog";
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
import { useForm } from "react-hook-form";
import { formatDate } from "@/lib/utils";

interface StaffMember {
  _id: string;
  name: string;
  email: string;
  role: string;
  isActive: boolean;
  lastLogin?: string;
  createdAt: string;
}
type StaffForm = {
  name: string;
  email: string;
  password: string;
  role: string;
  isActive: boolean;
};

const roleConfig: Record<string, { label: string; variant: "default" | "secondary" | "success" | "warning" | "destructive" | "outline" }> = {
  admin: { label: "Admin", variant: "destructive" },
  receptionist: { label: "Receptionist", variant: "secondary" },
  trainer: { label: "Trainer", variant: "success" },
};

function getInitials(name: string) {
  return name
    .split(" ")
    .map((n) => n[0])
    .join("")
    .toUpperCase()
    .slice(0, 2);
}

export default function StaffPage() {
  const [staff, setStaff] = useState<StaffMember[]>([]);
  const [open, setOpen] = useState(false);
  const [editStaff, setEditStaff] = useState<StaffMember | null>(null);
  const { register, handleSubmit, reset, setValue } = useForm<StaffForm>();

  const fetchStaff = () =>
    fetch("/api/staff")
      .then((r) => r.json())
      .then((d) => setStaff(Array.isArray(d) ? d : d.staff || []));
  useEffect(() => {
    fetchStaff();
  }, []);

  function openNew() {
    setEditStaff(null);
    reset({
      name: "",
      email: "",
      password: "",
      role: "receptionist",
      isActive: true,
    });
    setOpen(true);
  }
  function openEdit(s: StaffMember) {
    setEditStaff(s);
    reset({
      name: s.name,
      email: s.email,
      password: "",
      role: s.role,
      isActive: s.isActive,
    });
    setOpen(true);
  }

  async function onSubmit(data: StaffForm) {
    const payload = editStaff
      ? {
          name: data.name,
          role: data.role,
          isActive: data.isActive,
          ...(data.password ? { password: data.password } : {}),
        }
      : data;
    const res = await fetch(
      editStaff ? `/api/staff/${editStaff._id}` : "/api/staff",
      {
        method: editStaff ? "PUT" : "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload),
      }
    );
    if (res.ok) {
      toast.success(editStaff ? "Staff updated!" : "Staff created!");
      setOpen(false);
      fetchStaff();
    } else {
      const e = await res.json();
      toast.error(e.error || "Failed");
    }
  }

  async function deleteStaff(id: string) {
    const res = await fetch(`/api/staff/${id}`, { method: "DELETE" });
    if (res.ok) {
      toast.success("Staff deleted");
      fetchStaff();
    } else {
      const e = await res.json();
      toast.error(e.error || "Failed");
    }
  }

  return (
    <div className="space-y-6">
      <PageHeader
        title="Staff Management"
        description={`${staff.length} staff members`}
        actions={
          <Button onClick={openNew} className="gap-2">
            <Plus className="h-4 w-4" />
            Add Staff
          </Button>
        }
      />

      <Card className="border-0 shadow-card overflow-hidden">
        <CardContent className="p-0">
          <div className="overflow-x-auto">
            <Table>
              <TableHeader>
                <TableRow className="hover:bg-transparent">
                  <TableHead>Staff</TableHead>
                  <TableHead>Email</TableHead>
                  <TableHead>Role</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead>Last Login</TableHead>
                  <TableHead className="text-right w-16">Actions</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {staff.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={6} className="text-center py-12">
                      <div className="flex flex-col items-center gap-3">
                        <div className="inline-flex items-center justify-center w-12 h-12 rounded-full bg-muted text-muted-foreground">
                          <Users className="h-6 w-6" />
                        </div>
                        <div>
                          <p className="text-sm font-medium text-muted-foreground">
                            No staff found
                          </p>
                          <p className="text-xs text-muted-foreground mt-1">
                            Add your first staff member to get started
                          </p>
                        </div>
                      </div>
                    </TableCell>
                  </TableRow>
                ) : (
                  staff.map((s) => {
                    const role = roleConfig[s.role] || {
                      label: s.role,
                      variant: "outline",
                    };
                    return (
                      <TableRow
                        key={s._id}
                        className="group hover:bg-muted/40 transition-colors"
                      >
                        <TableCell>
                          <div className="flex items-center gap-3">
                            <Avatar className="h-9 w-9 border-2 border-background shadow-sm">
                              <AvatarFallback className="bg-primary/10 text-primary text-xs font-bold">
                                {getInitials(s.name)}
                              </AvatarFallback>
                            </Avatar>
                            <span className="font-medium text-sm">{s.name}</span>
                          </div>
                        </TableCell>
                        <TableCell className="text-sm">{s.email}</TableCell>
                        <TableCell>
                          <Badge variant={role.variant} className="capitalize text-xs">
                            {role.label}
                          </Badge>
                        </TableCell>
                        <TableCell>
                          <Badge
                            variant={s.isActive ? "success" : "secondary"}
                            className="text-xs gap-1.5"
                          >
                            <span
                              className={`h-1.5 w-1.5 rounded-full ${
                                s.isActive ? "bg-emerald-500" : "bg-gray-400"
                              }`}
                            />
                            {s.isActive ? "Active" : "Inactive"}
                          </Badge>
                        </TableCell>
                        <TableCell className="text-sm text-muted-foreground">
                          {s.lastLogin ? formatDate(s.lastLogin) : "—"}
                        </TableCell>
                        <TableCell className="text-right">
                          <DropdownMenu>
                            <DropdownMenuTrigger asChild>
                              <Button
                                size="icon"
                                variant="ghost"
                                className="h-8 w-8 opacity-0 group-hover:opacity-100 transition-opacity"
                              >
                                <MoreHorizontal className="h-4 w-4" />
                              </Button>
                            </DropdownMenuTrigger>
                            <DropdownMenuContent align="end" className="w-44">
                              <DropdownMenuItem onClick={() => openEdit(s)}>
                                <Edit className="h-4 w-4 mr-2" />
                                Edit
                              </DropdownMenuItem>
                              <DropdownMenuSeparator />
                              <AlertDialog>
                                <AlertDialogTrigger asChild>
                                  <DropdownMenuItem
                                    className="text-destructive focus:text-destructive focus:bg-destructive/10"
                                    onSelect={(e) => e.preventDefault()}
                                  >
                                    <Trash2 className="h-4 w-4 mr-2" />
                                    Delete
                                  </DropdownMenuItem>
                                </AlertDialogTrigger>
                                <AlertDialogContent>
                                  <AlertDialogHeader>
                                    <AlertDialogTitle>Delete Staff</AlertDialogTitle>
                                    <AlertDialogDescription>
                                      Delete <strong>{s.name}</strong>? This cannot be undone.
                                    </AlertDialogDescription>
                                  </AlertDialogHeader>
                                  <AlertDialogFooter>
                                    <AlertDialogCancel>Cancel</AlertDialogCancel>
                                    <AlertDialogAction
                                      className="bg-destructive hover:bg-destructive/90"
                                      onClick={() => deleteStaff(s._id)}
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

      <Dialog open={open} onOpenChange={setOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>
              {editStaff ? "Edit Staff" : "Add Staff Member"}
            </DialogTitle>
          </DialogHeader>
          <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
            <div className="space-y-2">
              <Label>Name *</Label>
              <Input {...register("name", { required: true })} />
            </div>
            <div className="space-y-2">
              <Label>Email *</Label>
              <Input
                type="email"
                {...register("email", { required: !editStaff })}
                disabled={!!editStaff}
              />
            </div>
            <div className="space-y-2">
              <Label>
                {editStaff
                  ? "New Password (leave blank to keep)"
                  : "Password *"}
              </Label>
              <Input
                type="password"
                {...register("password", { required: !editStaff })}
              />
            </div>
            <div className="space-y-2">
              <Label>Role</Label>
              <Select
                defaultValue={editStaff?.role || "receptionist"}
                onValueChange={(v) => setValue("role", v)}
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="admin">Admin</SelectItem>
                  <SelectItem value="receptionist">Receptionist</SelectItem>
                  <SelectItem value="trainer">Trainer</SelectItem>
                </SelectContent>
              </Select>
            </div>
            <DialogFooter>
              <Button type="button" variant="outline" onClick={() => setOpen(false)}>
                Cancel
              </Button>
              <Button type="submit">{editStaff ? "Update" : "Create"} Staff</Button>
            </DialogFooter>
          </form>
        </DialogContent>
      </Dialog>
    </div>
  );
}
