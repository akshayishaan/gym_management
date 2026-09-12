//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'signup_input.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SignupInput {
  /// Returns a new [SignupInput] instance.
  SignupInput({

    required  this.name,

    required  this.email,

    required  this.password,
  });

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
    
    name: r'password',
    required: true,
    includeIfNull: false,
  )


  final String password;




    bool operator ==(Object other) {
      return identical(this, other) ||
      other is SignupInput &&
      runtimeType == other.runtimeType &&
      equals(
        [
            name,
            email,
            password,
        ],
        [
            other.name,
            other.email,
            other.password,
        ]
      );
    }


    @override
    int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([
        name,
        email,
        password,
    ],);

  factory SignupInput.fromJson(Map<String, dynamic> json) => _$SignupInputFromJson(json);

  Map<String, dynamic> toJson() => _$SignupInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

