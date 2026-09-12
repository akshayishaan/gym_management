//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'success_response.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SuccessResponse {
  /// Returns a new [SuccessResponse] instance.
  SuccessResponse({

    required  this.success,
  });

  @JsonKey(
    
    name: r'success',
    required: true,
    includeIfNull: false,
  )


  final bool success;




    bool operator ==(Object other) {
      return identical(this, other) ||
      other is SuccessResponse &&
      runtimeType == other.runtimeType &&
      equals(
        [
            success,
        ],
        [
            other.success,
        ]
      );
    }


    @override
    int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([
        success,
    ],);

  factory SuccessResponse.fromJson(Map<String, dynamic> json) => _$SuccessResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SuccessResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

