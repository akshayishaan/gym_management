// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login_input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoginInput _$LoginInputFromJson(Map<String, dynamic> json) => $checkedCreate(
      'LoginInput',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['email', 'password'],
        );
        final val = LoginInput(
          email: $checkedConvert('email', (v) => v as String),
          password: $checkedConvert('password', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$LoginInputToJson(LoginInput instance) =>
    <String, dynamic>{
      'email': instance.email,
      'password': instance.password,
    };
