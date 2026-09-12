// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reports_response_insights.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReportsResponseInsights _$ReportsResponseInsightsFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'ReportsResponseInsights',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'expiringSoon',
            'expiredMembers',
            'dueMembers',
            'outstandingDues',
            'bestMonth'
          ],
        );
        final val = ReportsResponseInsights(
          expiringSoon: $checkedConvert('expiringSoon', (v) => v as num),
          expiredMembers: $checkedConvert('expiredMembers', (v) => v as num),
          dueMembers: $checkedConvert('dueMembers', (v) => v as num),
          outstandingDues: $checkedConvert('outstandingDues', (v) => v as num),
          bestMonth: $checkedConvert(
              'bestMonth',
              (v) => v == null
                  ? null
                  : ReportsResponseInsightsBestMonth.fromJson(
                      v as Map<String, dynamic>)),
        );
        return val;
      },
    );

Map<String, dynamic> _$ReportsResponseInsightsToJson(
        ReportsResponseInsights instance) =>
    <String, dynamic>{
      'expiringSoon': instance.expiringSoon,
      'expiredMembers': instance.expiredMembers,
      'dueMembers': instance.dueMembers,
      'outstandingDues': instance.outstandingDues,
      'bestMonth': instance.bestMonth?.toJson(),
    };
