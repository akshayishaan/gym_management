import 'package:gym_api/src/model/activity_list_response.dart';
import 'package:gym_api/src/model/activity_list_response_logs_inner.dart';
import 'package:gym_api/src/model/activity_log_response.dart';
import 'package:gym_api/src/model/auth_session_response.dart';
import 'package:gym_api/src/model/auth_session_response_user.dart';
import 'package:gym_api/src/model/dashboard_response.dart';
import 'package:gym_api/src/model/dashboard_response_expiring_list_inner.dart';
import 'package:gym_api/src/model/dashboard_response_recent_payments_inner.dart';
import 'package:gym_api/src/model/error_response.dart';
import 'package:gym_api/src/model/gym_create_input.dart';
import 'package:gym_api/src/model/gym_response.dart';
import 'package:gym_api/src/model/gym_update_input.dart';
import 'package:gym_api/src/model/health_response.dart';
import 'package:gym_api/src/model/lifecycle_result_response.dart';
import 'package:gym_api/src/model/login_input.dart';
import 'package:gym_api/src/model/member_create_input.dart';
import 'package:gym_api/src/model/member_create_response.dart';
import 'package:gym_api/src/model/member_list_response.dart';
import 'package:gym_api/src/model/member_response.dart';
import 'package:gym_api/src/model/member_update_input.dart';
import 'package:gym_api/src/model/membership_list_response.dart';
import 'package:gym_api/src/model/membership_list_response_memberships_inner.dart';
import 'package:gym_api/src/model/membership_response.dart';
import 'package:gym_api/src/model/payment_action_input.dart';
import 'package:gym_api/src/model/payment_create_input.dart';
import 'package:gym_api/src/model/payment_create_response.dart';
import 'package:gym_api/src/model/payment_list_item_response.dart';
import 'package:gym_api/src/model/payment_list_response.dart';
import 'package:gym_api/src/model/payment_list_response_payments_inner.dart';
import 'package:gym_api/src/model/payment_list_response_summary.dart';
import 'package:gym_api/src/model/payment_response.dart';
import 'package:gym_api/src/model/plan_create_input.dart';
import 'package:gym_api/src/model/plan_list_item_response.dart';
import 'package:gym_api/src/model/plan_list_item_response_stats.dart';
import 'package:gym_api/src/model/plan_list_response.dart';
import 'package:gym_api/src/model/plan_list_response_plans_inner.dart';
import 'package:gym_api/src/model/plan_list_response_summary.dart';
import 'package:gym_api/src/model/plan_response.dart';
import 'package:gym_api/src/model/plan_update_input.dart';
import 'package:gym_api/src/model/refresh_input.dart';
import 'package:gym_api/src/model/reports_response.dart';
import 'package:gym_api/src/model/reports_response_insights.dart';
import 'package:gym_api/src/model/reports_response_insights_best_month.dart';
import 'package:gym_api/src/model/reports_response_payment_methods_inner.dart';
import 'package:gym_api/src/model/reports_response_plan_performance_inner.dart';
import 'package:gym_api/src/model/reports_response_series_inner.dart';
import 'package:gym_api/src/model/reports_response_summary.dart';
import 'package:gym_api/src/model/reports_response_summary_revenue.dart';
import 'package:gym_api/src/model/signup_input.dart';
import 'package:gym_api/src/model/signup_response.dart';
import 'package:gym_api/src/model/success_response.dart';

