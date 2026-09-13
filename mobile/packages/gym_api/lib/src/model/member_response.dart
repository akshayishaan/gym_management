//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gym_api/src/model/member_display_status.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'member_response.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class MemberResponse {
  /// Returns a new [MemberResponse] instance.
  MemberResponse({

    required  this.id,

    required  this.gymId,

    required  this.name,

     this.email,

    required  this.phone,

     this.address,

     this.photo,

     this.dateOfBirth,

     this.gender,

     this.planId,

     this.planName,

     this.membershipStart,

     this.membershipExpiry,

     this.notes,

     this.emergencyContact,

    required  this.dueAmount,

    required  this.isActive,

     this.status,

     this.daysUntilExpiry,

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



      /// ISO 8601 date-time string
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


  final MemberResponseGenderEnum? gender;



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



      /// Calendar date in YYYY-MM-DD format
  @JsonKey(
    
    name: r'membershipStart',
    required: false,
    includeIfNull: false,
  )


  final String? membershipStart;



      /// Calendar date in YYYY-MM-DD format
  @JsonKey(
    
    name: r'membershipExpiry',
    required: false,
    includeIfNull: false,
  )


  final String? membershipExpiry;



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



  @JsonKey(
    
    name: r'dueAmount',
    required: true,
    includeIfNull: false,
  )


  final num dueAmount;



  @JsonKey(
    
    name: r'isActive',
    required: true,
    includeIfNull: false,
  )


  final bool isActive;



  @JsonKey(
    
    name: r'status',
    required: false,
    includeIfNull: false,
  )


  final MemberDisplayStatus? status;



  @JsonKey(
    
    name: r'daysUntilExpiry',
    required: false,
    includeIfNull: false,
  )


  final int? daysUntilExpiry;



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
      other is MemberResponse &&
      runtimeType == other.runtimeType &&
      equals(
        [
            id,
            gymId,
            name,
            email,
            phone,
            address,
            photo,
            dateOfBirth,
            gender,
            planId,
            planName,
            membershipStart,
            membershipExpiry,
            notes,
            emergencyContact,
            dueAmount,
            isActive,
            status,
            daysUntilExpiry,
            createdAt,
            updatedAt,
        ],
        [
            other.id,
            other.gymId,
            other.name,
            other.email,
            other.phone,
            other.address,
            other.photo,
            other.dateOfBirth,
            other.gender,
            other.planId,
            other.planName,
            other.membershipStart,
            other.membershipExpiry,
            other.notes,
            other.emergencyContact,
            other.dueAmount,
            other.isActive,
            other.status,
            other.daysUntilExpiry,
            other.createdAt,
            other.updatedAt,
        ]
      );
    }


    @override
    int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([
        id,
        gymId,
        name,
        email,
        phone,
        address,
        photo,
        dateOfBirth,
        gender,
        planId,
        planName,
        membershipStart,
        membershipExpiry,
        notes,
        emergencyContact,
        dueAmount,
        isActive,
        status,
        daysUntilExpiry,
        createdAt,
        updatedAt,
    ],);

  factory MemberResponse.fromJson(Map<String, dynamic> json) => _$MemberResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MemberResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum MemberResponseGenderEnum {
@JsonValue(r'male')
male(r'male'),
@JsonValue(r'female')
female(r'female'),
@JsonValue(r'other')
other(r'other');

const MemberResponseGenderEnum(this.value);

final String value;

@override
String toString() => value;
}


