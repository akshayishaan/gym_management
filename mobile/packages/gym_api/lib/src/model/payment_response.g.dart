// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaymentResponse _$PaymentResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'PaymentResponse',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            '_id',
            'gymId',
            'memberId',
            'memberName',
            'amount',
            'kind',
            'method',
            'status',
            'invoiceNumber',
            'paidAt',
            'createdAt',
            'updatedAt'
          ],
        );
        final val = PaymentResponse(
          id: $checkedConvert('_id', (v) => v as String),
          gymId: $checkedConvert('gymId', (v) => v as String),
          memberId: $checkedConvert('memberId', (v) => v as String),
          memberName: $checkedConvert('memberName', (v) => v as String),
          planId: $checkedConvert('planId', (v) => v as String?),
          planName: $checkedConvert('planName', (v) => v as String?),
          amount: $checkedConvert('amount', (v) => v as num),
          kind: $checkedConvert(
              'kind', (v) => $enumDecode(_$PaymentResponseKindEnumEnumMap, v)),
          method: $checkedConvert('method',
              (v) => $enumDecode(_$PaymentResponseMethodEnumEnumMap, v)),
          status: $checkedConvert('status',
              (v) => $enumDecode(_$PaymentResponseStatusEnumEnumMap, v)),
          invoiceNumber: $checkedConvert('invoiceNumber', (v) => v as String),
          notes: $checkedConvert('notes', (v) => v as String?),
          paidAt: $checkedConvert('paidAt', (v) => v as String),
          createdBy: $checkedConvert('createdBy', (v) => v as String?),
          voidedAt: $checkedConvert('voidedAt', (v) => v as String?),
          voidedBy: $checkedConvert('voidedBy', (v) => v as String?),
          voidReason: $checkedConvert('voidReason', (v) => v as String?),
          refundedAt: $checkedConvert('refundedAt', (v) => v as String?),
          refundedBy: $checkedConvert('refundedBy', (v) => v as String?),
          refundReason: $checkedConvert('refundReason', (v) => v as String?),
          createdAt: $checkedConvert('createdAt', (v) => v as String),
          updatedAt: $checkedConvert('updatedAt', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {'id': '_id'},
    );

Map<String, dynamic> _$PaymentResponseToJson(PaymentResponse instance) {
  final val = <String, dynamic>{
    '_id': instance.id,
    'gymId': instance.gymId,
    'memberId': instance.memberId,
    'memberName': instance.memberName,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('planId', instance.planId);
  writeNotNull('planName', instance.planName);
  val['amount'] = instance.amount;
  val['kind'] = _$PaymentResponseKindEnumEnumMap[instance.kind]!;
  val['method'] = _$PaymentResponseMethodEnumEnumMap[instance.method]!;
  val['status'] = _$PaymentResponseStatusEnumEnumMap[instance.status]!;
  val['invoiceNumber'] = instance.invoiceNumber;
  writeNotNull('notes', instance.notes);
  val['paidAt'] = instance.paidAt;
  writeNotNull('createdBy', instance.createdBy);
  writeNotNull('voidedAt', instance.voidedAt);
  writeNotNull('voidedBy', instance.voidedBy);
  writeNotNull('voidReason', instance.voidReason);
  writeNotNull('refundedAt', instance.refundedAt);
  writeNotNull('refundedBy', instance.refundedBy);
  writeNotNull('refundReason', instance.refundReason);
  val['createdAt'] = instance.createdAt;
  val['updatedAt'] = instance.updatedAt;
  return val;
}

const _$PaymentResponseKindEnumEnumMap = {
  PaymentResponseKindEnum.planPurchase: 'plan_purchase',
  PaymentResponseKindEnum.dues: 'dues',
};

const _$PaymentResponseMethodEnumEnumMap = {
  PaymentResponseMethodEnum.cash: 'cash',
  PaymentResponseMethodEnum.card: 'card',
  PaymentResponseMethodEnum.upi: 'upi',
  PaymentResponseMethodEnum.bankTransfer: 'bank_transfer',
  PaymentResponseMethodEnum.other: 'other',
};

const _$PaymentResponseStatusEnumEnumMap = {
  PaymentResponseStatusEnum.paid: 'paid',
  PaymentResponseStatusEnum.voided: 'voided',
  PaymentResponseStatusEnum.refunded: 'refunded',
};
