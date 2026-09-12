//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'plan_create_input.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PlanCreateInput {
  /// Returns a new [PlanCreateInput] instance.
  PlanCreateInput({

    required  this.name,

     this.description,

    required  this.durationDays,

    required  this.price,

     this.features,

     this.isActive = true,
  });

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



          // minimum: 1
  @JsonKey(
    
    name: r'durationDays',
    required: true,
    includeIfNull: false,
  )


  final int durationDays;



          // minimum: 0
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
    defaultValue: true,
    name: r'isActive',
    required: false,
    includeIfNull: false,
  )


  final bool? isActive;




    bool operator ==(Object other) {
      return identical(this, other) ||
      other is PlanCreateInput &&
      runtimeType == other.runtimeType &&
      equals(
        [
            name,
            description,
            durationDays,
            price,
            features,
            isActive,
        ],
        [
            other.name,
            other.description,
            other.durationDays,
            other.price,
            other.features,
            other.isActive,
        ]
      );
    }


    @override
    int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([
        name,
        description,
        durationDays,
        price,
        features,
        isActive,
    ],);

  factory PlanCreateInput.fromJson(Map<String, dynamic> json) => _$PlanCreateInputFromJson(json);

  Map<String, dynamic> toJson() => _$PlanCreateInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

