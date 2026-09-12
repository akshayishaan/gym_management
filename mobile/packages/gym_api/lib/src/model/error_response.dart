//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'error_response.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ErrorResponse {
  /// Returns a new [ErrorResponse] instance.
  ErrorResponse({

    required  this.error,

     this.details,
  });

  @JsonKey(
    
    name: r'error',
    required: true,
    includeIfNull: false,
  )


  final String error;



  @JsonKey(
    
    name: r'details',
    required: false,
    includeIfNull: false,
  )


  final Object? details;




    bool operator ==(Object other) {
      return identical(this, other) ||
      other is ErrorResponse &&
      runtimeType == other.runtimeType &&
      equals(
        [
            error,
            details,
        ],
        [
            other.error,
            other.details,
        ]
      );
    }


    @override
    int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([
        error,
        details,
    ],);

  factory ErrorResponse.fromJson(Map<String, dynamic> json) => _$ErrorResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ErrorResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

