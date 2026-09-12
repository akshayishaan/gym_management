//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'gym_update_input.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class GymUpdateInput {
  /// Returns a new [GymUpdateInput] instance.
  GymUpdateInput({

     this.name,

     this.logo,

     this.primaryColor,

     this.address,

     this.phone,

     this.email,

     this.currency,

     this.timezone,

     this.expiryReminderDays,

     this.isActive,
  });

  @JsonKey(
    
    name: r'name',
    required: false,
    includeIfNull: false,
  )


  final String? name;



  @JsonKey(
    
    name: r'logo',
    required: false,
    includeIfNull: false,
  )


  final String? logo;



  @JsonKey(
    
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
    
    name: r'currency',
    required: false,
    includeIfNull: false,
  )


  final String? currency;



  @JsonKey(
    
    name: r'timezone',
    required: false,
    includeIfNull: false,
  )


  final String? timezone;



          // minimum: 1
          // maximum: 90
  @JsonKey(
    
    name: r'expiryReminderDays',
    required: false,
    includeIfNull: false,
  )


  final int? expiryReminderDays;



  @JsonKey(
    
    name: r'isActive',
    required: false,
    includeIfNull: false,
  )


  final bool? isActive;




    bool operator ==(Object other) {
      return identical(this, other) ||
      other is GymUpdateInput &&
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

  factory GymUpdateInput.fromJson(Map<String, dynamic> json) => _$GymUpdateInputFromJson(json);

  Map<String, dynamic> toJson() => _$GymUpdateInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

