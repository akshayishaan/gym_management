//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gym_api/src/model/payment_list_response_payments_inner.dart';
import 'package:gym_api/src/model/payment_list_response_summary.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'payment_list_response.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PaymentListResponse {
  /// Returns a new [PaymentListResponse] instance.
  PaymentListResponse({

    required  this.payments,

    required  this.total,

    required  this.page,

    required  this.limit,

    required  this.summary,
  });

  @JsonKey(
    
    name: r'payments',
    required: true,
    includeIfNull: false,
  )


  final List<PaymentListResponsePaymentsInner> payments;



  @JsonKey(
    
    name: r'total',
    required: true,
    includeIfNull: false,
  )


  final num total;



  @JsonKey(
    
    name: r'page',
    required: true,
    includeIfNull: false,
  )


  final num page;



  @JsonKey(
    
    name: r'limit',
    required: true,
    includeIfNull: false,
  )


  final num limit;



  @JsonKey(
    
    name: r'summary',
    required: true,
    includeIfNull: false,
  )


  final PaymentListResponseSummary summary;




    bool operator ==(Object other) {
      return identical(this, other) ||
      other is PaymentListResponse &&
      runtimeType == other.runtimeType &&
      equals(
        [
            payments,
            total,
            page,
            limit,
            summary,
        ],
        [
            other.payments,
            other.total,
            other.page,
            other.limit,
            other.summary,
        ]
      );
    }


    @override
    int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([
        payments,
        total,
        page,
        limit,
        summary,
    ],);

  factory PaymentListResponse.fromJson(Map<String, dynamic> json) => _$PaymentListResponseFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentListResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

