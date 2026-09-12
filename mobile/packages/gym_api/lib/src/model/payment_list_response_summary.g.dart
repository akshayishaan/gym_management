// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_list_response_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaymentListResponseSummary _$PaymentListResponseSummaryFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'PaymentListResponseSummary',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['netAmount'],
        );
        final val = PaymentListResponseSummary(
          netAmount: $checkedConvert('netAmount', (v) => v as num),
        );
        return val;
      },
    );

Map<String, dynamic> _$PaymentListResponseSummaryToJson(
        PaymentListResponseSummary instance) =>
    <String, dynamic>{
      'netAmount': instance.netAmount,
    };
