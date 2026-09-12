//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'login_input.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class LoginInput {
  /// Returns a new [LoginInput] instance.
  LoginInput({

    required  this.email,

    required  this.password,
  });

  @JsonKey(
    
    name: r'email',
    required: true,
    includeIfNull: false,
  )


  final String email;



  @JsonKey(
    
    name: r'password',
    required: true,
    includeIfNull: false,
  )


  final String password;




    bool operator ==(Object other) {
      return identical(this, other) ||
      other is LoginInput &&
      runtimeType == other.runtimeType &&
      equals(
        [
            email,
            password,
        ],
        [
            other.email,
            other.password,
        ]
      );
    }


    @override
    int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([
        email,
        password,
    ],);

  factory LoginInput.fromJson(Map<String, dynamic> json) => _$LoginInputFromJson(json);

  Map<String, dynamic> toJson() => _$LoginInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

