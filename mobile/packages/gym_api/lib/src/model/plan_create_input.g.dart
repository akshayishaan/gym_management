// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_create_input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlanCreateInput _$PlanCreateInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'PlanCreateInput',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['name', 'durationDays', 'price'],
        );
        final val = PlanCreateInput(
          name: $checkedConvert('name', (v) => v as String),
          description: $checkedConvert('description', (v) => v as String?),
          durationDays:
              $checkedConvert('durationDays', (v) => (v as num).toInt()),
          price: $checkedConvert('price', (v) => v as num),
          features: $checkedConvert('features',
              (v) => (v as List<dynamic>?)?.map((e) => e as String).toList()),
          isActive: $checkedConvert('isActive', (v) => v as bool? ?? true),
        );
        return val;
      },
    );

Map<String, dynamic> _$PlanCreateInputToJson(PlanCreateInput instance) {
  final val = <String, dynamic>{
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
  writeNotNull('isActive', instance.isActive);
  return val;
}
