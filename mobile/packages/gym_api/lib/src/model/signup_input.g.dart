// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'signup_input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SignupInput _$SignupInputFromJson(Map<String, dynamic> json) => $checkedCreate(
      'SignupInput',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['name', 'email', 'password'],
        );
        final val = SignupInput(
          name: $checkedConvert('name', (v) => v as String),
          email: $checkedConvert('email', (v) => v as String),
          password: $checkedConvert('password', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$SignupInputToJson(SignupInput instance) =>
    <String, dynamic>{
      'name': instance.name,
      'email': instance.email,
      'password': instance.password,
    };
