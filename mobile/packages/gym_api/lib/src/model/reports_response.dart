//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gym_api/src/model/reports_response_series_inner.dart';
import 'package:gym_api/src/model/reports_response_payment_methods_inner.dart';
import 'package:gym_api/src/model/reports_response_insights.dart';
import 'package:gym_api/src/model/reports_response_plan_performance_inner.dart';
import 'package:gym_api/src/model/reports_response_summary.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'reports_response.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ReportsResponse {
  /// Returns a new [ReportsResponse] instance.
  ReportsResponse({

    required  this.year,

    required  this.asOf,

    required  this.timezone,

    required  this.summary,

    required  this.series,

    required  this.planPerformance,

    required  this.paymentMethods,

    required  this.insights,
  });

  @JsonKey(
    
    name: r'year',
    required: true,
    includeIfNull: false,
  )


  final num year;



      /// ISO 8601 date-time string
  @JsonKey(
    
    name: r'asOf',
    required: true,
    includeIfNull: false,
  )


  final String asOf;



  @JsonKey(
    
    name: r'timezone',
    required: true,
    includeIfNull: false,
  )


  final String timezone;



  @JsonKey(
    
    name: r'summary',
    required: true,
    includeIfNull: false,
  )


  final ReportsResponseSummary summary;



  @JsonKey(
    
    name: r'series',
    required: true,
    includeIfNull: false,
  )


  final List<ReportsResponseSeriesInner> series;



  @JsonKey(
    
    name: r'planPerformance',
    required: true,
    includeIfNull: false,
  )


  final List<ReportsResponsePlanPerformanceInner> planPerformance;



  @JsonKey(
    
    name: r'paymentMethods',
    required: true,
    includeIfNull: false,
  )


  final List<ReportsResponsePaymentMethodsInner> paymentMethods;



  @JsonKey(
    
    name: r'insights',
    required: true,
    includeIfNull: false,
  )


  final ReportsResponseInsights insights;




    bool operator ==(Object other) {
      return identical(this, other) ||
      other is ReportsResponse &&
      runtimeType == other.runtimeType &&
      equals(
        [
            year,
            asOf,
            timezone,
            summary,
            series,
            planPerformance,
            paymentMethods,
            insights,
        ],
        [
            other.year,
            other.asOf,
            other.timezone,
            other.summary,
            other.series,
            other.planPerformance,
            other.paymentMethods,
            other.insights,
        ]
      );
    }


    @override
    int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([
        year,
        asOf,
        timezone,
        summary,
        series,
        planPerformance,
        paymentMethods,
        insights,
    ],);

  factory ReportsResponse.fromJson(Map<String, dynamic> json) => _$ReportsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ReportsResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

