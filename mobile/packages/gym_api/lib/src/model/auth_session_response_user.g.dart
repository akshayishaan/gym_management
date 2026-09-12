// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_session_response_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuthSessionResponseUser _$AuthSessionResponseUserFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'AuthSessionResponseUser',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['id', 'name', 'email', 'role', 'gymIds'],
        );
        final val = AuthSessionResponseUser(
          id: $checkedConvert('id', (v) => v as String),
          name: $checkedConvert('name', (v) => v as String),
          email: $checkedConvert('email', (v) => v as String),
          role: $checkedConvert('role', (v) => v as String),
          gymIds: $checkedConvert('gymIds',
              (v) => (v as List<dynamic>).map((e) => e as String).toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$AuthSessionResponseUserToJson(
        AuthSessionResponseUser instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'email': instance.email,
      'role': instance.role,
      'gymIds': instance.gymIds,
    };
