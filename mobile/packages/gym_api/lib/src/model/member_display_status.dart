//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';


enum MemberDisplayStatus {
      @JsonValue(r'active')
      active(r'active'),
      @JsonValue(r'expiring')
      expiring(r'expiring'),
      @JsonValue(r'expired')
      expired(r'expired');

  const MemberDisplayStatus(this.value);

  final String value;

  @override
  String toString() => value;
}
