// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'member_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MemberResponse _$MemberResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'MemberResponse',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            '_id',
            'gymId',
            'name',
            'phone',
            'dueAmount',
            'isActive',
            'createdAt',
            'updatedAt'
          ],
        );
        final val = MemberResponse(
          id: $checkedConvert('_id', (v) => v as String),
          gymId: $checkedConvert('gymId', (v) => v as String),
          name: $checkedConvert('name', (v) => v as String),
          email: $checkedConvert('email', (v) => v as String?),
          phone: $checkedConvert('phone', (v) => v as String),
          address: $checkedConvert('address', (v) => v as String?),
          photo: $checkedConvert('photo', (v) => v as String?),
          dateOfBirth: $checkedConvert('dateOfBirth', (v) => v as String?),
          gender: $checkedConvert('gender',
              (v) => $enumDecodeNullable(_$MemberResponseGenderEnumEnumMap, v)),
          planId: $checkedConvert('planId', (v) => v as String?),
          planName: $checkedConvert('planName', (v) => v as String?),
          membershipStart:
              $checkedConvert('membershipStart', (v) => v as String?),
          membershipExpiry:
              $checkedConvert('membershipExpiry', (v) => v as String?),
          notes: $checkedConvert('notes', (v) => v as String?),
          emergencyContact:
              $checkedConvert('emergencyContact', (v) => v as String?),
          dueAmount: $checkedConvert('dueAmount', (v) => v as num),
          isActive: $checkedConvert('isActive', (v) => v as bool),
          status: $checkedConvert('status',
              (v) => $enumDecodeNullable(_$MemberDisplayStatusEnumMap, v)),
          daysUntilExpiry:
              $checkedConvert('daysUntilExpiry', (v) => (v as num?)?.toInt()),
          createdAt: $checkedConvert('createdAt', (v) => v as String),
          updatedAt: $checkedConvert('updatedAt', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {'id': '_id'},
    );

Map<String, dynamic> _$MemberResponseToJson(MemberResponse instance) {
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

  writeNotNull('email', instance.email);
  val['phone'] = instance.phone;
  writeNotNull('address', instance.address);
  writeNotNull('photo', instance.photo);
  writeNotNull('dateOfBirth', instance.dateOfBirth);
  writeNotNull('gender', _$MemberResponseGenderEnumEnumMap[instance.gender]);
  writeNotNull('planId', instance.planId);
  writeNotNull('planName', instance.planName);
  writeNotNull('membershipStart', instance.membershipStart);
  writeNotNull('membershipExpiry', instance.membershipExpiry);
  writeNotNull('notes', instance.notes);
  writeNotNull('emergencyContact', instance.emergencyContact);
  val['dueAmount'] = instance.dueAmount;
  val['isActive'] = instance.isActive;
  writeNotNull('status', _$MemberDisplayStatusEnumMap[instance.status]);
  writeNotNull('daysUntilExpiry', instance.daysUntilExpiry);
  val['createdAt'] = instance.createdAt;
  val['updatedAt'] = instance.updatedAt;
  return val;
}

const _$MemberResponseGenderEnumEnumMap = {
  MemberResponseGenderEnum.male: 'male',
  MemberResponseGenderEnum.female: 'female',
  MemberResponseGenderEnum.other: 'other',
};

const _$MemberDisplayStatusEnumMap = {
  MemberDisplayStatus.active: 'active',
  MemberDisplayStatus.expiring: 'expiring',
  MemberDisplayStatus.expired: 'expired',
};
