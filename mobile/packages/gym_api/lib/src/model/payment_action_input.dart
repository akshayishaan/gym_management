//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'payment_action_input.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PaymentActionInput {
  /// Returns a new [PaymentActionInput] instance.
  PaymentActionInput({

    required  this.requestId,

     this.reason,
  });

  @JsonKey(
    
    name: r'requestId',
    required: true,
    includeIfNull: false,
  )


  final String requestId;



  @JsonKey(
    
    name: r'reason',
    required: false,
    includeIfNull: false,
  )


  final String? reason;




    bool operator ==(Object other) {
      return identical(this, other) ||
      other is PaymentActionInput &&
      runtimeType == other.runtimeType &&
      equals(
        [
            requestId,
            reason,
        ],
        [
            other.requestId,
            other.reason,
        ]
      );
    }


    @override
    int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([
        requestId,
        reason,
    ],);

  factory PaymentActionInput.fromJson(Map<String, dynamic> json) => _$PaymentActionInputFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentActionInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

