//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gym_api/src/model/auth_session_response_user.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'auth_session_response.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AuthSessionResponse {
  /// Returns a new [AuthSessionResponse] instance.
  AuthSessionResponse({

    required  this.accessToken,

    required  this.refreshToken,

    required  this.user,
  });

  @JsonKey(
    
    name: r'accessToken',
    required: true,
    includeIfNull: false,
  )


  final String accessToken;



  @JsonKey(
    
    name: r'refreshToken',
    required: true,
    includeIfNull: false,
  )


  final String refreshToken;



  @JsonKey(
    
    name: r'user',
    required: true,
    includeIfNull: false,
  )


  final AuthSessionResponseUser user;




    bool operator ==(Object other) {
      return identical(this, other) ||
      other is AuthSessionResponse &&
      runtimeType == other.runtimeType &&
      equals(
        [
            accessToken,
            refreshToken,
            user,
        ],
        [
            other.accessToken,
            other.refreshToken,
            other.user,
        ]
      );
    }


    @override
    int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([
        accessToken,
        refreshToken,
        user,
    ],);

  factory AuthSessionResponse.fromJson(Map<String, dynamic> json) => _$AuthSessionResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AuthSessionResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

