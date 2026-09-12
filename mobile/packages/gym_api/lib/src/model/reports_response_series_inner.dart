//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'reports_response_series_inner.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ReportsResponseSeriesInner {
  /// Returns a new [ReportsResponseSeriesInner] instance.
  ReportsResponseSeriesInner({

    required  this.month,

    required  this.revenue,

    required  this.transactions,

    required  this.newMembers,

    required  this.memberships,

    required  this.renewals,
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



  @JsonKey(
    
    name: r'transactions',
    required: true,
    includeIfNull: false,
  )


  final num transactions;



  @JsonKey(
    
    name: r'newMembers',
    required: true,
    includeIfNull: false,
  )


  final num newMembers;



  @JsonKey(
    
    name: r'memberships',
    required: true,
    includeIfNull: false,
  )


  final num memberships;



  @JsonKey(
    
    name: r'renewals',
    required: true,
    includeIfNull: false,
  )


  final num renewals;




    bool operator ==(Object other) {
      return identical(this, other) ||
      other is ReportsResponseSeriesInner &&
      runtimeType == other.runtimeType &&
      equals(
        [
            month,
            revenue,
            transactions,
            newMembers,
            memberships,
            renewals,
        ],
        [
            other.month,
            other.revenue,
            other.transactions,
            other.newMembers,
            other.memberships,
            other.renewals,
        ]
      );
    }


    @override
    int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([
        month,
        revenue,
        transactions,
        newMembers,
        memberships,
        renewals,
    ],);

  factory ReportsResponseSeriesInner.fromJson(Map<String, dynamic> json) => _$ReportsResponseSeriesInnerFromJson(json);

  Map<String, dynamic> toJson() => _$ReportsResponseSeriesInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

