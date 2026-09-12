//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gym_api/src/model/activity_list_response_logs_inner.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'activity_list_response.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ActivityListResponse {
  /// Returns a new [ActivityListResponse] instance.
  ActivityListResponse({

    required  this.logs,

    required  this.total,

    required  this.page,

    required  this.limit,
  });

  @JsonKey(
    
    name: r'logs',
    required: true,
    includeIfNull: false,
  )


  final List<ActivityListResponseLogsInner> logs;



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
      other is ActivityListResponse &&
      runtimeType == other.runtimeType &&
      equals(
        [
            logs,
            total,
            page,
            limit,
        ],
        [
            other.logs,
            other.total,
            other.page,
            other.limit,
        ]
      );
    }


    @override
    int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([
        logs,
        total,
        page,
        limit,
    ],);

  factory ActivityListResponse.fromJson(Map<String, dynamic> json) => _$ActivityListResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ActivityListResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

