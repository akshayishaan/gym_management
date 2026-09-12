//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'member_create_input.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class MemberCreateInput {
  /// Returns a new [MemberCreateInput] instance.
  MemberCreateInput({

    required  this.requestId,

    required  this.name,

     this.email,

    required  this.phone,

     this.address,

     this.photo,

     this.dateOfBirth,

     this.gender,

     this.planId,

     this.membershipStart,

     this.notes,

     this.emergencyContact,

     this.amountPaid,

     this.paymentMethod,
  });

  @JsonKey(
    
    name: r'requestId',
    required: true,
    includeIfNull: false,
  )


  final String requestId;



  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



  @JsonKey(
    
    name: r'email',
    required: false,
    includeIfNull: false,
  )


  final String? email;



  @JsonKey(
    
    name: r'phone',
    required: true,
    includeIfNull: false,
  )


  final String phone;



  @JsonKey(
    
    name: r'address',
    required: false,
    includeIfNull: false,
  )


  final String? address;



  @JsonKey(
    
    name: r'photo',
    required: false,
    includeIfNull: false,
  )


  final String? photo;



  @JsonKey(
    
    name: r'dateOfBirth',
    required: false,
    includeIfNull: false,
  )


  final String? dateOfBirth;



  @JsonKey(
    
    name: r'gender',
    required: false,
    includeIfNull: false,
  )


  final MemberCreateInputGenderEnum? gender;



  @JsonKey(
    
    name: r'planId',
    required: false,
    includeIfNull: false,
  )


  final String? planId;



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



  @JsonKey(
    
    name: r'emergencyContact',
    required: false,
    includeIfNull: false,
  )


  final String? emergencyContact;



          // minimum: 0
  @JsonKey(
    
    name: r'amountPaid',
    required: false,
    includeIfNull: false,
  )


  final num? amountPaid;



  @JsonKey(
    
    name: r'paymentMethod',
    required: false,
    includeIfNull: false,
  )


  final MemberCreateInputPaymentMethodEnum? paymentMethod;




    bool operator ==(Object other) {
      return identical(this, other) ||
      other is MemberCreateInput &&
      runtimeType == other.runtimeType &&
      equals(
        [
            requestId,
            name,
            email,
            phone,
            address,
            photo,
            dateOfBirth,
            gender,
            planId,
            membershipStart,
            notes,
            emergencyContact,
            amountPaid,
            paymentMethod,
        ],
        [
            other.requestId,
            other.name,
            other.email,
            other.phone,
            other.address,
            other.photo,
            other.dateOfBirth,
            other.gender,
            other.planId,
            other.membershipStart,
            other.notes,
            other.emergencyContact,
            other.amountPaid,
            other.paymentMethod,
        ]
      );
    }


    @override
    int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([
        requestId,
        name,
        email,
        phone,
        address,
        photo,
        dateOfBirth,
        gender,
        planId,
        membershipStart,
        notes,
        emergencyContact,
        amountPaid,
        paymentMethod,
    ],);

  factory MemberCreateInput.fromJson(Map<String, dynamic> json) => _$MemberCreateInputFromJson(json);

  Map<String, dynamic> toJson() => _$MemberCreateInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum MemberCreateInputGenderEnum {
@JsonValue(r'male')
male(r'male'),
@JsonValue(r'female')
female(r'female'),
@JsonValue(r'other')
other(r'other');

const MemberCreateInputGenderEnum(this.value);

final String value;

@override
String toString() => value;
}



enum MemberCreateInputPaymentMethodEnum {
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

const MemberCreateInputPaymentMethodEnum(this.value);

final String value;

@override
String toString() => value;
}


