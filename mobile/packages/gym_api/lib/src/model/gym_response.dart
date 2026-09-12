//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'gym_response.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class GymResponse {
  /// Returns a new [GymResponse] instance.
  GymResponse({

    required  this.id,

    required  this.name,

     this.logo,

    required  this.primaryColor,

     this.address,

     this.phone,

     this.email,

    required  this.currency,

    required  this.timezone,

    required  this.expiryReminderDays,

    required  this.isActive,

     this.ownerId,

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



  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



  @JsonKey(
    
    name: r'logo',
    required: false,
    includeIfNull: false,
  )


  final String? logo;



  @JsonKey(
    
    name: r'primaryColor',
    required: true,
    includeIfNull: false,
  )


  final String primaryColor;



  @JsonKey(
    
    name: r'address',
    required: false,
    includeIfNull: false,
  )


  final String? address;



  @JsonKey(
    
    name: r'phone',
    required: false,
    includeIfNull: false,
  )


  final String? phone;



  @JsonKey(
    
    name: r'email',
    required: false,
    includeIfNull: false,
  )


  final String? email;



  @JsonKey(
    
    name: r'currency',
    required: true,
    includeIfNull: false,
  )


  final String currency;



  @JsonKey(
    
    name: r'timezone',
    required: true,
    includeIfNull: false,
  )


  final String timezone;



  @JsonKey(
    
    name: r'expiryReminderDays',
    required: true,
    includeIfNull: false,
  )


  final num expiryReminderDays;



  @JsonKey(
    
    name: r'isActive',
    required: true,
    includeIfNull: false,
  )


  final bool isActive;



      /// Mongo ObjectId serialized as a string
  @JsonKey(
    
    name: r'ownerId',
    required: false,
    includeIfNull: false,
  )


  final String? ownerId;



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
      other is GymResponse &&
      runtimeType == other.runtimeType &&
      equals(
        [
            id,
            name,
            logo,
            primaryColor,
            address,
            phone,
            email,
            currency,
            timezone,
            expiryReminderDays,
            isActive,
            ownerId,
            createdAt,
            updatedAt,
        ],
        [
            other.id,
            other.name,
            other.logo,
            other.primaryColor,
            other.address,
            other.phone,
            other.email,
            other.currency,
            other.timezone,
            other.expiryReminderDays,
            other.isActive,
            other.ownerId,
            other.createdAt,
            other.updatedAt,
        ]
      );
    }


    @override
    int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([
        id,
        name,
        logo,
        primaryColor,
        address,
        phone,
        email,
        currency,
        timezone,
        expiryReminderDays,
        isActive,
        ownerId,
        createdAt,
        updatedAt,
    ],);

  factory GymResponse.fromJson(Map<String, dynamic> json) => _$GymResponseFromJson(json);

  Map<String, dynamic> toJson() => _$GymResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

