// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_list_item_response_stats.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlanListItemResponseStats _$PlanListItemResponseStatsFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'PlanListItemResponseStats',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'activeMembers',
            'salesYtd',
            'revenueAtSaleYtd',
            'totalMemberships'
          ],
        );
        final val = PlanListItemResponseStats(
          activeMembers: $checkedConvert('activeMembers', (v) => v as num),
          salesYtd: $checkedConvert('salesYtd', (v) => v as num),
          revenueAtSaleYtd:
              $checkedConvert('revenueAtSaleYtd', (v) => v as num),
          totalMemberships:
              $checkedConvert('totalMemberships', (v) => v as num),
        );
        return val;
      },
    );

Map<String, dynamic> _$PlanListItemResponseStatsToJson(
        PlanListItemResponseStats instance) =>
    <String, dynamic>{
      'activeMembers': instance.activeMembers,
      'salesYtd': instance.salesYtd,
      'revenueAtSaleYtd': instance.revenueAtSaleYtd,
      'totalMemberships': instance.totalMemberships,
    };
