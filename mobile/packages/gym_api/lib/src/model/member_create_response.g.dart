// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'member_create_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MemberCreateResponse _$MemberCreateResponseFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'MemberCreateResponse',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['member', 'payment'],
        );
        final val = MemberCreateResponse(
          member: $checkedConvert('member',
              (v) => MemberResponse.fromJson(v as Map<String, dynamic>)),
          payment: $checkedConvert(
              'payment',
              (v) => v == null
                  ? null
                  : PaymentResponse.fromJson(v as Map<String, dynamic>)),
          membershipId: $checkedConvert('membershipId', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$MemberCreateResponseToJson(
    MemberCreateResponse instance) {
  final val = <String, dynamic>{
    'member': instance.member.toJson(),
    'payment': instance.payment?.toJson(),
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('membershipId', instance.membershipId);
  return val;
}
