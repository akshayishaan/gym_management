// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activity_list_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ActivityListResponse _$ActivityListResponseFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'ActivityListResponse',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['logs', 'total', 'page', 'limit'],
        );
        final val = ActivityListResponse(
          logs: $checkedConvert(
              'logs',
              (v) => (v as List<dynamic>)
                  .map((e) => ActivityListResponseLogsInner.fromJson(
                      e as Map<String, dynamic>))
                  .toList()),
          total: $checkedConvert('total', (v) => v as num),
          page: $checkedConvert('page', (v) => v as num),
          limit: $checkedConvert('limit', (v) => v as num),
        );
        return val;
      },
    );

Map<String, dynamic> _$ActivityListResponseToJson(
        ActivityListResponse instance) =>
    <String, dynamic>{
      'logs': instance.logs.map((e) => e.toJson()).toList(),
      'total': instance.total,
      'page': instance.page,
      'limit': instance.limit,
    };
