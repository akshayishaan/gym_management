//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'reports_response_insights_best_month.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ReportsResponseInsightsBestMonth {
  /// Returns a new [ReportsResponseInsightsBestMonth] instance.
  ReportsResponseInsightsBestMonth({

    required  this.month,

    required  this.revenue,
  });

  @JsonKey(
    
    name: r'month',
    required: true,
    includeIfNull: false,
  )


  final num month;



  @JsonKey(
    
    name: r'revenue',
    required: true,
    includeIfNull: false,
  )


  final num revenue;




    bool operator ==(Object other) {
      return identical(this, other) ||
      other is ReportsResponseInsightsBestMonth &&
      runtimeType == other.runtimeType &&
      equals(
        [
            month,
            revenue,
        ],
        [
            other.month,
            other.revenue,
        ]
      );
    }


    @override
    int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([
        month,
        revenue,
    ],);

  factory ReportsResponseInsightsBestMonth.fromJson(Map<String, dynamic> json) => _$ReportsResponseInsightsBestMonthFromJson(json);

  Map<String, dynamic> toJson() => _$ReportsResponseInsightsBestMonthToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

