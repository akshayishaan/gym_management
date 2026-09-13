import 'package:flutter/material.dart';
import 'package:gym_api/gym_api.dart';

import '../data/formatters.dart';
import '../theme/colors.dart';
import '../theme/theme.dart';
import 'avatar.dart';

/// A single activity-log entry, mirroring the web `ActivityRow`: an avatar +
/// staff name, a colored action badge, the entity, and optional details.
class ActivityRow extends StatelessWidget {
  const ActivityRow({super.key, required this.log, required this.t});

  final ActivityListResponseLogsInner log;
  final ThemeTokens t;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Avatar(name: log.staffName, size: 36, background: t.secondary.value),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  log.staffName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: t.foreground,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                formatDate(log.createdAt),
                style: TextStyle(fontSize: 12, color: t.muted.foreground),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              _ActionBadge(action: log.action, t: t),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  capitalizeWords(log.entity),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: t.muted.foreground),
                ),
              ),
            ],
          ),
          if (log.details != null && log.details!.isNotEmpty) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              log.details!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: t.muted.foreground),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionBadge extends StatelessWidget {
  const _ActionBadge({required this.action, required this.t});

  final String action;
  final ThemeTokens t;

  (Color, Color) _colorsFor(String action) => switch (action) {
        'created' => (t.success.value, t.success.value),
        'updated' => (t.secondary.foreground, t.primary.value),
        'deleted' => (t.destructive.value, t.destructive.value),
        'voided' => (t.secondary.foreground, t.muted.foreground),
        'refunded' => (t.warning.value, t.warning.value),
        'reversed' => (t.destructive.value, t.destructive.value),
        'migrated' => (t.muted.foreground, t.primary.value),
        _ => (t.muted.foreground, t.muted.foreground),
      };

  @override
  Widget build(BuildContext context) {
    final (Color textColor, Color dotColor) = _colorsFor(action);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: withOpacity(textColor, 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            capitalizeWords(action),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
