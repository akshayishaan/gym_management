// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gym_create_input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GymCreateInput _$GymCreateInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'GymCreateInput',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['name'],
        );
        final val = GymCreateInput(
          name: $checkedConvert('name', (v) => v as String),
          logo: $checkedConvert('logo', (v) => v as String?),
          primaryColor:
              $checkedConvert('primaryColor', (v) => v as String? ?? '#6366f1'),
          address: $checkedConvert('address', (v) => v as String?),
          phone: $checkedConvert('phone', (v) => v as String?),
          email: $checkedConvert('email', (v) => v as String?),
          currency: $checkedConvert('currency', (v) => v as String? ?? 'INR'),
          timezone: $checkedConvert(
              'timezone', (v) => v as String? ?? 'Asia/Kolkata'),
          expiryReminderDays: $checkedConvert(
              'expiryReminderDays', (v) => (v as num?)?.toInt() ?? 7),
          isActive: $checkedConvert('isActive', (v) => v as bool? ?? true),
        );
        return val;
      },
    );

Map<String, dynamic> _$GymCreateInputToJson(GymCreateInput instance) {
  final val = <String, dynamic>{
    'name': instance.name,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('logo', instance.logo);
  writeNotNull('primaryColor', instance.primaryColor);
  writeNotNull('address', instance.address);
  writeNotNull('phone', instance.phone);
  writeNotNull('email', instance.email);
  writeNotNull('currency', instance.currency);
  writeNotNull('timezone', instance.timezone);
  writeNotNull('expiryReminderDays', instance.expiryReminderDays);
  writeNotNull('isActive', instance.isActive);
  return val;
}
