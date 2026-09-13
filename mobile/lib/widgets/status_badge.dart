import 'package:flutter/material.dart';
import 'package:gym_api/gym_api.dart';

import '../theme/colors.dart';
import '../theme/theme.dart';

/// The five badge states a membership/member can present.
enum BadgeVariant { active, expiring, expired, reversed, urgent }

/// Maps a member's display status to a [BadgeVariant]. `null` (no membership)
/// falls back to [BadgeVariant.active]; callers should gate on a null status
/// before rendering a badge (see [MemberCard]).
BadgeVariant variantFromDisplayStatus(MemberDisplayStatus? status) {
  return switch (status) {
    MemberDisplayStatus.active => BadgeVariant.active,
    MemberDisplayStatus.expiring => BadgeVariant.expiring,
    MemberDisplayStatus.expired => BadgeVariant.expired,
    null => BadgeVariant.active,
  };
}

/// Title-cased display label for a member display status.
String displayStatusLabel(MemberDisplayStatus? status) {
  return switch (status) {
    MemberDisplayStatus.active => 'Active',
    MemberDisplayStatus.expiring => 'Expiring Soon',
    MemberDisplayStatus.expired => 'Expired',
    null => 'Active',
  };
}

/// Immutable per-variant color set resolved against the current tokens.
class _BadgeStyle {
  const _BadgeStyle(this.dot, this.text, this.background, this.border);

  /// Dot fill and (for active/expiring/expired) the accent color.
  final Color dot;
  final Color text;
  final Color background;
  final Color border;
}

_BadgeStyle _styleFor(BadgeVariant variant, ThemeTokens t, Brightness b) {
  switch (variant) {
    case BadgeVariant.active:
      return _BadgeStyle(
        t.success.value,
        t.success.value,
        withOpacity(t.success.value, 0.10),
        withOpacity(t.success.value, 0.20),
      );
    case BadgeVariant.expiring:
      // Web: `text-warning-foreground dark:text-warning`.
      final Color text =
          b == Brightness.dark ? t.warning.value : t.warning.foreground;
      return _BadgeStyle(
        t.warning.value,
        text,
        withOpacity(t.warning.value, 0.15),
        withOpacity(t.warning.value, 0.25),
      );
    case BadgeVariant.expired:
      return _BadgeStyle(
        t.destructive.value,
        t.destructive.value,
        withOpacity(t.destructive.value, 0.10),
        withOpacity(t.destructive.value, 0.20),
      );
    case BadgeVariant.urgent:
      return _BadgeStyle(
        t.destructive.value,
        t.destructive.value,
        withOpacity(t.destructive.value, 0.10),
        withOpacity(t.destructive.value, 0.20),
      );
    case BadgeVariant.reversed:
      return _BadgeStyle(
        t.secondary.foreground,
        t.secondary.foreground,
        t.secondary.value,
        t.secondary.value,
      );
  }
}

/// A rounded pill badge (dot + label) for membership/member status.
///
/// DOT rule (mirrors the web `MemberCard`): when [days] is `0..7` and the
/// variant is a display status, the label becomes `Today`/`${days}d` instead
/// of the status word. Negative values are never rendered. `reversed` always
/// shows `Reversed`.
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.variant,
    required this.label,
    this.days,
  });

  final BadgeVariant variant;
  final String label;
  final int? days;

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens ext = Theme.of(context).extension<AppThemeTokens>()!;
    final ThemeTokens t = ext.tokens;
    final Brightness brightness = Theme.of(context).brightness;
    final _BadgeStyle style = _styleFor(variant, t, brightness);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: style.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: style.dot,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _resolveLabel(),
            style: TextStyle(
              color: style.text,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  String _resolveLabel() {
    if (variant == BadgeVariant.reversed) return 'Reversed';
    final int? d = days;
    if (d != null && d >= 0 && d <= 7) {
      return d == 0 ? 'Today' : '${d}d';
    }
    return label;
  }
}
