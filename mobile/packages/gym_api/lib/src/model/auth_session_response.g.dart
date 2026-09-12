// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_session_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuthSessionResponse _$AuthSessionResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'AuthSessionResponse',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['accessToken', 'refreshToken', 'user'],
        );
        final val = AuthSessionResponse(
          accessToken: $checkedConvert('accessToken', (v) => v as String),
          refreshToken: $checkedConvert('refreshToken', (v) => v as String),
          user: $checkedConvert(
              'user',
              (v) =>
                  AuthSessionResponseUser.fromJson(v as Map<String, dynamic>)),
        );
        return val;
      },
    );

Map<String, dynamic> _$AuthSessionResponseToJson(
        AuthSessionResponse instance) =>
    <String, dynamic>{
      'accessToken': instance.accessToken,
      'refreshToken': instance.refreshToken,
      'user': instance.user.toJson(),
    };
