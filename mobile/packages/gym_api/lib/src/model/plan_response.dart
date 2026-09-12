//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'plan_response.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PlanResponse {
  /// Returns a new [PlanResponse] instance.
  PlanResponse({

    required  this.id,

    required  this.gymId,

    required  this.name,

     this.description,

    required  this.durationDays,

    required  this.price,

     this.features,

    required  this.isActive,

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
    
    name: r'description',
    required: false,
    includeIfNull: false,
  )


  final String? description;



  @JsonKey(
    
    name: r'durationDays',
    required: true,
    includeIfNull: false,
  )


  final num durationDays;



  @JsonKey(
    
    name: r'price',
    required: true,
    includeIfNull: false,
  )


  final num price;



  @JsonKey(
    
    name: r'features',
    required: false,
    includeIfNull: false,
  )


  final List<String>? features;



  @JsonKey(
    
    name: r'isActive',
    required: true,
    includeIfNull: false,
  )


  final bool isActive;



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
      other is PlanResponse &&
      runtimeType == other.runtimeType &&
      equals(
        [
            id,
            gymId,
            name,
            description,
            durationDays,
            price,
            features,
            isActive,
            createdAt,
            updatedAt,
        ],
        [
            other.id,
            other.gymId,
            other.name,
            other.description,
            other.durationDays,
            other.price,
            other.features,
            other.isActive,
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
        description,
        durationDays,
        price,
        features,
        isActive,
        createdAt,
        updatedAt,
    ],);

  factory PlanResponse.fromJson(Map<String, dynamic> json) => _$PlanResponseFromJson(json);

  Map<String, dynamic> toJson() => _$PlanResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

