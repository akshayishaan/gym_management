//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gym_api/src/model/plan_list_item_response_stats.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'plan_list_item_response.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PlanListItemResponse {
  /// Returns a new [PlanListItemResponse] instance.
  PlanListItemResponse({

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

     this.stats,
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



  @JsonKey(
    
    name: r'stats',
    required: false,
    includeIfNull: false,
  )


  final PlanListItemResponseStats? stats;




    bool operator ==(Object other) {
      return identical(this, other) ||
      other is PlanListItemResponse &&
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
            stats,
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
            other.stats,
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
        stats,
    ],);

  factory PlanListItemResponse.fromJson(Map<String, dynamic> json) => _$PlanListItemResponseFromJson(json);

  Map<String, dynamic> toJson() => _$PlanListItemResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

