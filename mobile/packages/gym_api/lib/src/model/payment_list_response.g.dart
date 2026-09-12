// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_list_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaymentListResponse _$PaymentListResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'PaymentListResponse',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['payments', 'total', 'page', 'limit', 'summary'],
        );
        final val = PaymentListResponse(
          payments: $checkedConvert(
              'payments',
              (v) => (v as List<dynamic>)
                  .map((e) => PaymentListResponsePaymentsInner.fromJson(
                      e as Map<String, dynamic>))
                  .toList()),
          total: $checkedConvert('total', (v) => v as num),
          page: $checkedConvert('page', (v) => v as num),
          limit: $checkedConvert('limit', (v) => v as num),
          summary: $checkedConvert(
              'summary',
              (v) => PaymentListResponseSummary.fromJson(
                  v as Map<String, dynamic>)),
        );
        return val;
      },
    );

Map<String, dynamic> _$PaymentListResponseToJson(
        PaymentListResponse instance) =>
    <String, dynamic>{
      'payments': instance.payments.map((e) => e.toJson()).toList(),
      'total': instance.total,
      'page': instance.page,
      'limit': instance.limit,
      'summary': instance.summary.toJson(),
    };
