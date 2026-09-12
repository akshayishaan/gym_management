// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reports_response_payment_methods_inner.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReportsResponsePaymentMethodsInner _$ReportsResponsePaymentMethodsInnerFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'ReportsResponsePaymentMethodsInner',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['method', 'amount', 'count', 'percentage'],
        );
        final val = ReportsResponsePaymentMethodsInner(
          method: $checkedConvert('method', (v) => v as String),
          amount: $checkedConvert('amount', (v) => v as num),
          count: $checkedConvert('count', (v) => v as num),
          percentage: $checkedConvert('percentage', (v) => v as num),
        );
        return val;
      },
    );

Map<String, dynamic> _$ReportsResponsePaymentMethodsInnerToJson(
        ReportsResponsePaymentMethodsInner instance) =>
    <String, dynamic>{
      'method': instance.method,
      'amount': instance.amount,
      'count': instance.count,
      'percentage': instance.percentage,
    };
