// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lifecycle_result_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LifecycleResultResponse _$LifecycleResultResponseFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'LifecycleResultResponse',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['memberId'],
        );
        final val = LifecycleResultResponse(
          memberId: $checkedConvert('memberId', (v) => v as String),
          paymentId: $checkedConvert('paymentId', (v) => v as String?),
          membershipId: $checkedConvert('membershipId', (v) => v as String?),
          renewedUntil: $checkedConvert('renewedUntil', (v) => v as String?),
          dueAmount: $checkedConvert('dueAmount', (v) => v as num?),
        );
        return val;
      },
    );

Map<String, dynamic> _$LifecycleResultResponseToJson(
    LifecycleResultResponse instance) {
  final val = <String, dynamic>{
    'memberId': instance.memberId,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('paymentId', instance.paymentId);
  writeNotNull('membershipId', instance.membershipId);
  writeNotNull('renewedUntil', instance.renewedUntil);
  writeNotNull('dueAmount', instance.dueAmount);
  return val;
}
