export interface PlanStats {
  activeMembers: number;
  salesYtd: number;
  revenueAtSaleYtd: number;
  totalMemberships: number;
}

export interface PlanListItem {
  _id: string;
  name: string;
  description?: string;
  durationDays: number;
  price: number;
  features?: string[];
  isActive: boolean;
  stats?: PlanStats;
}

export interface PlansResponse {
  plans: PlanListItem[];
  total: number;
  page: number;
  limit: number;
  summary?: {
    activePlans: number;
    activeMembers: number;
    salesYtd: number;
    revenueAtSaleYtd: number;
  };
}
