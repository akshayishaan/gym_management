//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gym_api/src/model/member_display_status.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'membership_list_response_memberships_inner.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class MembershipListResponseMembershipsInner {
  /// Returns a new [MembershipListResponseMembershipsInner] instance.
  MembershipListResponseMembershipsInner({

    required  this.id,

    required  this.gymId,

    required  this.memberId,

     this.planId,

    required  this.planName,

    required  this.startDate,

    required  this.expiryDate,

     this.paymentId,

     this.planPrice,

     this.amount,

    required  this.grantedBy,

     this.notes,

    required  this.status,

     this.expiryStatus,

     this.durationDays,

     this.reversedAt,

     this.reversedBy,

     this.reversalReason,

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



      /// Mongo ObjectId serialized as a string
  @JsonKey(
    
    name: r'planId',
    required: false,
    includeIfNull: false,
  )


  final String? planId;



  @JsonKey(
    
    name: r'planName',
    required: true,
    includeIfNull: false,
  )


  final String planName;



      /// Calendar date in YYYY-MM-DD format
  @JsonKey(
    
    name: r'startDate',
    required: true,
    includeIfNull: false,
  )


  final String startDate;



      /// Calendar date in YYYY-MM-DD format
  @JsonKey(
    
    name: r'expiryDate',
    required: true,
    includeIfNull: false,
  )


  final String expiryDate;



      /// Mongo ObjectId serialized as a string
  @JsonKey(
    
    name: r'paymentId',
    required: false,
    includeIfNull: false,
  )


  final String? paymentId;



  @JsonKey(
    
    name: r'planPrice',
    required: false,
    includeIfNull: false,
  )


  final num? planPrice;



  @JsonKey(
    
    name: r'amount',
    required: false,
    includeIfNull: false,
  )


  final num? amount;



      /// Mongo ObjectId serialized as a string
  @JsonKey(
    
    name: r'grantedBy',
    required: true,
    includeIfNull: false,
  )


  final String grantedBy;



  @JsonKey(
    
    name: r'notes',
    required: false,
    includeIfNull: false,
  )


  final String? notes;



  @JsonKey(
    
    name: r'status',
    required: true,
    includeIfNull: false,
  )


  final MembershipListResponseMembershipsInnerStatusEnum status;



  @JsonKey(
    
    name: r'expiryStatus',
    required: false,
    includeIfNull: false,
  )


  final MemberDisplayStatus? expiryStatus;



  @JsonKey(
    
    name: r'durationDays',
    required: false,
    includeIfNull: false,
  )


  final int? durationDays;



      /// ISO 8601 date-time string
  @JsonKey(
    
    name: r'reversedAt',
    required: false,
    includeIfNull: false,
  )


  final String? reversedAt;



      /// Mongo ObjectId serialized as a string
  @JsonKey(
    
    name: r'reversedBy',
    required: false,
    includeIfNull: false,
  )


  final String? reversedBy;



  @JsonKey(
    
    name: r'reversalReason',
    required: false,
    includeIfNull: false,
  )


  final String? reversalReason;



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
      other is MembershipListResponseMembershipsInner &&
      runtimeType == other.runtimeType &&
      equals(
        [
            id,
            gymId,
            memberId,
            planId,
            planName,
            startDate,
            expiryDate,
            paymentId,
            planPrice,
            amount,
            grantedBy,
            notes,
            status,
            expiryStatus,
            durationDays,
            reversedAt,
            reversedBy,
            reversalReason,
            createdAt,
            updatedAt,
        ],
        [
            other.id,
            other.gymId,
            other.memberId,
            other.planId,
            other.planName,
            other.startDate,
            other.expiryDate,
            other.paymentId,
            other.planPrice,
            other.amount,
            other.grantedBy,
            other.notes,
            other.status,
            other.expiryStatus,
            other.durationDays,
            other.reversedAt,
            other.reversedBy,
            other.reversalReason,
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
        planId,
        planName,
        startDate,
        expiryDate,
        paymentId,
        planPrice,
        amount,
        grantedBy,
        notes,
        status,
        expiryStatus,
        durationDays,
        reversedAt,
        reversedBy,
        reversalReason,
        createdAt,
        updatedAt,
    ],);

  factory MembershipListResponseMembershipsInner.fromJson(Map<String, dynamic> json) => _$MembershipListResponseMembershipsInnerFromJson(json);

  Map<String, dynamic> toJson() => _$MembershipListResponseMembershipsInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum MembershipListResponseMembershipsInnerStatusEnum {
@JsonValue(r'active')
active(r'active'),
@JsonValue(r'reversed')
reversed(r'reversed');

const MembershipListResponseMembershipsInnerStatusEnum(this.value);

final String value;

@override
String toString() => value;
}


