//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'plan_list_response_summary.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PlanListResponseSummary {
  /// Returns a new [PlanListResponseSummary] instance.
  PlanListResponseSummary({

    required  this.activePlans,

    required  this.activeMembers,

    required  this.salesYtd,

    required  this.revenueAtSaleYtd,
  });

  @JsonKey(
    
    name: r'activePlans',
    required: true,
    includeIfNull: false,
  )


  final num activePlans;



  @JsonKey(
    
    name: r'activeMembers',
    required: true,
    includeIfNull: false,
  )


  final num activeMembers;



  @JsonKey(
    
    name: r'salesYtd',
    required: true,
    includeIfNull: false,
  )


  final num salesYtd;



  @JsonKey(
    
    name: r'revenueAtSaleYtd',
    required: true,
    includeIfNull: false,
  )


  final num revenueAtSaleYtd;




    bool operator ==(Object other) {
      return identical(this, other) ||
      other is PlanListResponseSummary &&
      runtimeType == other.runtimeType &&
      equals(
        [
            activePlans,
            activeMembers,
            salesYtd,
            revenueAtSaleYtd,
        ],
        [
            other.activePlans,
            other.activeMembers,
            other.salesYtd,
            other.revenueAtSaleYtd,
        ]
      );
    }


    @override
    int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([
        activePlans,
        activeMembers,
        salesYtd,
        revenueAtSaleYtd,
    ],);

  factory PlanListResponseSummary.fromJson(Map<String, dynamic> json) => _$PlanListResponseSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$PlanListResponseSummaryToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

