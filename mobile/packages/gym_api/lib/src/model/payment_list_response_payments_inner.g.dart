// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_list_response_payments_inner.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaymentListResponsePaymentsInner _$PaymentListResponsePaymentsInnerFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'PaymentListResponsePaymentsInner',
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
        final val = PaymentListResponsePaymentsInner(
          id: $checkedConvert('_id', (v) => v as String),
          gymId: $checkedConvert('gymId', (v) => v as String),
          memberId: $checkedConvert('memberId', (v) => v as String),
          memberName: $checkedConvert('memberName', (v) => v as String),
          planId: $checkedConvert('planId', (v) => v as String?),
          planName: $checkedConvert('planName', (v) => v as String?),
          amount: $checkedConvert('amount', (v) => v as num),
          kind: $checkedConvert(
              'kind',
              (v) => $enumDecode(
                  _$PaymentListResponsePaymentsInnerKindEnumEnumMap, v)),
          method: $checkedConvert(
              'method',
              (v) => $enumDecode(
                  _$PaymentListResponsePaymentsInnerMethodEnumEnumMap, v)),
          status: $checkedConvert(
              'status',
              (v) => $enumDecode(
                  _$PaymentListResponsePaymentsInnerStatusEnumEnumMap, v)),
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
          membershipId: $checkedConvert('membershipId', (v) => v as String?),
          membershipStatus: $checkedConvert(
              'membershipStatus',
              (v) => $enumDecodeNullable(
                  _$PaymentListResponsePaymentsInnerMembershipStatusEnumEnumMap,
                  v)),
        );
        return val;
      },
      fieldKeyMap: const {'id': '_id'},
    );

Map<String, dynamic> _$PaymentListResponsePaymentsInnerToJson(
    PaymentListResponsePaymentsInner instance) {
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
  val['kind'] =
      _$PaymentListResponsePaymentsInnerKindEnumEnumMap[instance.kind]!;
  val['method'] =
      _$PaymentListResponsePaymentsInnerMethodEnumEnumMap[instance.method]!;
  val['status'] =
      _$PaymentListResponsePaymentsInnerStatusEnumEnumMap[instance.status]!;
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
  writeNotNull('membershipId', instance.membershipId);
  writeNotNull(
      'membershipStatus',
      _$PaymentListResponsePaymentsInnerMembershipStatusEnumEnumMap[
          instance.membershipStatus]);
  return val;
}

const _$PaymentListResponsePaymentsInnerKindEnumEnumMap = {
  PaymentListResponsePaymentsInnerKindEnum.planPurchase: 'plan_purchase',
  PaymentListResponsePaymentsInnerKindEnum.dues: 'dues',
};

const _$PaymentListResponsePaymentsInnerMethodEnumEnumMap = {
  PaymentListResponsePaymentsInnerMethodEnum.cash: 'cash',
  PaymentListResponsePaymentsInnerMethodEnum.card: 'card',
  PaymentListResponsePaymentsInnerMethodEnum.upi: 'upi',
  PaymentListResponsePaymentsInnerMethodEnum.bankTransfer: 'bank_transfer',
  PaymentListResponsePaymentsInnerMethodEnum.other: 'other',
};

const _$PaymentListResponsePaymentsInnerStatusEnumEnumMap = {
  PaymentListResponsePaymentsInnerStatusEnum.paid: 'paid',
  PaymentListResponsePaymentsInnerStatusEnum.voided: 'voided',
  PaymentListResponsePaymentsInnerStatusEnum.refunded: 'refunded',
};

const _$PaymentListResponsePaymentsInnerMembershipStatusEnumEnumMap = {
  PaymentListResponsePaymentsInnerMembershipStatusEnum.active: 'active',
  PaymentListResponsePaymentsInnerMembershipStatusEnum.reversed: 'reversed',
};
