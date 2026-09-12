//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'member_update_input.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class MemberUpdateInput {
  /// Returns a new [MemberUpdateInput] instance.
  MemberUpdateInput({

     this.name,

     this.email,

     this.phone,

     this.address,

     this.photo,

     this.dateOfBirth,

     this.gender,

     this.notes,

     this.emergencyContact,

     this.isActive,
  });

  @JsonKey(
    
    name: r'name',
    required: false,
    includeIfNull: false,
  )


  final String? name;



  @JsonKey(
    
    name: r'email',
    required: false,
    includeIfNull: false,
  )


  final String? email;



  @JsonKey(
    
    name: r'phone',
    required: false,
    includeIfNull: false,
  )


  final String? phone;



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


  final MemberUpdateInputGenderEnum? gender;



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
    
    name: r'isActive',
    required: false,
    includeIfNull: false,
  )


  final bool? isActive;




    bool operator ==(Object other) {
      return identical(this, other) ||
      other is MemberUpdateInput &&
      runtimeType == other.runtimeType &&
      equals(
        [
            name,
            email,
            phone,
            address,
            photo,
            dateOfBirth,
            gender,
            notes,
            emergencyContact,
            isActive,
        ],
        [
            other.name,
            other.email,
            other.phone,
            other.address,
            other.photo,
            other.dateOfBirth,
            other.gender,
            other.notes,
            other.emergencyContact,
            other.isActive,
        ]
      );
    }


    @override
    int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([
        name,
        email,
        phone,
        address,
        photo,
        dateOfBirth,
        gender,
        notes,
        emergencyContact,
        isActive,
    ],);

  factory MemberUpdateInput.fromJson(Map<String, dynamic> json) => _$MemberUpdateInputFromJson(json);

  Map<String, dynamic> toJson() => _$MemberUpdateInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum MemberUpdateInputGenderEnum {
@JsonValue(r'male')
male(r'male'),
@JsonValue(r'female')
female(r'female'),
@JsonValue(r'other')
other(r'other');

const MemberUpdateInputGenderEnum(this.value);

final String value;

@override
String toString() => value;
}


