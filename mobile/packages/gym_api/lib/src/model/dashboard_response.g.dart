// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DashboardResponse _$DashboardResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'DashboardResponse',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'totalMembers',
            'activeMembers',
            'expiredMembers',
            'expiringMembers',
            'monthRevenue',
            'recentPayments',
            'expiringList'
          ],
        );
        final val = DashboardResponse(
          totalMembers: $checkedConvert('totalMembers', (v) => v as num),
          activeMembers: $checkedConvert('activeMembers', (v) => v as num),
          expiredMembers: $checkedConvert('expiredMembers', (v) => v as num),
          expiringMembers: $checkedConvert('expiringMembers', (v) => v as num),
          monthRevenue: $checkedConvert('monthRevenue', (v) => v as num),
          recentPayments: $checkedConvert(
              'recentPayments',
              (v) => (v as List<dynamic>)
                  .map((e) => DashboardResponseRecentPaymentsInner.fromJson(
                      e as Map<String, dynamic>))
                  .toList()),
          expiringList: $checkedConvert(
              'expiringList',
              (v) => (v as List<dynamic>)
                  .map((e) => DashboardResponseExpiringListInner.fromJson(
                      e as Map<String, dynamic>))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$DashboardResponseToJson(DashboardResponse instance) =>
    <String, dynamic>{
      'totalMembers': instance.totalMembers,
      'activeMembers': instance.activeMembers,
      'expiredMembers': instance.expiredMembers,
      'expiringMembers': instance.expiringMembers,
      'monthRevenue': instance.monthRevenue,
      'recentPayments': instance.recentPayments.map((e) => e.toJson()).toList(),
      'expiringList': instance.expiringList.map((e) => e.toJson()).toList(),
    };
