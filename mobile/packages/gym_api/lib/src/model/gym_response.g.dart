// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gym_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GymResponse _$GymResponseFromJson(Map<String, dynamic> json) => $checkedCreate(
      'GymResponse',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            '_id',
            'name',
            'primaryColor',
            'currency',
            'timezone',
            'expiryReminderDays',
            'isActive',
            'createdAt',
            'updatedAt'
          ],
        );
        final val = GymResponse(
          id: $checkedConvert('_id', (v) => v as String),
          name: $checkedConvert('name', (v) => v as String),
          logo: $checkedConvert('logo', (v) => v as String?),
          primaryColor: $checkedConvert('primaryColor', (v) => v as String),
          address: $checkedConvert('address', (v) => v as String?),
          phone: $checkedConvert('phone', (v) => v as String?),
          email: $checkedConvert('email', (v) => v as String?),
          currency: $checkedConvert('currency', (v) => v as String),
          timezone: $checkedConvert('timezone', (v) => v as String),
          expiryReminderDays:
              $checkedConvert('expiryReminderDays', (v) => v as num),
          isActive: $checkedConvert('isActive', (v) => v as bool),
          ownerId: $checkedConvert('ownerId', (v) => v as String?),
          createdAt: $checkedConvert('createdAt', (v) => v as String),
          updatedAt: $checkedConvert('updatedAt', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {'id': '_id'},
    );

Map<String, dynamic> _$GymResponseToJson(GymResponse instance) {
  final val = <String, dynamic>{
    '_id': instance.id,
    'name': instance.name,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('logo', instance.logo);
  val['primaryColor'] = instance.primaryColor;
  writeNotNull('address', instance.address);
  writeNotNull('phone', instance.phone);
  writeNotNull('email', instance.email);
  val['currency'] = instance.currency;
  val['timezone'] = instance.timezone;
  val['expiryReminderDays'] = instance.expiryReminderDays;
  val['isActive'] = instance.isActive;
  writeNotNull('ownerId', instance.ownerId);
  val['createdAt'] = instance.createdAt;
  val['updatedAt'] = instance.updatedAt;
  return val;
}
