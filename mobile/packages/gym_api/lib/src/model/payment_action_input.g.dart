// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_action_input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaymentActionInput _$PaymentActionInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'PaymentActionInput',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['requestId'],
        );
        final val = PaymentActionInput(
          requestId: $checkedConvert('requestId', (v) => v as String),
          reason: $checkedConvert('reason', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$PaymentActionInputToJson(PaymentActionInput instance) {
  final val = <String, dynamic>{
    'requestId': instance.requestId,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('reason', instance.reason);
  return val;
}
