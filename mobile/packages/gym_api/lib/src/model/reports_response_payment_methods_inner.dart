//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'reports_response_payment_methods_inner.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ReportsResponsePaymentMethodsInner {
  /// Returns a new [ReportsResponsePaymentMethodsInner] instance.
  ReportsResponsePaymentMethodsInner({

    required  this.method,

    required  this.amount,

    required  this.count,

    required  this.percentage,
  });

  @JsonKey(
    
    name: r'method',
    required: true,
    includeIfNull: false,
  )


  final String method;



  @JsonKey(
    
    name: r'amount',
    required: true,
    includeIfNull: false,
  )


  final num amount;



  @JsonKey(
    
    name: r'count',
    required: true,
    includeIfNull: false,
  )


  final num count;



  @JsonKey(
    
    name: r'percentage',
    required: true,
    includeIfNull: false,
  )


  final num percentage;




    bool operator ==(Object other) {
      return identical(this, other) ||
      other is ReportsResponsePaymentMethodsInner &&
      runtimeType == other.runtimeType &&
      equals(
        [
            method,
            amount,
            count,
            percentage,
        ],
        [
            other.method,
            other.amount,
            other.count,
            other.percentage,
        ]
      );
    }


    @override
    int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([
        method,
        amount,
        count,
        percentage,
    ],);

  factory ReportsResponsePaymentMethodsInner.fromJson(Map<String, dynamic> json) => _$ReportsResponsePaymentMethodsInnerFromJson(json);

  Map<String, dynamic> toJson() => _$ReportsResponsePaymentMethodsInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

