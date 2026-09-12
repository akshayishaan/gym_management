//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gym_api/src/model/payment_response.dart';
import 'package:gym_api/src/model/member_response.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'member_create_response.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class MemberCreateResponse {
  /// Returns a new [MemberCreateResponse] instance.
  MemberCreateResponse({

    required  this.member,

    required  this.payment,

     this.membershipId,
  });

  @JsonKey(
    
    name: r'member',
    required: true,
    includeIfNull: false,
  )


  final MemberResponse member;



  @JsonKey(
    
    name: r'payment',
    required: true,
    includeIfNull: true,
  )


  final PaymentResponse? payment;



      /// Mongo ObjectId serialized as a string
  @JsonKey(
    
    name: r'membershipId',
    required: false,
    includeIfNull: false,
  )


  final String? membershipId;




    bool operator ==(Object other) {
      return identical(this, other) ||
      other is MemberCreateResponse &&
      runtimeType == other.runtimeType &&
      equals(
        [
            member,
            payment,
            membershipId,
        ],
        [
            other.member,
            other.payment,
            other.membershipId,
        ]
      );
    }


    @override
    int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([
        member,
        payment,
        membershipId,
    ],);

  factory MemberCreateResponse.fromJson(Map<String, dynamic> json) => _$MemberCreateResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MemberCreateResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

