//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'auth_session_response_user.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AuthSessionResponseUser {
  /// Returns a new [AuthSessionResponseUser] instance.
  AuthSessionResponseUser({

    required  this.id,

    required  this.name,

    required  this.email,

    required  this.role,

    required  this.gymIds,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



  @JsonKey(
    
    name: r'email',
    required: true,
    includeIfNull: false,
  )


  final String email;



  @JsonKey(
    
    name: r'role',
    required: true,
    includeIfNull: false,
  )


  final String role;



  @JsonKey(
    
    name: r'gymIds',
    required: true,
    includeIfNull: false,
  )


  final List<String> gymIds;




    bool operator ==(Object other) {
      return identical(this, other) ||
      other is AuthSessionResponseUser &&
      runtimeType == other.runtimeType &&
      equals(
        [
            id,
            name,
            email,
            role,
            gymIds,
        ],
        [
            other.id,
            other.name,
            other.email,
            other.role,
            other.gymIds,
        ]
      );
    }


    @override
    int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([
        id,
        name,
        email,
        role,
        gymIds,
    ],);

  factory AuthSessionResponseUser.fromJson(Map<String, dynamic> json) => _$AuthSessionResponseUserFromJson(json);

  Map<String, dynamic> toJson() => _$AuthSessionResponseUserToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

