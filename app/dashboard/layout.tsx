import { getServerSession } from "next-auth";
import { redirect } from "next/navigation";
import { authOptions } from "@/lib/auth";
import { GymGuard } from "@/components/dashboard/GymGuard";
import { MobileShell } from "@/components/layout/MobileShell";

export default async function DashboardLayout({ children }: { children: React.ReactNode }) {
  const session = await getServerSession(authOptions);
  if (!session) redirect("/login");

  return (
    <MobileShell>
      <GymGuard>{children}</GymGuard>
    </MobileShell>
  );
}
