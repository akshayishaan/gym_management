import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../design/colors.dart';

/// A RepiX ActivityLog as returned by `GET /activity`. The backend's
/// `activity-log.schema.ts` is the source of truth; this model mirrors it
/// with camelCase Dart fields.
///
/// The `action` field is left as a raw string (matching `Payment.kind` /
/// `Payment.method` style) so the wire format and the display label stay
/// decoupled — the label lives on the model, the chip color lives on the
/// model's color-mapping getter.
///
/// Kept as a plain Dart class (no freezed) to match `Payment`/`Member`/`Plan`.
class ActivityLog {
  const ActivityLog({
    required this.id,
    this.gymId,
    this.staffId,
    required this.staffName,
    required this.action,
    required this.entity,
    this.entityId,
    this.details,
    this.createdAt,
    this.day,
    this.time,
  });

  /// Mongoose `_id` mapped to `id` on the wire.
  final String id;
  final String? gymId;
  final String? staffId;
  final String staffName;

  /// One of the values in [ActionType]. The backend writes other values
  /// for newer actions; we fall back to the raw string when unknown.
  final String action;
  final String entity;
  final String? entityId;
  final String? details;
  final DateTime? createdAt;

  /// Gym-local calendar date (`YYYY-MM-DD`) and time (`HH:mm`) of the event,
  /// computed by the server in the Gym's timezone.
  final String? day;
  final String? time;

  /// Uppercase label for the chip cluster.
  String get label {
    switch (action) {
      case ActionType.created:
        return 'CREATED';
      case ActionType.updated:
        return 'UPDATED';
      case ActionType.deleted:
        return 'DELETED';
      case ActionType.voided:
        return 'VOIDED';
      case ActionType.refunded:
        return 'REFUNDED';
      case ActionType.reversed:
        return 'REVERSED';
      default:
        return action.toUpperCase();
    }
  }

  /// Plain-words headline: "Member created", "Plan updated", "Payment
  /// voided".
  String get title {
    final subject = entity.isEmpty
        ? 'Record'
        : entity[0].toUpperCase() + entity.substring(1);
    return '$subject ${action.isEmpty ? 'changed' : action}';
  }

  /// Last six characters of the record id, enough to tell records apart
  /// without printing the whole 24-character database id.
  String get shortId {
    final full = (entityId != null && entityId!.isNotEmpty) ? entityId! : id;
    return full.length <= 6 ? full : full.substring(full.length - 6);
  }

  /// Accent for the action. Uses the app palette: lime for created, blue
  /// (info) for updated, orange for voided/refunded, red for deleted, grey
  /// for reversed and anything unknown.
  Color get accent {
    switch (action) {
      case ActionType.created:
        return LatoColors.primary;
      case ActionType.updated:
        return LatoColors.info;
      case ActionType.voided:
      case ActionType.refunded:
        return LatoColors.warning;
      case ActionType.deleted:
        return LatoColors.error;
      default:
        return LatoColors.textSecondaryDark;
    }
  }

  /// Chip palette for the action, derived from [accent].
  ({Color bg, Color fg, Color border}) get colors {
    final c = accent;
    return (bg: LatoColors.tint(c), fg: c, border: c.withValues(alpha: 0.4));
  }

  /// Time of day, in the Gym's timezone when the server sent it (`time`,
  /// `HH:mm`), otherwise the device's local time.
  String get timeLabel {
    final t = time;
    if (t != null && RegExp(r'^\d{2}:\d{2}$').hasMatch(t)) {
      final parts = t.split(':');
      return DateFormat('h:mm a').format(
        DateTime(2000, 1, 1, int.parse(parts[0]), int.parse(parts[1])),
      );
    }
    final ts = createdAt;
    return ts == null ? '\u2014' : DateFormat('h:mm a').format(ts.toLocal());
  }

  /// `YYYY-MM-DD` day bucket. Prefers the Gym-local [day] sent by the
  /// server so grouping does not depend on the device timezone; falls back
  /// to the device-local date of [createdAt]. Empty when neither exists.
  String get dayKey {
    final d = day;
    if (d != null && d.isNotEmpty) return d;
    final ts = createdAt?.toLocal();
    if (ts == null) return '';
    final y = ts.year.toString().padLeft(4, '0');
    final m = ts.month.toString().padLeft(2, '0');
    final dd = ts.day.toString().padLeft(2, '0');
    return '$y-$m-$dd';
  }

  factory ActivityLog.fromJson(Map<String, dynamic> json) {
    return ActivityLog(
      id: (json['_id'] ?? json['id']) as String,
      gymId: json['gymId']?.toString(),
      staffId: json['staffId']?.toString(),
      staffName: json['staffName'] as String? ?? '',
      action: json['action'] as String? ?? '',
      entity: json['entity'] as String? ?? '',
      entityId: json['entityId']?.toString(),
      details: json['details'] as String?,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      day: json['day'] as String?,
      time: json['time'] as String?,
    );
  }
}

/// Wire-format action names that the backend writes to `action`. The
/// chip cluster on the activity log screen filters on these.
class ActionType {
  const ActionType._();

  static const String created = 'created';
  static const String updated = 'updated';
  static const String deleted = 'deleted';
  static const String voided = 'voided';
  static const String refunded = 'refunded';
  static const String reversed = 'reversed';

  /// All known action values. Used to populate the chip cluster in
  /// deterministic order and to validate filter inputs.
  static const Set<String> all = {
    created,
    updated,
    deleted,
    voided,
    refunded,
    reversed,
  };
}
