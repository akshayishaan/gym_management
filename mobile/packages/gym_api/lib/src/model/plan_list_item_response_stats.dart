//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'plan_list_item_response_stats.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PlanListItemResponseStats {
  /// Returns a new [PlanListItemResponseStats] instance.
  PlanListItemResponseStats({

    required  this.activeMembers,

    required  this.salesYtd,

    required  this.revenueAtSaleYtd,

    required  this.totalMemberships,
  });

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



  @JsonKey(
    
    name: r'totalMemberships',
    required: true,
    includeIfNull: false,
  )


  final num totalMemberships;




    bool operator ==(Object other) {
      return identical(this, other) ||
      other is PlanListItemResponseStats &&
      runtimeType == other.runtimeType &&
      equals(
        [
            activeMembers,
            salesYtd,
            revenueAtSaleYtd,
            totalMemberships,
        ],
        [
            other.activeMembers,
            other.salesYtd,
            other.revenueAtSaleYtd,
            other.totalMemberships,
        ]
      );
    }


    @override
    int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([
        activeMembers,
        salesYtd,
        revenueAtSaleYtd,
        totalMemberships,
    ],);

  factory PlanListItemResponseStats.fromJson(Map<String, dynamic> json) => _$PlanListItemResponseStatsFromJson(json);

  Map<String, dynamic> toJson() => _$PlanListItemResponseStatsToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

