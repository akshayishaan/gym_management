// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_response_recent_payments_inner.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DashboardResponseRecentPaymentsInner
    _$DashboardResponseRecentPaymentsInnerFromJson(Map<String, dynamic> json) =>
        $checkedCreate(
          'DashboardResponseRecentPaymentsInner',
          json,
          ($checkedConvert) {
            $checkKeys(
              json,
              requiredKeys: const [
                '_id',
                'memberName',
                'amount',
                'paidAt',
                'method'
              ],
            );
            final val = DashboardResponseRecentPaymentsInner(
              id: $checkedConvert('_id', (v) => v as String),
              memberName: $checkedConvert('memberName', (v) => v as String),
              amount: $checkedConvert('amount', (v) => v as num),
              paidAt: $checkedConvert('paidAt', (v) => v as String),
              method: $checkedConvert(
                  'method',
                  (v) => $enumDecode(
                      _$DashboardResponseRecentPaymentsInnerMethodEnumEnumMap,
                      v)),
            );
            return val;
          },
          fieldKeyMap: const {'id': '_id'},
        );

Map<String, dynamic> _$DashboardResponseRecentPaymentsInnerToJson(
        DashboardResponseRecentPaymentsInner instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'memberName': instance.memberName,
      'amount': instance.amount,
      'paidAt': instance.paidAt,
      'method': _$DashboardResponseRecentPaymentsInnerMethodEnumEnumMap[
          instance.method]!,
    };

const _$DashboardResponseRecentPaymentsInnerMethodEnumEnumMap = {
  DashboardResponseRecentPaymentsInnerMethodEnum.cash: 'cash',
  DashboardResponseRecentPaymentsInnerMethodEnum.card: 'card',
  DashboardResponseRecentPaymentsInnerMethodEnum.upi: 'upi',
  DashboardResponseRecentPaymentsInnerMethodEnum.bankTransfer: 'bank_transfer',
  DashboardResponseRecentPaymentsInnerMethodEnum.other: 'other',
};
