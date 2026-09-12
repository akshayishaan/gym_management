//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gym_api/src/model/dashboard_response_expiring_list_inner.dart';
import 'package:gym_api/src/model/dashboard_response_recent_payments_inner.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'dashboard_response.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DashboardResponse {
  /// Returns a new [DashboardResponse] instance.
  DashboardResponse({

    required  this.totalMembers,

    required  this.activeMembers,

    required  this.expiredMembers,

    required  this.expiringMembers,

    required  this.monthRevenue,

    required  this.recentPayments,

    required  this.expiringList,
  });

  @JsonKey(
    
    name: r'totalMembers',
    required: true,
    includeIfNull: false,
  )


  final num totalMembers;



  @JsonKey(
    
    name: r'activeMembers',
    required: true,
    includeIfNull: false,
  )


  final num activeMembers;



  @JsonKey(
    
    name: r'expiredMembers',
    required: true,
    includeIfNull: false,
  )


  final num expiredMembers;



  @JsonKey(
    
    name: r'expiringMembers',
    required: true,
    includeIfNull: false,
  )


  final num expiringMembers;



  @JsonKey(
    
    name: r'monthRevenue',
    required: true,
    includeIfNull: false,
  )


  final num monthRevenue;



  @JsonKey(
    
    name: r'recentPayments',
    required: true,
    includeIfNull: false,
  )


  final List<DashboardResponseRecentPaymentsInner> recentPayments;



  @JsonKey(
    
    name: r'expiringList',
    required: true,
    includeIfNull: false,
  )


  final List<DashboardResponseExpiringListInner> expiringList;




    bool operator ==(Object other) {
      return identical(this, other) ||
      other is DashboardResponse &&
      runtimeType == other.runtimeType &&
      equals(
        [
            totalMembers,
            activeMembers,
            expiredMembers,
            expiringMembers,
            monthRevenue,
            recentPayments,
            expiringList,
        ],
        [
            other.totalMembers,
            other.activeMembers,
            other.expiredMembers,
            other.expiringMembers,
            other.monthRevenue,
            other.recentPayments,
            other.expiringList,
        ]
      );
    }


    @override
    int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([
        totalMembers,
        activeMembers,
        expiredMembers,
        expiringMembers,
        monthRevenue,
        recentPayments,
        expiringList,
    ],);

  factory DashboardResponse.fromJson(Map<String, dynamic> json) => _$DashboardResponseFromJson(json);

  Map<String, dynamic> toJson() => _$DashboardResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

