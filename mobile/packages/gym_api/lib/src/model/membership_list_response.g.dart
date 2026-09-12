// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'membership_list_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MembershipListResponse _$MembershipListResponseFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'MembershipListResponse',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['memberships'],
        );
        final val = MembershipListResponse(
          memberships: $checkedConvert(
              'memberships',
              (v) => (v as List<dynamic>)
                  .map((e) => MembershipListResponseMembershipsInner.fromJson(
                      e as Map<String, dynamic>))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$MembershipListResponseToJson(
        MembershipListResponse instance) =>
    <String, dynamic>{
      'memberships': instance.memberships.map((e) => e.toJson()).toList(),
    };
