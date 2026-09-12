//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'gym_create_input.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class GymCreateInput {
  /// Returns a new [GymCreateInput] instance.
  GymCreateInput({

    required  this.name,

     this.logo,

     this.primaryColor = '#6366f1',

     this.address,

     this.phone,

     this.email,

     this.currency = 'INR',

     this.timezone = 'Asia/Kolkata',

     this.expiryReminderDays = 7,

     this.isActive = true,
  });

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
    defaultValue: '#6366f1',
    name: r'primaryColor',
    required: false,
    includeIfNull: false,
  )


  final String? primaryColor;



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
    defaultValue: 'INR',
    name: r'currency',
    required: false,
    includeIfNull: false,
  )


  final String? currency;



  @JsonKey(
    defaultValue: 'Asia/Kolkata',
    name: r'timezone',
    required: false,
    includeIfNull: false,
  )


  final String? timezone;



          // minimum: 1
          // maximum: 90
  @JsonKey(
    defaultValue: 7,
    name: r'expiryReminderDays',
    required: false,
    includeIfNull: false,
  )


  final int? expiryReminderDays;



  @JsonKey(
    defaultValue: true,
    name: r'isActive',
    required: false,
    includeIfNull: false,
  )


  final bool? isActive;




    bool operator ==(Object other) {
      return identical(this, other) ||
      other is GymCreateInput &&
      runtimeType == other.runtimeType &&
      equals(
        [
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
        ],
        [
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
        ]
      );
    }


    @override
    int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([
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
    ],);

  factory GymCreateInput.fromJson(Map<String, dynamic> json) => _$GymCreateInputFromJson(json);

  Map<String, dynamic> toJson() => _$GymCreateInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

