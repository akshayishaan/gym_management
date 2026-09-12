//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gym_api/src/model/payment_response.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'payment_create_response.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PaymentCreateResponse {
  /// Returns a new [PaymentCreateResponse] instance.
  PaymentCreateResponse({

    required  this.memberId,

     this.paymentId,

     this.membershipId,

     this.renewedUntil,

     this.dueAmount,

    required  this.payment,
  });

      /// Mongo ObjectId serialized as a string
  @JsonKey(
    
    name: r'memberId',
    required: true,
    includeIfNull: false,
  )


  final String memberId;



      /// Mongo ObjectId serialized as a string
  @JsonKey(
    
    name: r'paymentId',
    required: false,
    includeIfNull: false,
  )


  final String? paymentId;



      /// Mongo ObjectId serialized as a string
  @JsonKey(
    
    name: r'membershipId',
    required: false,
    includeIfNull: false,
  )


  final String? membershipId;



      /// Calendar date in YYYY-MM-DD format
  @JsonKey(
    
    name: r'renewedUntil',
    required: false,
    includeIfNull: false,
  )


  final String? renewedUntil;



  @JsonKey(
    
    name: r'dueAmount',
    required: false,
    includeIfNull: false,
  )


  final num? dueAmount;



  @JsonKey(
    
    name: r'payment',
    required: true,
    includeIfNull: true,
  )


  final PaymentResponse? payment;




    bool operator ==(Object other) {
      return identical(this, other) ||
      other is PaymentCreateResponse &&
      runtimeType == other.runtimeType &&
      equals(
        [
            memberId,
            paymentId,
            membershipId,
            renewedUntil,
            dueAmount,
            payment,
        ],
        [
            other.memberId,
            other.paymentId,
            other.membershipId,
            other.renewedUntil,
            other.dueAmount,
            other.payment,
        ]
      );
    }


    @override
    int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([
        memberId,
        paymentId,
        membershipId,
        renewedUntil,
        dueAmount,
        payment,
    ],);

  factory PaymentCreateResponse.fromJson(Map<String, dynamic> json) => _$PaymentCreateResponseFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentCreateResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

