import 'package:flutter/material.dart';
import 'package:gym_api/gym_api.dart';

import '../data/formatters.dart';
import '../theme/colors.dart';
import '../theme/theme.dart';
import 'app_section_label.dart';
import 'app_surface.dart';

enum _PlanAction { edit, duplicate, toggleActive }

/// A single plan in the Plans screen, ported from the web `PlanCard`.
///
/// Renders a leading state icon, the plan name + price/duration subtitle, a
/// "Most used" / "Paused" pill, an admin-only overflow menu (Edit / Duplicate /
/// Deactivate|Activate), a 3-column metric grid, feature chips, and — when
/// inactive — a dimmed surface with a warning accent bar and an explanatory
/// note. Actions are callback-driven so the widget stays pure.
class PlanCard extends StatelessWidget {
  const PlanCard({
    super.key,
    required this.plan,
    required this.currency,
    required this.isMostUsed,
    required this.isAdmin,
    required this.onEdit,
    required this.onDuplicate,
    required this.onToggleActive,
  });

  final PlanListResponsePlansInner plan;
  final String currency;
  final bool isMostUsed;
  final bool isAdmin;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onToggleActive;

  void _handleAction(_PlanAction action) {
    switch (action) {
      case _PlanAction.edit:
        onEdit();
        break;
      case _PlanAction.duplicate:
        onDuplicate();
        break;
      case _PlanAction.toggleActive:
        onToggleActive();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens ext = Theme.of(context).extension<AppThemeTokens>()!;
    final ThemeTokens t = ext.tokens;

    final bool active = plan.isActive;
    final PlanListItemResponseStats? stats = plan.stats;
    final List<String> features = plan.features ?? const <String>[];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (!active) ...<Widget>[
          Container(
            width: 4,
            margin: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: t.warning.value,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: AppSurface(
            color: active ? null : withOpacity(t.muted.value, 0.40),
            borderRadius: BorderRadius.circular(t.radius * 1.42),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _header(t, active),
                const SizedBox(height: 12),
                Text(
                  '${formatCurrency(plan.price, currency)} · '
                  '${plan.durationDays.toInt()} days',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: t.muted.foreground,
                  ),
                ),
                if (plan.description != null &&
                    plan.description!.trim().isNotEmpty) ...<Widget>[
                  const SizedBox(height: 6),
                  Text(
                    plan.description!.trim(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: t.muted.foreground,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                _metrics(t, stats),
                if (features.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 16),
                  _features(t, features),
                ],
                if (!active) ...<Widget>[
                  const SizedBox(height: 16),
                  Text(
                    'Hidden from new purchases. Existing memberships remain valid.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: t.warning.value,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _header(ThemeTokens t, bool active) {
    return Row(
      children: <Widget>[
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: active
                ? withOpacity(t.primary.value, 0.10)
                : withOpacity(t.warning.value, 0.15),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            active ? Icons.fitness_center : Icons.pause_circle_outline,
            size: 22,
            color: active ? t.primary.value : t.warning.value,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                plan.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: t.foreground,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: <Widget>[
                  if (isMostUsed)
                    _Pill(
                      label: 'Most used',
                      foreground: t.success.value,
                      background: withOpacity(t.success.value, 0.10),
                      border: withOpacity(t.success.value, 0.25),
                      icon: Icons.auto_awesome,
                    ),
                  if (!active)
                    _Pill(
                      label: 'Paused',
                      foreground: t.warning.foreground,
                      background: withOpacity(t.warning.value, 0.15),
                      border: withOpacity(t.warning.value, 0.25),
                    ),
                ],
              ),
            ],
          ),
        ),
        if (isAdmin) ...<Widget>[
          const SizedBox(width: 4),
          PopupMenuButton<_PlanAction>(
            icon: Icon(Icons.more_horiz, color: t.foreground),
            padding: EdgeInsets.zero,
            iconSize: 22,
            onSelected: _handleAction,
            itemBuilder: (BuildContext context) =>
                <PopupMenuEntry<_PlanAction>>[
              const PopupMenuItem<_PlanAction>(
                value: _PlanAction.edit,
                child: _MenuItem(
                  icon: Icons.edit_outlined,
                  label: 'Edit',
                ),
              ),
              const PopupMenuItem<_PlanAction>(
                value: _PlanAction.duplicate,
                child: _MenuItem(
                  icon: Icons.content_copy,
                  label: 'Duplicate',
                ),
              ),
              PopupMenuItem<_PlanAction>(
                value: _PlanAction.toggleActive,
                child: _MenuItem(
                  icon: active
                      ? Icons.pause_circle_outline
                      : Icons.play_circle_outline,
                  label: active ? 'Deactivate' : 'Activate',
                  color: active ? t.destructive.value : t.success.value,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _metrics(ThemeTokens t, PlanListItemResponseStats? stats) {
    final num members = stats?.activeMembers ?? 0;
    final num sales = stats?.salesYtd ?? 0;
    final num revenue = stats?.revenueAtSaleYtd ?? 0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _Metric(
          label: 'Members',
          value: members.toInt().toString(),
          tokens: t,
        ),
        _Metric(
          label: 'YTD sales',
          value: sales.toInt().toString(),
          tokens: t,
        ),
        _Metric(
          label: 'YTD revenue',
          value: formatCurrency(revenue, currency),
          tokens: t,
        ),
      ],
    );
  }

  Widget _features(ThemeTokens t, List<String> features) {
    const int maxShown = 3;
    final int shown = features.length > maxShown ? maxShown : features.length;
    final int remaining = features.length - shown;

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: <Widget>[
        for (int i = 0; i < shown; i++)
          _Pill(
            label: features[i],
            foreground: t.muted.foreground,
            background: t.muted.value,
            border: t.muted.value,
            icon: Icons.check,
          ),
        if (remaining > 0)
          _Pill(
            label: '+$remaining',
            foreground: t.muted.foreground,
            background: t.muted.value,
            border: t.muted.value,
          ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.tokens,
  });

  final String label;
  final String value;
  final ThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AppSectionLabel(label),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: tokens.foreground,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    this.color,
  });

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = Theme.of(context).extension<AppThemeTokens>()!.tokens;
    final Color effective = color ?? t.foreground;

    return Row(
      children: <Widget>[
        Icon(icon, size: 18, color: effective),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(fontSize: 14, color: effective)),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.foreground,
    required this.background,
    required this.border,
    this.icon,
  });

  final String label;
  final Color foreground;
  final Color background;
  final Color border;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 12, color: foreground),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              height: 1.2,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}
