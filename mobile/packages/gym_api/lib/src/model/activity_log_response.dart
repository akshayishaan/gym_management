//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'activity_log_response.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ActivityLogResponse {
  /// Returns a new [ActivityLogResponse] instance.
  ActivityLogResponse({

    required  this.id,

     this.gymId,

     this.staffId,

    required  this.staffName,

    required  this.action,

    required  this.entity,

     this.entityId,

     this.details,

    required  this.createdAt,
  });

      /// Mongo ObjectId serialized as a string
  @JsonKey(
    
    name: r'_id',
    required: true,
    includeIfNull: false,
  )


  final String id;



      /// Mongo ObjectId serialized as a string
  @JsonKey(
    
    name: r'gymId',
    required: false,
    includeIfNull: false,
  )


  final String? gymId;



      /// Mongo ObjectId serialized as a string
  @JsonKey(
    
    name: r'staffId',
    required: false,
    includeIfNull: false,
  )


  final String? staffId;



  @JsonKey(
    
    name: r'staffName',
    required: true,
    includeIfNull: false,
  )


  final String staffName;



  @JsonKey(
    
    name: r'action',
    required: true,
    includeIfNull: false,
  )


  final String action;



  @JsonKey(
    
    name: r'entity',
    required: true,
    includeIfNull: false,
  )


  final String entity;



  @JsonKey(
    
    name: r'entityId',
    required: false,
    includeIfNull: false,
  )


  final String? entityId;



  @JsonKey(
    
    name: r'details',
    required: false,
    includeIfNull: false,
  )


  final String? details;



      /// ISO 8601 date-time string
  @JsonKey(
    
    name: r'createdAt',
    required: true,
    includeIfNull: false,
  )


  final String createdAt;




    bool operator ==(Object other) {
      return identical(this, other) ||
      other is ActivityLogResponse &&
      runtimeType == other.runtimeType &&
      equals(
        [
            id,
            gymId,
            staffId,
            staffName,
            action,
            entity,
            entityId,
            details,
            createdAt,
        ],
        [
            other.id,
            other.gymId,
            other.staffId,
            other.staffName,
            other.action,
            other.entity,
            other.entityId,
            other.details,
            other.createdAt,
        ]
      );
    }


    @override
    int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([
        id,
        gymId,
        staffId,
        staffName,
        action,
        entity,
        entityId,
        details,
        createdAt,
    ],);

  factory ActivityLogResponse.fromJson(Map<String, dynamic> json) => _$ActivityLogResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ActivityLogResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

