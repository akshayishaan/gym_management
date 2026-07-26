export const gymQueryKeys = {
  root: (gymId: string | null) => ["gym", gymId] as const,
  dashboard: (gymId: string | null) => ["gym", gymId, "dashboard"] as const,
  members: (gymId: string | null, filters: Record<string, unknown>) =>
    ["gym", gymId, "members", filters] as const,
  member: (gymId: string | null, memberId: string) =>
    ["gym", gymId, "member", memberId] as const,
  memberships: (gymId: string | null, memberId: string) =>
    ["gym", gymId, "memberships", memberId] as const,
  payments: (gymId: string | null, filters: Record<string, unknown>) =>
    ["gym", gymId, "payments", filters] as const,
  plans: (gymId: string | null, filters: Record<string, unknown>) =>
    ["gym", gymId, "plans", filters] as const,
  reports: (gymId: string | null, year: number) =>
    ["gym", gymId, "reports", year] as const,
  activity: (gymId: string | null) => ["gym", gymId, "activity"] as const,
};
