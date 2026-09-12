//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'payment_create_input.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PaymentCreateInput {
  /// Returns a new [PaymentCreateInput] instance.
  PaymentCreateInput({

    required  this.requestId,

    required  this.memberId,

     this.planId,

    required  this.amount,

    required  this.method,

     this.membershipStart,

     this.notes,
  });

  @JsonKey(
    
    name: r'requestId',
    required: true,
    includeIfNull: false,
  )


  final String requestId;



  @JsonKey(
    
    name: r'memberId',
    required: true,
    includeIfNull: false,
  )


  final String memberId;



  @JsonKey(
    
    name: r'planId',
    required: false,
    includeIfNull: false,
  )


  final String? planId;



          // minimum: 0
  @JsonKey(
    
    name: r'amount',
    required: true,
    includeIfNull: false,
  )


  final num amount;



  @JsonKey(
    
    name: r'method',
    required: true,
    includeIfNull: false,
  )


  final PaymentCreateInputMethodEnum method;



  @JsonKey(
    
    name: r'membershipStart',
    required: false,
    includeIfNull: false,
  )


  final String? membershipStart;



  @JsonKey(
    
    name: r'notes',
    required: false,
    includeIfNull: false,
  )


  final String? notes;




    bool operator ==(Object other) {
      return identical(this, other) ||
      other is PaymentCreateInput &&
      runtimeType == other.runtimeType &&
      equals(
        [
            requestId,
            memberId,
            planId,
            amount,
            method,
            membershipStart,
            notes,
        ],
        [
            other.requestId,
            other.memberId,
            other.planId,
            other.amount,
            other.method,
            other.membershipStart,
            other.notes,
        ]
      );
    }


    @override
    int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([
        requestId,
        memberId,
        planId,
        amount,
        method,
        membershipStart,
        notes,
    ],);

  factory PaymentCreateInput.fromJson(Map<String, dynamic> json) => _$PaymentCreateInputFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentCreateInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum PaymentCreateInputMethodEnum {
@JsonValue(r'cash')
cash(r'cash'),
@JsonValue(r'card')
card(r'card'),
@JsonValue(r'upi')
upi(r'upi'),
@JsonValue(r'bank_transfer')
bankTransfer(r'bank_transfer'),
@JsonValue(r'other')
other(r'other');

const PaymentCreateInputMethodEnum(this.value);

final String value;

@override
String toString() => value;
}


