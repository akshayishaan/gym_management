//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'lifecycle_result_response.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class LifecycleResultResponse {
  /// Returns a new [LifecycleResultResponse] instance.
  LifecycleResultResponse({

    required  this.memberId,

     this.paymentId,

     this.membershipId,

     this.renewedUntil,

     this.dueAmount,
  });

      /// Mongo ObjectId serialized as a string
  @JsonKey(
    
    name: r'memberId',
    required: true,
    includeIfNull: false,
  )


  final String memberId;



      /// Mongo ObjectId serialized as a string
  @JsonKey(
    
    name: r'paymentId',
    required: false,
    includeIfNull: false,
  )


  final String? paymentId;



      /// Mongo ObjectId serialized as a string
  @JsonKey(
    
    name: r'membershipId',
    required: false,
    includeIfNull: false,
  )


  final String? membershipId;



      /// Calendar date in YYYY-MM-DD format
  @JsonKey(
    
    name: r'renewedUntil',
    required: false,
    includeIfNull: false,
  )


  final String? renewedUntil;



  @JsonKey(
    
    name: r'dueAmount',
    required: false,
    includeIfNull: false,
  )


  final num? dueAmount;




    bool operator ==(Object other) {
      return identical(this, other) ||
      other is LifecycleResultResponse &&
      runtimeType == other.runtimeType &&
      equals(
        [
            memberId,
            paymentId,
            membershipId,
            renewedUntil,
            dueAmount,
        ],
        [
            other.memberId,
            other.paymentId,
            other.membershipId,
            other.renewedUntil,
            other.dueAmount,
        ]
      );
    }


    @override
    int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([
        memberId,
        paymentId,
        membershipId,
        renewedUntil,
        dueAmount,
    ],);

  factory LifecycleResultResponse.fromJson(Map<String, dynamic> json) => _$LifecycleResultResponseFromJson(json);

  Map<String, dynamic> toJson() => _$LifecycleResultResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

