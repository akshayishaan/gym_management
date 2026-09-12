//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'dashboard_response_recent_payments_inner.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DashboardResponseRecentPaymentsInner {
  /// Returns a new [DashboardResponseRecentPaymentsInner] instance.
  DashboardResponseRecentPaymentsInner({

    required  this.id,

    required  this.memberName,

    required  this.amount,

    required  this.paidAt,

    required  this.method,
  });

      /// Mongo ObjectId serialized as a string
  @JsonKey(
    
    name: r'_id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'memberName',
    required: true,
    includeIfNull: false,
  )


  final String memberName;



  @JsonKey(
    
    name: r'amount',
    required: true,
    includeIfNull: false,
  )


  final num amount;



      /// ISO 8601 date-time string
  @JsonKey(
    
    name: r'paidAt',
    required: true,
    includeIfNull: false,
  )


  final String paidAt;



  @JsonKey(
    
    name: r'method',
    required: true,
    includeIfNull: false,
  )


  final DashboardResponseRecentPaymentsInnerMethodEnum method;




    bool operator ==(Object other) {
      return identical(this, other) ||
      other is DashboardResponseRecentPaymentsInner &&
      runtimeType == other.runtimeType &&
      equals(
        [
            id,
            memberName,
            amount,
            paidAt,
            method,
        ],
        [
            other.id,
            other.memberName,
            other.amount,
            other.paidAt,
            other.method,
        ]
      );
    }


    @override
    int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([
        id,
        memberName,
        amount,
        paidAt,
        method,
    ],);

  factory DashboardResponseRecentPaymentsInner.fromJson(Map<String, dynamic> json) => _$DashboardResponseRecentPaymentsInnerFromJson(json);

  Map<String, dynamic> toJson() => _$DashboardResponseRecentPaymentsInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum DashboardResponseRecentPaymentsInnerMethodEnum {
@JsonValue(r'cash')
cash(r'cash'),
@JsonValue(r'card')
card(r'card'),
@JsonValue(r'upi')
upi(r'upi'),
@JsonValue(r'bank_transfer')
bankTransfer(r'bank_transfer'),
@JsonValue(r'other')
other(r'other');

const DashboardResponseRecentPaymentsInnerMethodEnum(this.value);

final String value;

@override
String toString() => value;
}


