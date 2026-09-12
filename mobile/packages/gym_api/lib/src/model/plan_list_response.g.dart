// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_list_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlanListResponse _$PlanListResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'PlanListResponse',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['plans', 'total', 'page', 'limit'],
        );
        final val = PlanListResponse(
          plans: $checkedConvert(
              'plans',
              (v) => (v as List<dynamic>)
                  .map((e) => PlanListResponsePlansInner.fromJson(
                      e as Map<String, dynamic>))
                  .toList()),
          total: $checkedConvert('total', (v) => v as num),
          page: $checkedConvert('page', (v) => v as num),
          limit: $checkedConvert('limit', (v) => v as num),
          summary: $checkedConvert(
              'summary',
              (v) => v == null
                  ? null
                  : PlanListResponseSummary.fromJson(
                      v as Map<String, dynamic>)),
        );
        return val;
      },
    );

Map<String, dynamic> _$PlanListResponseToJson(PlanListResponse instance) {
  final val = <String, dynamic>{
    'plans': instance.plans.map((e) => e.toJson()).toList(),
    'total': instance.total,
    'page': instance.page,
    'limit': instance.limit,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('summary', instance.summary?.toJson());
  return val;
}
