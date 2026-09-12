//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'signup_response.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SignupResponse {
  /// Returns a new [SignupResponse] instance.
  SignupResponse({

    required  this.message,
  });

  @JsonKey(
    
    name: r'message',
    required: true,
    includeIfNull: false,
  )


  final String message;




    bool operator ==(Object other) {
      return identical(this, other) ||
      other is SignupResponse &&
      runtimeType == other.runtimeType &&
      equals(
        [
            message,
        ],
        [
            other.message,
        ]
      );
    }


    @override
    int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([
        message,
    ],);

  factory SignupResponse.fromJson(Map<String, dynamic> json) => _$SignupResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SignupResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

