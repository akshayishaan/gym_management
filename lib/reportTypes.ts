export interface ReportComparisonMetric {
  value: number;
  previous: number;
  changePercent: number | null;
}

export interface ReportSeriesPoint {
  month: number;
  revenue: number;
  transactions: number;
  newMembers: number;
  memberships: number;
  renewals: number;
}

export interface ReportPlanPerformance {
  key: string;
  planId?: string;
  name: string;
  revenue: number;
  sales: number;
  activeMembers: number;
}

export interface ReportPaymentMethod {
  method: string;
  amount: number;
  count: number;
  percentage: number;
}

export interface ReportsResponse {
  year: number;
  asOf: string;
  timezone: string;
  summary: {
    revenue: ReportComparisonMetric;
    transactions: ReportComparisonMetric;
    newMembers: ReportComparisonMetric;
    renewals: ReportComparisonMetric;
    activeMembers: number;
    outstandingDues: number;
    dueMembers: number;
  };
  series: ReportSeriesPoint[];
  planPerformance: ReportPlanPerformance[];
  paymentMethods: ReportPaymentMethod[];
  insights: {
    expiringSoon: number;
    expiredMembers: number;
    dueMembers: number;
    outstandingDues: number;
    bestMonth: { month: number; revenue: number } | null;
  };
}
