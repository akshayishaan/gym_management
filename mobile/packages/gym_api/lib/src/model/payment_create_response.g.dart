// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_create_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaymentCreateResponse _$PaymentCreateResponseFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'PaymentCreateResponse',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['memberId', 'payment'],
        );
        final val = PaymentCreateResponse(
          memberId: $checkedConvert('memberId', (v) => v as String),
          paymentId: $checkedConvert('paymentId', (v) => v as String?),
          membershipId: $checkedConvert('membershipId', (v) => v as String?),
          renewedUntil: $checkedConvert('renewedUntil', (v) => v as String?),
          dueAmount: $checkedConvert('dueAmount', (v) => v as num?),
          payment: $checkedConvert(
              'payment',
              (v) => v == null
                  ? null
                  : PaymentResponse.fromJson(v as Map<String, dynamic>)),
        );
        return val;
      },
    );

Map<String, dynamic> _$PaymentCreateResponseToJson(
    PaymentCreateResponse instance) {
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
  val['payment'] = instance.payment?.toJson();
  return val;
}
