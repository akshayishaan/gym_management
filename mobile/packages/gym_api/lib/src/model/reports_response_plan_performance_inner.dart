//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'reports_response_plan_performance_inner.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ReportsResponsePlanPerformanceInner {
  /// Returns a new [ReportsResponsePlanPerformanceInner] instance.
  ReportsResponsePlanPerformanceInner({

    required  this.key,

     this.planId,

    required  this.name,

    required  this.revenue,

    required  this.sales,

    required  this.activeMembers,
  });

  @JsonKey(
    
    name: r'key',
    required: true,
    includeIfNull: false,
  )


  final String key;



  @JsonKey(
    
    name: r'planId',
    required: false,
    includeIfNull: false,
  )


  final String? planId;



  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



  @JsonKey(
    
    name: r'revenue',
    required: true,
    includeIfNull: false,
  )


  final num revenue;



  @JsonKey(
    
    name: r'sales',
    required: true,
    includeIfNull: false,
  )


  final num sales;



  @JsonKey(
    
    name: r'activeMembers',
    required: true,
    includeIfNull: false,
  )


  final num activeMembers;




    bool operator ==(Object other) {
      return identical(this, other) ||
      other is ReportsResponsePlanPerformanceInner &&
      runtimeType == other.runtimeType &&
      equals(
        [
            key,
            planId,
            name,
            revenue,
            sales,
            activeMembers,
        ],
        [
            other.key,
            other.planId,
            other.name,
            other.revenue,
            other.sales,
            other.activeMembers,
        ]
      );
    }


    @override
    int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([
        key,
        planId,
        name,
        revenue,
        sales,
        activeMembers,
    ],);

  factory ReportsResponsePlanPerformanceInner.fromJson(Map<String, dynamic> json) => _$ReportsResponsePlanPerformanceInnerFromJson(json);

  Map<String, dynamic> toJson() => _$ReportsResponsePlanPerformanceInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

