//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gym_api/src/model/reports_response_insights_best_month.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'reports_response_insights.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ReportsResponseInsights {
  /// Returns a new [ReportsResponseInsights] instance.
  ReportsResponseInsights({

    required  this.expiringSoon,

    required  this.expiredMembers,

    required  this.dueMembers,

    required  this.outstandingDues,

    required  this.bestMonth,
  });

  @JsonKey(
    
    name: r'expiringSoon',
    required: true,
    includeIfNull: false,
  )


  final num expiringSoon;



  @JsonKey(
    
    name: r'expiredMembers',
    required: true,
    includeIfNull: false,
  )


  final num expiredMembers;



  @JsonKey(
    
    name: r'dueMembers',
    required: true,
    includeIfNull: false,
  )


  final num dueMembers;



  @JsonKey(
    
    name: r'outstandingDues',
    required: true,
    includeIfNull: false,
  )


  final num outstandingDues;



  @JsonKey(
    
    name: r'bestMonth',
    required: true,
    includeIfNull: true,
  )


  final ReportsResponseInsightsBestMonth? bestMonth;




    bool operator ==(Object other) {
      return identical(this, other) ||
      other is ReportsResponseInsights &&
      runtimeType == other.runtimeType &&
      equals(
        [
            expiringSoon,
            expiredMembers,
            dueMembers,
            outstandingDues,
            bestMonth,
        ],
        [
            other.expiringSoon,
            other.expiredMembers,
            other.dueMembers,
            other.outstandingDues,
            other.bestMonth,
        ]
      );
    }


    @override
    int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([
        expiringSoon,
        expiredMembers,
        dueMembers,
        outstandingDues,
        bestMonth,
    ],);

  factory ReportsResponseInsights.fromJson(Map<String, dynamic> json) => _$ReportsResponseInsightsFromJson(json);

  Map<String, dynamic> toJson() => _$ReportsResponseInsightsToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