final _regList = RegExp(r'^List<(.*)>$');
final _regSet = RegExp(r'^Set<(.*)>$');
final _regMap = RegExp(r'^Map<String,(.*)>$');

  ReturnType deserialize<ReturnType, BaseType>(dynamic value, String targetType, {bool growable= true}) {
      switch (targetType) {
        case 'String':
          return '$value' as ReturnType;
        case 'int':
          return (value is int ? value : int.parse('$value')) as ReturnType;
        case 'bool':
          if (value is bool) {
            return value as ReturnType;
          }
          final valueString = '$value'.toLowerCase();
          return (valueString == 'true' || valueString == '1') as ReturnType;
        case 'double':
          return (value is double ? value : double.parse('$value')) as ReturnType;
        case 'ActivityListResponse':
          return ActivityListResponse.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ActivityListResponseLogsInner':
          return ActivityListResponseLogsInner.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ActivityLogResponse':
          return ActivityLogResponse.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AuthSessionResponse':
          return AuthSessionResponse.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AuthSessionResponseUser':
          return AuthSessionResponseUser.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'DashboardResponse':
          return DashboardResponse.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'DashboardResponseExpiringListInner':
          return DashboardResponseExpiringListInner.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'DashboardResponseRecentPaymentsInner':
          return DashboardResponseRecentPaymentsInner.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ErrorResponse':
          return ErrorResponse.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'GymCreateInput':
          return GymCreateInput.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'GymResponse':
          return GymResponse.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'GymUpdateInput':
          return GymUpdateInput.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'HealthResponse':
          return HealthResponse.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'LifecycleResultResponse':
          return LifecycleResultResponse.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'LoginInput':
          return LoginInput.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'MemberCreateInput':
          return MemberCreateInput.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'MemberCreateResponse':
          return MemberCreateResponse.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'MemberListResponse':
          return MemberListResponse.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'MemberResponse':
          return MemberResponse.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'MemberUpdateInput':
          return MemberUpdateInput.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'MembershipListResponse':
          return MembershipListResponse.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'MembershipListResponseMembershipsInner':
          return MembershipListResponseMembershipsInner.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'MembershipResponse':
          return MembershipResponse.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PaymentActionInput':
          return PaymentActionInput.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PaymentCreateInput':
          return PaymentCreateInput.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PaymentCreateResponse':
          return PaymentCreateResponse.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PaymentListItemResponse':
          return PaymentListItemResponse.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PaymentListResponse':
          return PaymentListResponse.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PaymentListResponsePaymentsInner':
          return PaymentListResponsePaymentsInner.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PaymentListResponseSummary':
          return PaymentListResponseSummary.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PaymentResponse':
          return PaymentResponse.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PlanCreateInput':
          return PlanCreateInput.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PlanListItemResponse':
          return PlanListItemResponse.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PlanListItemResponseStats':
          return PlanListItemResponseStats.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PlanListResponse':
          return PlanListResponse.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PlanListResponsePlansInner':
          return PlanListResponsePlansInner.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PlanListResponseSummary':
          return PlanListResponseSummary.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PlanResponse':
          return PlanResponse.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PlanUpdateInput':
          return PlanUpdateInput.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'RefreshInput':
          return RefreshInput.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ReportsResponse':
          return ReportsResponse.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ReportsResponseInsights':
          return ReportsResponseInsights.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ReportsResponseInsightsBestMonth':
          return ReportsResponseInsightsBestMonth.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ReportsResponsePaymentMethodsInner':
          return ReportsResponsePaymentMethodsInner.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ReportsResponsePlanPerformanceInner':
          return ReportsResponsePlanPerformanceInner.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ReportsResponseSeriesInner':
          return ReportsResponseSeriesInner.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ReportsResponseSummary':
          return ReportsResponseSummary.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ReportsResponseSummaryRevenue':
          return ReportsResponseSummaryRevenue.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SignupInput':
          return SignupInput.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SignupResponse':
          return SignupResponse.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SuccessResponse':
          return SuccessResponse.fromJson(value as Map<String, dynamic>) as ReturnType;
        default:
          RegExpMatch? match;

          if (value is List && (match = _regList.firstMatch(targetType)) != null) {
            targetType = match![1]!; // ignore: parameter_assignments
            return value
              .map<BaseType>((dynamic v) => deserialize<BaseType, BaseType>(v, targetType, growable: growable))
              .toList(growable: growable) as ReturnType;
          }
          if (value is Set && (match = _regSet.firstMatch(targetType)) != null) {
            targetType = match![1]!; // ignore: parameter_assignments
            return value
              .map<BaseType>((dynamic v) => deserialize<BaseType, BaseType>(v, targetType, growable: growable))
              .toSet() as ReturnType;
          }
          if (value is Map && (match = _regMap.firstMatch(targetType)) != null) {
            targetType = match![1]!.trim(); // ignore: parameter_assignments
            return Map<String, BaseType>.fromIterables(
              value.keys as Iterable<String>,
              value.values.map((dynamic v) => deserialize<BaseType, BaseType>(v, targetType, growable: growable)),
            ) as ReturnType;
          }
          break;
    }
    throw Exception('Cannot deserialize');
  }