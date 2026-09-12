// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reports_response_summary_revenue.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReportsResponseSummaryRevenue _$ReportsResponseSummaryRevenueFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'ReportsResponseSummaryRevenue',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['value', 'previous', 'changePercent'],
        );
        final val = ReportsResponseSummaryRevenue(
          value: $checkedConvert('value', (v) => v as num),
          previous: $checkedConvert('previous', (v) => v as num),
          changePercent: $checkedConvert('changePercent', (v) => v as num?),
        );
        return val;
      },
    );

Map<String, dynamic> _$ReportsResponseSummaryRevenueToJson(
        ReportsResponseSummaryRevenue instance) =>
    <String, dynamic>{
      'value': instance.value,
      'previous': instance.previous,
      'changePercent': instance.changePercent,
    };
