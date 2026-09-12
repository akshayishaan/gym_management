// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'member_update_input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MemberUpdateInput _$MemberUpdateInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'MemberUpdateInput',
      json,
      ($checkedConvert) {
        final val = MemberUpdateInput(
          name: $checkedConvert('name', (v) => v as String?),
          email: $checkedConvert('email', (v) => v as String?),
          phone: $checkedConvert('phone', (v) => v as String?),
          address: $checkedConvert('address', (v) => v as String?),
          photo: $checkedConvert('photo', (v) => v as String?),
          dateOfBirth: $checkedConvert('dateOfBirth', (v) => v as String?),
          gender: $checkedConvert(
              'gender',
              (v) =>
                  $enumDecodeNullable(_$MemberUpdateInputGenderEnumEnumMap, v)),
          notes: $checkedConvert('notes', (v) => v as String?),
          emergencyContact:
              $checkedConvert('emergencyContact', (v) => v as String?),
          isActive: $checkedConvert('isActive', (v) => v as bool?),
        );
        return val;
      },
    );

Map<String, dynamic> _$MemberUpdateInputToJson(MemberUpdateInput instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('name', instance.name);
  writeNotNull('email', instance.email);
  writeNotNull('phone', instance.phone);
  writeNotNull('address', instance.address);
  writeNotNull('photo', instance.photo);
  writeNotNull('dateOfBirth', instance.dateOfBirth);
  writeNotNull('gender', _$MemberUpdateInputGenderEnumEnumMap[instance.gender]);
  writeNotNull('notes', instance.notes);
  writeNotNull('emergencyContact', instance.emergencyContact);
  writeNotNull('isActive', instance.isActive);
  return val;
}

const _$MemberUpdateInputGenderEnumEnumMap = {
  MemberUpdateInputGenderEnum.male: 'male',
  MemberUpdateInputGenderEnum.female: 'female',
  MemberUpdateInputGenderEnum.other: 'other',
};
