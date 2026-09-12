// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'member_list_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MemberListResponse _$MemberListResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'MemberListResponse',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['members', 'total', 'page', 'limit'],
        );
        final val = MemberListResponse(
          members: $checkedConvert(
              'members',
              (v) => (v as List<dynamic>)
                  .map(
                      (e) => MemberResponse.fromJson(e as Map<String, dynamic>))
                  .toList()),
          total: $checkedConvert('total', (v) => v as num),
          page: $checkedConvert('page', (v) => v as num),
          limit: $checkedConvert('limit', (v) => v as num),
        );
        return val;
      },
    );

Map<String, dynamic> _$MemberListResponseToJson(MemberListResponse instance) =>
    <String, dynamic>{
      'members': instance.members.map((e) => e.toJson()).toList(),
      'total': instance.total,
      'page': instance.page,
      'limit': instance.limit,
    };
