import 'package:flutter/material.dart';

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

  /// Uppercase label for the chip cluster (matches Figma).
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

  /// Chip palette for the action. Colors match the Figma design — the
  /// alpha-aware `0xAARRGGBB` form lets the chip blend with its surface.
  ({Color bg, Color fg, Color border}) get colors {
    switch (action) {
      case ActionType.created:
        return (
          bg: const Color(0xFF2A2A0F),
          fg: const Color(0xFFC5F23F),
          border: const Color(0xFF3D4A0A),
        );
      case ActionType.updated:
        return (
          bg: const Color(0xFF00262B),
          fg: const Color(0xFF00DBE9),
          border: const Color(0xFF005C66),
        );
      case ActionType.voided:
        return (
          bg: const Color(0xFF2A1100),
          fg: const Color(0xFFFF5708),
          border: const Color(0xFF66310A),
        );
      case ActionType.refunded:
        return (
          bg: const Color(0xFF2A1810),
          fg: const Color(0xFFFFB59C),
          border: const Color(0xFF663D33),
        );
      case ActionType.reversed:
        return (
          bg: const Color(0xFF2A1F18),
          fg: const Color(0xFFFFDBCF),
          border: const Color(0xFF66483D),
        );
      case ActionType.deleted:
        return (
          bg: const Color(0xFF2A0F0F),
          fg: const Color(0xFFFFB4AB),
          border: const Color(0xFF662222),
        );
      default:
        return (
          bg: const Color(0xFF1F1F1F),
          fg: const Color(0xFFA3A3A3),
          border: const Color(0xFF404040),
        );
    }
  }

  /// `YYYY-MM-DD` day bucket derived from [createdAt]. Used by Track B's
  /// grouping header. Returns an empty string if [createdAt] is null.
  String get dayKey {
    final ts = createdAt;
    if (ts == null) return '';
    final y = ts.year.toString().padLeft(4, '0');
    final m = ts.month.toString().padLeft(2, '0');
    final d = ts.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
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