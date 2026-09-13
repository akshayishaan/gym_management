// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'membership_list_response_memberships_inner.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MembershipListResponseMembershipsInner
    _$MembershipListResponseMembershipsInnerFromJson(
            Map<String, dynamic> json) =>
        $checkedCreate(
          'MembershipListResponseMembershipsInner',
          json,
          ($checkedConvert) {
            $checkKeys(
              json,
              requiredKeys: const [
                '_id',
                'gymId',
                'memberId',
                'planName',
                'startDate',
                'expiryDate',
                'grantedBy',
                'status',
                'createdAt',
                'updatedAt'
              ],
            );
            final val = MembershipListResponseMembershipsInner(
              id: $checkedConvert('_id', (v) => v as String),
              gymId: $checkedConvert('gymId', (v) => v as String),
              memberId: $checkedConvert('memberId', (v) => v as String),
              planId: $checkedConvert('planId', (v) => v as String?),
              planName: $checkedConvert('planName', (v) => v as String),
              startDate: $checkedConvert('startDate', (v) => v as String),
              expiryDate: $checkedConvert('expiryDate', (v) => v as String),
              paymentId: $checkedConvert('paymentId', (v) => v as String?),
              planPrice: $checkedConvert('planPrice', (v) => v as num?),
              amount: $checkedConvert('amount', (v) => v as num?),
              grantedBy: $checkedConvert('grantedBy', (v) => v as String),
              notes: $checkedConvert('notes', (v) => v as String?),
              status: $checkedConvert(
                  'status',
                  (v) => $enumDecode(
                      _$MembershipListResponseMembershipsInnerStatusEnumEnumMap,
                      v)),
              expiryStatus: $checkedConvert('expiryStatus',
                  (v) => $enumDecodeNullable(_$MemberDisplayStatusEnumMap, v)),
              durationDays:
                  $checkedConvert('durationDays', (v) => (v as num?)?.toInt()),
              reversedAt: $checkedConvert('reversedAt', (v) => v as String?),
              reversedBy: $checkedConvert('reversedBy', (v) => v as String?),
              reversalReason:
                  $checkedConvert('reversalReason', (v) => v as String?),
              createdAt: $checkedConvert('createdAt', (v) => v as String),
              updatedAt: $checkedConvert('updatedAt', (v) => v as String),
            );
            return val;
          },
          fieldKeyMap: const {'id': '_id'},
        );

Map<String, dynamic> _$MembershipListResponseMembershipsInnerToJson(
    MembershipListResponseMembershipsInner instance) {
  final val = <String, dynamic>{
    '_id': instance.id,
    'gymId': instance.gymId,
    'memberId': instance.memberId,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('planId', instance.planId);
  val['planName'] = instance.planName;
  val['startDate'] = instance.startDate;
  val['expiryDate'] = instance.expiryDate;
  writeNotNull('paymentId', instance.paymentId);
  writeNotNull('planPrice', instance.planPrice);
  writeNotNull('amount', instance.amount);
  val['grantedBy'] = instance.grantedBy;
  writeNotNull('notes', instance.notes);
  val['status'] = _$MembershipListResponseMembershipsInnerStatusEnumEnumMap[
      instance.status]!;
  writeNotNull(
      'expiryStatus', _$MemberDisplayStatusEnumMap[instance.expiryStatus]);
  writeNotNull('durationDays', instance.durationDays);
  writeNotNull('reversedAt', instance.reversedAt);
  writeNotNull('reversedBy', instance.reversedBy);
  writeNotNull('reversalReason', instance.reversalReason);
  val['createdAt'] = instance.createdAt;
  val['updatedAt'] = instance.updatedAt;
  return val;
}

const _$MembershipListResponseMembershipsInnerStatusEnumEnumMap = {
  MembershipListResponseMembershipsInnerStatusEnum.active: 'active',
  MembershipListResponseMembershipsInnerStatusEnum.reversed: 'reversed',
};

const _$MemberDisplayStatusEnumMap = {
  MemberDisplayStatus.active: 'active',
  MemberDisplayStatus.expiring: 'expiring',
  MemberDisplayStatus.expired: 'expired',
};
