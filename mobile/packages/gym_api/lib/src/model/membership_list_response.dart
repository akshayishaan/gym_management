//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gym_api/src/model/membership_list_response_memberships_inner.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'membership_list_response.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class MembershipListResponse {
  /// Returns a new [MembershipListResponse] instance.
  MembershipListResponse({

    required  this.memberships,
  });

  @JsonKey(
    
    name: r'memberships',
    required: true,
    includeIfNull: false,
  )


  final List<MembershipListResponseMembershipsInner> memberships;




    bool operator ==(Object other) {
      return identical(this, other) ||
      other is MembershipListResponse &&
      runtimeType == other.runtimeType &&
      equals(
        [
            memberships,
        ],
        [
            other.memberships,
        ]
      );
    }


    @override
    int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([
        memberships,
    ],);

  factory MembershipListResponse.fromJson(Map<String, dynamic> json) => _$MembershipListResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MembershipListResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

