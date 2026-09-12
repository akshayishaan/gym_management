//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'reports_response_summary_revenue.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ReportsResponseSummaryRevenue {
  /// Returns a new [ReportsResponseSummaryRevenue] instance.
  ReportsResponseSummaryRevenue({

    required  this.value,

    required  this.previous,

    required  this.changePercent,
  });

  @JsonKey(
    
    name: r'value',
    required: true,
    includeIfNull: false,
  )


  final num value;



  @JsonKey(
    
    name: r'previous',
    required: true,
    includeIfNull: false,
  )


  final num previous;



  @JsonKey(
    
    name: r'changePercent',
    required: true,
    includeIfNull: true,
  )


  final num? changePercent;




    bool operator ==(Object other) {
      return identical(this, other) ||
      other is ReportsResponseSummaryRevenue &&
      runtimeType == other.runtimeType &&
      equals(
        [
            value,
            previous,
            changePercent,
        ],
        [
            other.value,
            other.previous,
            other.changePercent,
        ]
      );
    }


    @override
    int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([
        value,
        previous,
        changePercent,
    ],);

  factory ReportsResponseSummaryRevenue.fromJson(Map<String, dynamic> json) => _$ReportsResponseSummaryRevenueFromJson(json);

  Map<String, dynamic> toJson() => _$ReportsResponseSummaryRevenueToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

