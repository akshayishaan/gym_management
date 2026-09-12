// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_list_response_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlanListResponseSummary _$PlanListResponseSummaryFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'PlanListResponseSummary',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'activePlans',
            'activeMembers',
            'salesYtd',
            'revenueAtSaleYtd'
          ],
        );
        final val = PlanListResponseSummary(
          activePlans: $checkedConvert('activePlans', (v) => v as num),
          activeMembers: $checkedConvert('activeMembers', (v) => v as num),
          salesYtd: $checkedConvert('salesYtd', (v) => v as num),
          revenueAtSaleYtd:
              $checkedConvert('revenueAtSaleYtd', (v) => v as num),
        );
        return val;
      },
    );

Map<String, dynamic> _$PlanListResponseSummaryToJson(
        PlanListResponseSummary instance) =>
    <String, dynamic>{
      'activePlans': instance.activePlans,
      'activeMembers': instance.activeMembers,
      'salesYtd': instance.salesYtd,
      'revenueAtSaleYtd': instance.revenueAtSaleYtd,
    };
