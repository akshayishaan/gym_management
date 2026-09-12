// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_update_input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlanUpdateInput _$PlanUpdateInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'PlanUpdateInput',
      json,
      ($checkedConvert) {
        final val = PlanUpdateInput(
          name: $checkedConvert('name', (v) => v as String?),
          description: $checkedConvert('description', (v) => v as String?),
          durationDays:
              $checkedConvert('durationDays', (v) => (v as num?)?.toInt()),
          price: $checkedConvert('price', (v) => v as num?),
          features: $checkedConvert('features',
              (v) => (v as List<dynamic>?)?.map((e) => e as String).toList()),
          isActive: $checkedConvert('isActive', (v) => v as bool?),
        );
        return val;
      },
    );

Map<String, dynamic> _$PlanUpdateInputToJson(PlanUpdateInput instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('name', instance.name);
  writeNotNull('description', instance.description);
  writeNotNull('durationDays', instance.durationDays);
  writeNotNull('price', instance.price);
  writeNotNull('features', instance.features);
  writeNotNull('isActive', instance.isActive);
  return val;
}
