// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reports_response_series_inner.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReportsResponseSeriesInner _$ReportsResponseSeriesInnerFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'ReportsResponseSeriesInner',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'month',
            'revenue',
            'transactions',
            'newMembers',
            'memberships',
            'renewals'
          ],
        );
        final val = ReportsResponseSeriesInner(
          month: $checkedConvert('month', (v) => v as num),
          revenue: $checkedConvert('revenue', (v) => v as num),
          transactions: $checkedConvert('transactions', (v) => v as num),
          newMembers: $checkedConvert('newMembers', (v) => v as num),
          memberships: $checkedConvert('memberships', (v) => v as num),
          renewals: $checkedConvert('renewals', (v) => v as num),
        );
        return val;
      },
    );

Map<String, dynamic> _$ReportsResponseSeriesInnerToJson(
        ReportsResponseSeriesInner instance) =>
    <String, dynamic>{
      'month': instance.month,
      'revenue': instance.revenue,
      'transactions': instance.transactions,
      'newMembers': instance.newMembers,
      'memberships': instance.memberships,
      'renewals': instance.renewals,
    };
