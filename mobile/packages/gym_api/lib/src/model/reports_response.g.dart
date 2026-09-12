// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reports_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReportsResponse _$ReportsResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'ReportsResponse',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'year',
            'asOf',
            'timezone',
            'summary',
            'series',
            'planPerformance',
            'paymentMethods',
            'insights'
          ],
        );
        final val = ReportsResponse(
          year: $checkedConvert('year', (v) => v as num),
          asOf: $checkedConvert('asOf', (v) => v as String),
          timezone: $checkedConvert('timezone', (v) => v as String),
          summary: $checkedConvert(
              'summary',
              (v) =>
                  ReportsResponseSummary.fromJson(v as Map<String, dynamic>)),
          series: $checkedConvert(
              'series',
              (v) => (v as List<dynamic>)
                  .map((e) => ReportsResponseSeriesInner.fromJson(
                      e as Map<String, dynamic>))
                  .toList()),
          planPerformance: $checkedConvert(
              'planPerformance',
              (v) => (v as List<dynamic>)
                  .map((e) => ReportsResponsePlanPerformanceInner.fromJson(
                      e as Map<String, dynamic>))
                  .toList()),
          paymentMethods: $checkedConvert(
              'paymentMethods',
              (v) => (v as List<dynamic>)
                  .map((e) => ReportsResponsePaymentMethodsInner.fromJson(
                      e as Map<String, dynamic>))
                  .toList()),
          insights: $checkedConvert(
              'insights',
              (v) =>
                  ReportsResponseInsights.fromJson(v as Map<String, dynamic>)),
        );
        return val;
      },
    );

Map<String, dynamic> _$ReportsResponseToJson(ReportsResponse instance) =>
    <String, dynamic>{
      'year': instance.year,
      'asOf': instance.asOf,
      'timezone': instance.timezone,
      'summary': instance.summary.toJson(),
      'series': instance.series.map((e) => e.toJson()).toList(),
      'planPerformance':
          instance.planPerformance.map((e) => e.toJson()).toList(),
      'paymentMethods': instance.paymentMethods.map((e) => e.toJson()).toList(),
      'insights': instance.insights.toJson(),
    };
