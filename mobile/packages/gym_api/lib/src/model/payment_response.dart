//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'payment_response.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PaymentResponse {
  /// Returns a new [PaymentResponse] instance.
  PaymentResponse({

    required  this.id,

    required  this.gymId,

    required  this.memberId,

    required  this.memberName,

     this.planId,

     this.planName,

    required  this.amount,

    required  this.kind,

    required  this.method,

    required  this.status,

    required  this.invoiceNumber,

     this.notes,

    required  this.paidAt,

     this.createdBy,

     this.voidedAt,

     this.voidedBy,

     this.voidReason,

     this.refundedAt,

     this.refundedBy,

     this.refundReason,

    required  this.createdAt,

    required  this.updatedAt,
  });

      /// Mongo ObjectId serialized as a string
  @JsonKey(
    
    name: r'_id',
    required: true,
    includeIfNull: false,
  )


  final String id;



      /// Mongo ObjectId serialized as a string
  @JsonKey(
    
    name: r'gymId',
    required: true,
    includeIfNull: false,
  )


  final String gymId;



      /// Mongo ObjectId serialized as a string
  @JsonKey(
    
    name: r'memberId',
    required: true,
    includeIfNull: false,
  )


  final String memberId;



  @JsonKey(
    
    name: r'memberName',
    required: true,
    includeIfNull: false,
  )


  final String memberName;



      /// Mongo ObjectId serialized as a string
  @JsonKey(
    
    name: r'planId',
    required: false,
    includeIfNull: false,
  )


  final String? planId;



  @JsonKey(
    
    name: r'planName',
    required: false,
    includeIfNull: false,
  )


  final String? planName;



  @JsonKey(
    
    name: r'amount',
    required: true,
    includeIfNull: false,
  )


  final num amount;



  @JsonKey(
    
    name: r'kind',
    required: true,
    includeIfNull: false,
  )


  final PaymentResponseKindEnum kind;



  @JsonKey(
    
    name: r'method',
    required: true,
    includeIfNull: false,
  )


  final PaymentResponseMethodEnum method;



  @JsonKey(
    
    name: r'status',
    required: true,
    includeIfNull: false,
  )


  final PaymentResponseStatusEnum status;



  @JsonKey(
    
    name: r'invoiceNumber',
    required: true,
    includeIfNull: false,
  )


  final String invoiceNumber;



  @JsonKey(
    
    name: r'notes',
    required: false,
    includeIfNull: false,
  )


  final String? notes;



      /// ISO 8601 date-time string
  @JsonKey(
    
    name: r'paidAt',
    required: true,
    includeIfNull: false,
  )


  final String paidAt;



      /// Mongo ObjectId serialized as a string
  @JsonKey(
    
    name: r'createdBy',
    required: false,
    includeIfNull: false,
  )


  final String? createdBy;



      /// ISO 8601 date-time string
  @JsonKey(
    
    name: r'voidedAt',
    required: false,
    includeIfNull: false,
  )


  final String? voidedAt;



      /// Mongo ObjectId serialized as a string
  @JsonKey(
    
    name: r'voidedBy',
    required: false,
    includeIfNull: false,
  )


  final String? voidedBy;



  @JsonKey(
    
    name: r'voidReason',
    required: false,
    includeIfNull: false,
  )


  final String? voidReason;



      /// ISO 8601 date-time string
  @JsonKey(
    
    name: r'refundedAt',
    required: false,
    includeIfNull: false,
  )


  final String? refundedAt;



      /// Mongo ObjectId serialized as a string
  @JsonKey(
    
    name: r'refundedBy',
    required: false,
    includeIfNull: false,
  )


  final String? refundedBy;



  @JsonKey(
    
    name: r'refundReason',
    required: false,
    includeIfNull: false,
  )


  final String? refundReason;



      /// ISO 8601 date-time string
  @JsonKey(
    
    name: r'createdAt',
    required: true,
    includeIfNull: false,
  )


  final String createdAt;



      /// ISO 8601 date-time string
  @JsonKey(
    
    name: r'updatedAt',
    required: true,
    includeIfNull: false,
  )


  final String updatedAt;




    bool operator ==(Object other) {
      return identical(this, other) ||
      other is PaymentResponse &&
      runtimeType == other.runtimeType &&
      equals(
        [
            id,
            gymId,
            memberId,
            memberName,
            planId,
            planName,
            amount,
            kind,
            method,
            status,
            invoiceNumber,
            notes,
            paidAt,
            createdBy,
            voidedAt,
            voidedBy,
            voidReason,
            refundedAt,
            refundedBy,
            refundReason,
            createdAt,
            updatedAt,
        ],
        [
            other.id,
            other.gymId,
            other.memberId,
            other.memberName,
            other.planId,
            other.planName,
            other.amount,
            other.kind,
            other.method,
            other.status,
            other.invoiceNumber,
            other.notes,
            other.paidAt,
            other.createdBy,
            other.voidedAt,
            other.voidedBy,
            other.voidReason,
            other.refundedAt,
            other.refundedBy,
            other.refundReason,
            other.createdAt,
            other.updatedAt,
        ]
      );
    }


    @override
    int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([
        id,
        gymId,
        memberId,
        memberName,
        planId,
        planName,
        amount,
        kind,
        method,
        status,
        invoiceNumber,
        notes,
        paidAt,
        createdBy,
        voidedAt,
        voidedBy,
        voidReason,
        refundedAt,
        refundedBy,
        refundReason,
        createdAt,
        updatedAt,
    ],);

  factory PaymentResponse.fromJson(Map<String, dynamic> json) => _$PaymentResponseFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum PaymentResponseKindEnum {
@JsonValue(r'plan_purchase')
planPurchase(r'plan_purchase'),
@JsonValue(r'dues')
dues(r'dues');

const PaymentResponseKindEnum(this.value);

final String value;

@override
String toString() => value;
}



enum PaymentResponseMethodEnum {
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

const PaymentResponseMethodEnum(this.value);

final String value;

@override
String toString() => value;
}



enum PaymentResponseStatusEnum {
@JsonValue(r'paid')
paid(r'paid'),
@JsonValue(r'voided')
voided(r'voided'),
@JsonValue(r'refunded')
refunded(r'refunded');

const PaymentResponseStatusEnum(this.value);

final String value;

@override
String toString() => value;
}


