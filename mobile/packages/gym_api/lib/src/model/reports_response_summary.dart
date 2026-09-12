//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gym_api/src/model/reports_response_summary_revenue.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'reports_response_summary.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ReportsResponseSummary {
  /// Returns a new [ReportsResponseSummary] instance.
  ReportsResponseSummary({

    required  this.revenue,

    required  this.transactions,

    required  this.newMembers,

    required  this.renewals,

    required  this.activeMembers,

    required  this.outstandingDues,

    required  this.dueMembers,
  });

  @JsonKey(
    
    name: r'revenue',
    required: true,
    includeIfNull: false,
  )


  final ReportsResponseSummaryRevenue revenue;



  @JsonKey(
    
    name: r'transactions',
    required: true,
    includeIfNull: false,
  )


  final ReportsResponseSummaryRevenue transactions;



  @JsonKey(
    
    name: r'newMembers',
    required: true,
    includeIfNull: false,
  )


  final ReportsResponseSummaryRevenue newMembers;



  @JsonKey(
    
    name: r'renewals',
    required: true,
    includeIfNull: false,
  )


  final ReportsResponseSummaryRevenue renewals;



  @JsonKey(
    
    name: r'activeMembers',
    required: true,
    includeIfNull: false,
  )


  final num activeMembers;



  @JsonKey(
    
    name: r'outstandingDues',
    required: true,
    includeIfNull: false,
  )


  final num outstandingDues;



  @JsonKey(
    
    name: r'dueMembers',
    required: true,
    includeIfNull: false,
  )


  final num dueMembers;




    bool operator ==(Object other) {
      return identical(this, other) ||
      other is ReportsResponseSummary &&
      runtimeType == other.runtimeType &&
      equals(
        [
            revenue,
            transactions,
            newMembers,
            renewals,
            activeMembers,
            outstandingDues,
            dueMembers,
        ],
        [
            other.revenue,
            other.transactions,
            other.newMembers,
            other.renewals,
            other.activeMembers,
            other.outstandingDues,
            other.dueMembers,
        ]
      );
    }


    @override
    int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([
        revenue,
        transactions,
        newMembers,
        renewals,
        activeMembers,
        outstandingDues,
        dueMembers,
    ],);

  factory ReportsResponseSummary.fromJson(Map<String, dynamic> json) => _$ReportsResponseSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$ReportsResponseSummaryToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

