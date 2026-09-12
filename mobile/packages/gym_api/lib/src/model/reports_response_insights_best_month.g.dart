// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reports_response_insights_best_month.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReportsResponseInsightsBestMonth _$ReportsResponseInsightsBestMonthFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'ReportsResponseInsightsBestMonth',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['month', 'revenue'],
        );
        final val = ReportsResponseInsightsBestMonth(
          month: $checkedConvert('month', (v) => v as num),
          revenue: $checkedConvert('revenue', (v) => v as num),
        );
        return val;
      },
    );

Map<String, dynamic> _$ReportsResponseInsightsBestMonthToJson(
        ReportsResponseInsightsBestMonth instance) =>
    <String, dynamic>{
      'month': instance.month,
      'revenue': instance.revenue,
    };
