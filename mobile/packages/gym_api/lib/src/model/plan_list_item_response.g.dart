// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_list_item_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlanListItemResponse _$PlanListItemResponseFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'PlanListItemResponse',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            '_id',
            'gymId',
            'name',
            'durationDays',
            'price',
            'isActive',
            'createdAt',
            'updatedAt'
          ],
        );
        final val = PlanListItemResponse(
          id: $checkedConvert('_id', (v) => v as String),
          gymId: $checkedConvert('gymId', (v) => v as String),
          name: $checkedConvert('name', (v) => v as String),
          description: $checkedConvert('description', (v) => v as String?),
          durationDays: $checkedConvert('durationDays', (v) => v as num),
          price: $checkedConvert('price', (v) => v as num),
          features: $checkedConvert('features',
              (v) => (v as List<dynamic>?)?.map((e) => e as String).toList()),
          isActive: $checkedConvert('isActive', (v) => v as bool),
          createdAt: $checkedConvert('createdAt', (v) => v as String),
          updatedAt: $checkedConvert('updatedAt', (v) => v as String),
          stats: $checkedConvert(
              'stats',
              (v) => v == null
                  ? null
                  : PlanListItemResponseStats.fromJson(
                      v as Map<String, dynamic>)),
        );
        return val;
      },
      fieldKeyMap: const {'id': '_id'},
    );

Map<String, dynamic> _$PlanListItemResponseToJson(
    PlanListItemResponse instance) {
  final val = <String, dynamic>{
    '_id': instance.id,
    'gymId': instance.gymId,
    'name': instance.name,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('description', instance.description);
  val['durationDays'] = instance.durationDays;
  val['price'] = instance.price;
  writeNotNull('features', instance.features);
  val['isActive'] = instance.isActive;
  val['createdAt'] = instance.createdAt;
  val['updatedAt'] = instance.updatedAt;
  writeNotNull('stats', instance.stats?.toJson());
  return val;
}
