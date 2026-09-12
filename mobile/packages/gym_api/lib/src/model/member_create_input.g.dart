// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'member_create_input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MemberCreateInput _$MemberCreateInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'MemberCreateInput',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['requestId', 'name', 'phone'],
        );
        final val = MemberCreateInput(
          requestId: $checkedConvert('requestId', (v) => v as String),
          name: $checkedConvert('name', (v) => v as String),
          email: $checkedConvert('email', (v) => v as String?),
          phone: $checkedConvert('phone', (v) => v as String),
          address: $checkedConvert('address', (v) => v as String?),
          photo: $checkedConvert('photo', (v) => v as String?),
          dateOfBirth: $checkedConvert('dateOfBirth', (v) => v as String?),
          gender: $checkedConvert(
              'gender',
              (v) =>
                  $enumDecodeNullable(_$MemberCreateInputGenderEnumEnumMap, v)),
          planId: $checkedConvert('planId', (v) => v as String?),
          membershipStart:
              $checkedConvert('membershipStart', (v) => v as String?),
          notes: $checkedConvert('notes', (v) => v as String?),
          emergencyContact:
              $checkedConvert('emergencyContact', (v) => v as String?),
          amountPaid: $checkedConvert('amountPaid', (v) => v as num?),
          paymentMethod: $checkedConvert(
              'paymentMethod',
              (v) => $enumDecodeNullable(
                  _$MemberCreateInputPaymentMethodEnumEnumMap, v)),
        );
        return val;
      },
    );

Map<String, dynamic> _$MemberCreateInputToJson(MemberCreateInput instance) {
  final val = <String, dynamic>{
    'requestId': instance.requestId,
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
  writeNotNull('gender', _$MemberCreateInputGenderEnumEnumMap[instance.gender]);
  writeNotNull('planId', instance.planId);
  writeNotNull('membershipStart', instance.membershipStart);
  writeNotNull('notes', instance.notes);
  writeNotNull('emergencyContact', instance.emergencyContact);
  writeNotNull('amountPaid', instance.amountPaid);
  writeNotNull('paymentMethod',
      _$MemberCreateInputPaymentMethodEnumEnumMap[instance.paymentMethod]);
  return val;
}

const _$MemberCreateInputGenderEnumEnumMap = {
  MemberCreateInputGenderEnum.male: 'male',
  MemberCreateInputGenderEnum.female: 'female',
  MemberCreateInputGenderEnum.other: 'other',
};

const _$MemberCreateInputPaymentMethodEnumEnumMap = {
  MemberCreateInputPaymentMethodEnum.cash: 'cash',
  MemberCreateInputPaymentMethodEnum.card: 'card',
  MemberCreateInputPaymentMethodEnum.upi: 'upi',
  MemberCreateInputPaymentMethodEnum.bankTransfer: 'bank_transfer',
  MemberCreateInputPaymentMethodEnum.other: 'other',
};
