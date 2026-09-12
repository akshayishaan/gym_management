// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reports_response_plan_performance_inner.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReportsResponsePlanPerformanceInner
    _$ReportsResponsePlanPerformanceInnerFromJson(Map<String, dynamic> json) =>
        $checkedCreate(
          'ReportsResponsePlanPerformanceInner',
          json,
          ($checkedConvert) {
            $checkKeys(
              json,
              requiredKeys: const [
                'key',
                'name',
                'revenue',
                'sales',
                'activeMembers'
              ],
            );
            final val = ReportsResponsePlanPerformanceInner(
              key: $checkedConvert('key', (v) => v as String),
              planId: $checkedConvert('planId', (v) => v as String?),
              name: $checkedConvert('name', (v) => v as String),
              revenue: $checkedConvert('revenue', (v) => v as num),
              sales: $checkedConvert('sales', (v) => v as num),
              activeMembers: $checkedConvert('activeMembers', (v) => v as num),
            );
            return val;
          },
        );

Map<String, dynamic> _$ReportsResponsePlanPerformanceInnerToJson(
    ReportsResponsePlanPerformanceInner instance) {
  final val = <String, dynamic>{
    'key': instance.key,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('planId', instance.planId);
  val['name'] = instance.name;
  val['revenue'] = instance.revenue;
  val['sales'] = instance.sales;
  val['activeMembers'] = instance.activeMembers;
  return val;
}
