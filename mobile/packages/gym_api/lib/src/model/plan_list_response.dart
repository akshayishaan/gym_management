//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gym_api/src/model/plan_list_response_summary.dart';
import 'package:gym_api/src/model/plan_list_response_plans_inner.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'plan_list_response.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PlanListResponse {
  /// Returns a new [PlanListResponse] instance.
  PlanListResponse({

    required  this.plans,

    required  this.total,

    required  this.page,

    required  this.limit,

     this.summary,
  });

  @JsonKey(
    
    name: r'plans',
    required: true,
    includeIfNull: false,
  )


  final List<PlanListResponsePlansInner> plans;



  @JsonKey(
    
    name: r'total',
    required: true,
    includeIfNull: false,
  )


  final num total;



  @JsonKey(
    
    name: r'page',
    required: true,
    includeIfNull: false,
  )


  final num page;



  @JsonKey(
    
    name: r'limit',
    required: true,
    includeIfNull: false,
  )


  final num limit;



  @JsonKey(
    
    name: r'summary',
    required: false,
    includeIfNull: false,
  )


  final PlanListResponseSummary? summary;




    bool operator ==(Object other) {
      return identical(this, other) ||
      other is PlanListResponse &&
      runtimeType == other.runtimeType &&
      equals(
        [
            plans,
            total,
            page,
            limit,
            summary,
        ],
        [
            other.plans,
            other.total,
            other.page,
            other.limit,
            other.summary,
        ]
      );
    }


    @override
    int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([
        plans,
        total,
        page,
        limit,
        summary,
    ],);

  factory PlanListResponse.fromJson(Map<String, dynamic> json) => _$PlanListResponseFromJson(json);

  Map<String, dynamic> toJson() => _$PlanListResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

