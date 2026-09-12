//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'payment_list_response_summary.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PaymentListResponseSummary {
  /// Returns a new [PaymentListResponseSummary] instance.
  PaymentListResponseSummary({

    required  this.netAmount,
  });

  @JsonKey(
    
    name: r'netAmount',
    required: true,
    includeIfNull: false,
  )


  final num netAmount;




    bool operator ==(Object other) {
      return identical(this, other) ||
      other is PaymentListResponseSummary &&
      runtimeType == other.runtimeType &&
      equals(
        [
            netAmount,
        ],
        [
            other.netAmount,
        ]
      );
    }


    @override
    int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([
        netAmount,
    ],);

  factory PaymentListResponseSummary.fromJson(Map<String, dynamic> json) => _$PaymentListResponseSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentListResponseSummaryToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

