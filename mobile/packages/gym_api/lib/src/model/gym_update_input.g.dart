// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gym_update_input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GymUpdateInput _$GymUpdateInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'GymUpdateInput',
      json,
      ($checkedConvert) {
        final val = GymUpdateInput(
          name: $checkedConvert('name', (v) => v as String?),
          logo: $checkedConvert('logo', (v) => v as String?),
          primaryColor: $checkedConvert('primaryColor', (v) => v as String?),
          address: $checkedConvert('address', (v) => v as String?),
          phone: $checkedConvert('phone', (v) => v as String?),
          email: $checkedConvert('email', (v) => v as String?),
          currency: $checkedConvert('currency', (v) => v as String?),
          timezone: $checkedConvert('timezone', (v) => v as String?),
          expiryReminderDays: $checkedConvert(
              'expiryReminderDays', (v) => (v as num?)?.toInt()),
          isActive: $checkedConvert('isActive', (v) => v as bool?),
        );
        return val;
      },
    );

Map<String, dynamic> _$GymUpdateInputToJson(GymUpdateInput instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('name', instance.name);
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
