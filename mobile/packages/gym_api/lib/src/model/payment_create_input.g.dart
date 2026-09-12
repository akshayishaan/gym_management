// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_create_input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaymentCreateInput _$PaymentCreateInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'PaymentCreateInput',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['requestId', 'memberId', 'amount', 'method'],
        );
        final val = PaymentCreateInput(
          requestId: $checkedConvert('requestId', (v) => v as String),
          memberId: $checkedConvert('memberId', (v) => v as String),
          planId: $checkedConvert('planId', (v) => v as String?),
          amount: $checkedConvert('amount', (v) => v as num),
          method: $checkedConvert('method',
              (v) => $enumDecode(_$PaymentCreateInputMethodEnumEnumMap, v)),
          membershipStart:
              $checkedConvert('membershipStart', (v) => v as String?),
          notes: $checkedConvert('notes', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$PaymentCreateInputToJson(PaymentCreateInput instance) {
  final val = <String, dynamic>{
    'requestId': instance.requestId,
    'memberId': instance.memberId,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('planId', instance.planId);
  val['amount'] = instance.amount;
  val['method'] = _$PaymentCreateInputMethodEnumEnumMap[instance.method]!;
  writeNotNull('membershipStart', instance.membershipStart);
  writeNotNull('notes', instance.notes);
  return val;
}

const _$PaymentCreateInputMethodEnumEnumMap = {
  PaymentCreateInputMethodEnum.cash: 'cash',
  PaymentCreateInputMethodEnum.card: 'card',
  PaymentCreateInputMethodEnum.upi: 'upi',
  PaymentCreateInputMethodEnum.bankTransfer: 'bank_transfer',
  PaymentCreateInputMethodEnum.other: 'other',
};
