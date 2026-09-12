// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reports_response_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReportsResponseSummary _$ReportsResponseSummaryFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'ReportsResponseSummary',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'revenue',
            'transactions',
            'newMembers',
            'renewals',
            'activeMembers',
            'outstandingDues',
            'dueMembers'
          ],
        );
        final val = ReportsResponseSummary(
          revenue: $checkedConvert(
              'revenue',
              (v) => ReportsResponseSummaryRevenue.fromJson(
                  v as Map<String, dynamic>)),
          transactions: $checkedConvert(
              'transactions',
              (v) => ReportsResponseSummaryRevenue.fromJson(
                  v as Map<String, dynamic>)),
          newMembers: $checkedConvert(
              'newMembers',
              (v) => ReportsResponseSummaryRevenue.fromJson(
                  v as Map<String, dynamic>)),
          renewals: $checkedConvert(
              'renewals',
              (v) => ReportsResponseSummaryRevenue.fromJson(
                  v as Map<String, dynamic>)),
          activeMembers: $checkedConvert('activeMembers', (v) => v as num),
          outstandingDues: $checkedConvert('outstandingDues', (v) => v as num),
          dueMembers: $checkedConvert('dueMembers', (v) => v as num),
        );
        return val;
      },
    );

Map<String, dynamic> _$ReportsResponseSummaryToJson(
        ReportsResponseSummary instance) =>
    <String, dynamic>{
      'revenue': instance.revenue.toJson(),
      'transactions': instance.transactions.toJson(),
      'newMembers': instance.newMembers.toJson(),
      'renewals': instance.renewals.toJson(),
      'activeMembers': instance.activeMembers,
      'outstandingDues': instance.outstandingDues,
      'dueMembers': instance.dueMembers,
    };
