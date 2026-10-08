import 'package:flutter/material.dart';

import '../../../design/components/lato_card.dart';
import '../../../design/spacing.dart';
import '../domain/activity_log.dart';
import 'activity_styles.dart';

/// Single event card. Layout: avatar + staff name with time and short id +
/// action pill (header), then a plain-words title and the explanatory body,
/// with a vertical rail + colored node marker hugging the left edge.
class ActivityEventCard extends StatelessWidget {
  const ActivityEventCard({super.key, required this.log});
  final ActivityLog log;

  @override
  Widget build(BuildContext context) {
    final colors = log.colors;
    final body = log.details ?? '';

    return Semantics(
      label: log.title,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Vertical rail behind the card. left: 11 keeps it aligned with
          // the center of the 22x22 node marker.
          Positioned(
            left: 11,
            top: 8,
            bottom: 8.5,
            child: Container(width: 2, color: Alog.rail),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: LatoCard(
              padding: const EdgeInsets.all(17),
              borderColor: Alog.cardBorder,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Who did it, when, and what kind of change.
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AlogAvatar(
                        initials: _initials(log.staffName),
                        color: colors.fg,
                      ),
                      const SizedBox(width: LatoSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              log.staffName,
                              style: Alog.staffName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${log.timeLabel} \u00b7 #${log.shortId}',
                              style: Alog.sage12,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: LatoSpacing.sm),
                      AlogStatusPill(label: log.label, colors: colors),
                    ],
                  ),
                  const SizedBox(height: LatoSpacing.md),
                  Text(log.title, style: Alog.cardTitle),
                  if (body.isNotEmpty) ...[
                    const SizedBox(height: LatoSpacing.xs),
                    Text(body, style: Alog.bodyCopy),
                  ],
                ],
              ),
            ),
          ),
          Positioned(left: 0, top: 14, child: AlogNodeMarker(color: colors.fg)),
        ],
      ),
    );
  }

  /// First letter of first + last name, max 2 chars. Falls back to "?".
  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    final a = parts.first.substring(0, 1);
    final b = parts.last.substring(0, 1);
    return (a + b).toUpperCase();
  }
}

/// 22x22 circular node on the timeline rail with a colored border, glow
/// and inner dot.
class AlogNodeMarker extends StatelessWidget {
  const AlogNodeMarker({super.key, required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: Alog.railBg,
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 4,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
  }
}

/// Small colored status pill. Unlike `LatoStatusChip`, this uses the
/// `colors` triple from the [ActivityLog] model so each action gets its
/// own palette.
class AlogStatusPill extends StatelessWidget {
  const AlogStatusPill({super.key, required this.label, required this.colors});
  final String label;
  final ({Color bg, Color fg, Color border}) colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.border, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: colors.fg,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.65,
        ),
      ),
    );
  }
}

/// Square 28x28 avatar with bold initials tinted in the action's color.
class AlogAvatar extends StatelessWidget {
  const AlogAvatar({super.key, required this.initials, required this.color});
  final String initials;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Alog.avatarBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Alog.avatarBorder, width: 1),
      ),
      child: Text(
        initials,
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
