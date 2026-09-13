//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'dashboard_response_expiring_list_inner.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DashboardResponseExpiringListInner {
  /// Returns a new [DashboardResponseExpiringListInner] instance.
  DashboardResponseExpiringListInner({

    required  this.id,

    required  this.name,

    required  this.phone,

    required  this.membershipExpiry,

     this.planName,

    required  this.daysUntilExpiry,
  });

      /// Mongo ObjectId serialized as a string
  @JsonKey(
    
    name: r'_id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



  @JsonKey(
    
    name: r'phone',
    required: true,
    includeIfNull: false,
  )


  final String phone;



      /// Calendar date in YYYY-MM-DD format
  @JsonKey(
    
    name: r'membershipExpiry',
    required: true,
    includeIfNull: false,
  )


  final String membershipExpiry;



  @JsonKey(
    
    name: r'planName',
    required: false,
    includeIfNull: false,
  )


  final String? planName;



  @JsonKey(
    
    name: r'daysUntilExpiry',
    required: true,
    includeIfNull: false,
  )


  final int daysUntilExpiry;




    bool operator ==(Object other) {
      return identical(this, other) ||
      other is DashboardResponseExpiringListInner &&
      runtimeType == other.runtimeType &&
      equals(
        [
            id,
            name,
            phone,
            membershipExpiry,
            planName,
            daysUntilExpiry,
        ],
        [
            other.id,
            other.name,
            other.phone,
            other.membershipExpiry,
            other.planName,
            other.daysUntilExpiry,
        ]
      );
    }


    @override
    int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([
        id,
        name,
        phone,
        membershipExpiry,
        planName,
        daysUntilExpiry,
    ],);

  factory DashboardResponseExpiringListInner.fromJson(Map<String, dynamic> json) => _$DashboardResponseExpiringListInnerFromJson(json);

  Map<String, dynamic> toJson() => _$DashboardResponseExpiringListInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

