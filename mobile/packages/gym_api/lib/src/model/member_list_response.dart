//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gym_api/src/model/member_response.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'member_list_response.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class MemberListResponse {
  /// Returns a new [MemberListResponse] instance.
  MemberListResponse({

    required  this.members,

    required  this.total,

    required  this.page,

    required  this.limit,
  });

  @JsonKey(
    
    name: r'members',
    required: true,
    includeIfNull: false,
  )


  final List<MemberResponse> members;



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




    bool operator ==(Object other) {
      return identical(this, other) ||
      other is MemberListResponse &&
      runtimeType == other.runtimeType &&
      equals(
        [
            members,
            total,
            page,
            limit,
        ],
        [
            other.members,
            other.total,
            other.page,
            other.limit,
        ]
      );
    }


    @override
    int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([
        members,
        total,
        page,
        limit,
    ],);

  factory MemberListResponse.fromJson(Map<String, dynamic> json) => _$MemberListResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MemberListResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

