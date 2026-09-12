//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'plan_update_input.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PlanUpdateInput {
  /// Returns a new [PlanUpdateInput] instance.
  PlanUpdateInput({

     this.name,

     this.description,

     this.durationDays,

     this.price,

     this.features,

     this.isActive,
  });

  @JsonKey(
    
    name: r'name',
    required: false,
    includeIfNull: false,
  )


  final String? name;



  @JsonKey(
    
    name: r'description',
    required: false,
    includeIfNull: false,
  )


  final String? description;



          // minimum: 1
  @JsonKey(
    
    name: r'durationDays',
    required: false,
    includeIfNull: false,
  )


  final int? durationDays;



          // minimum: 0
  @JsonKey(
    
    name: r'price',
    required: false,
    includeIfNull: false,
  )


  final num? price;



  @JsonKey(
    
    name: r'features',
    required: false,
    includeIfNull: false,
  )


  final List<String>? features;



  @JsonKey(
    
    name: r'isActive',
    required: false,
    includeIfNull: false,
  )


  final bool? isActive;




    bool operator ==(Object other) {
      return identical(this, other) ||
      other is PlanUpdateInput &&
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

  factory PlanUpdateInput.fromJson(Map<String, dynamic> json) => _$PlanUpdateInputFromJson(json);

  Map<String, dynamic> toJson() => _$PlanUpdateInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

