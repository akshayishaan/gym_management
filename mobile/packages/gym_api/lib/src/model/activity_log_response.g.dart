// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activity_log_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ActivityLogResponse _$ActivityLogResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'ActivityLogResponse',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            '_id',
            'staffName',
            'action',
            'entity',
            'createdAt'
          ],
        );
        final val = ActivityLogResponse(
          id: $checkedConvert('_id', (v) => v as String),
          gymId: $checkedConvert('gymId', (v) => v as String?),
          staffId: $checkedConvert('staffId', (v) => v as String?),
          staffName: $checkedConvert('staffName', (v) => v as String),
          action: $checkedConvert('action', (v) => v as String),
          entity: $checkedConvert('entity', (v) => v as String),
          entityId: $checkedConvert('entityId', (v) => v as String?),
          details: $checkedConvert('details', (v) => v as String?),
          createdAt: $checkedConvert('createdAt', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {'id': '_id'},
    );

Map<String, dynamic> _$ActivityLogResponseToJson(ActivityLogResponse instance) {
  final val = <String, dynamic>{
    '_id': instance.id,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('gymId', instance.gymId);
  writeNotNull('staffId', instance.staffId);
  val['staffName'] = instance.staffName;
  val['action'] = instance.action;
  val['entity'] = instance.entity;
  writeNotNull('entityId', instance.entityId);
  writeNotNull('details', instance.details);
  val['createdAt'] = instance.createdAt;
  return val;
}
