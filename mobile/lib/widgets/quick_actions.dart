import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/theme.dart';
import 'app_surface.dart';

/// Four quick-action tiles inside an [AppSurface], mirroring the web
/// `QuickActions`. Each tile is a ~48px icon chip (rounded 18px) with a tinted
/// background and an 11px bold label beneath it.
class QuickActions extends StatelessWidget {
  const QuickActions({
    super.key,
    required this.onAddMember,
    required this.onRecordPayment,
    required this.onRemind,
    required this.onReports,
  });

  final VoidCallback onAddMember;
  final VoidCallback onRecordPayment;
  final VoidCallback onRemind;
  final VoidCallback onReports;

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens ext = Theme.of(context).extension<AppThemeTokens>()!;
    final ThemeTokens t = ext.tokens;

    return AppSurface(
      borderRadius: BorderRadius.circular(t.radius * 1.55), // ~28px
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _ActionTile(
            label: 'Add',
            icon: Icons.person_add,
            background: t.primary.value,
            foreground: t.primary.foreground,
            onTap: onAddMember,
          ),
          _ActionTile(
            label: 'Payment',
            icon: Icons.credit_card,
            background: withOpacity(t.success.value, 0.10),
            foreground: t.success.value,
            onTap: onRecordPayment,
          ),
          _ActionTile(
            label: 'Remind',
            icon: Icons.notifications,
            background: withOpacity(t.warning.value, 0.10),
            foreground: t.warning.value,
            onTap: onRemind,
          ),
          _ActionTile(
            label: 'Reports',
            icon: Icons.bar_chart,
            background: t.accent.value,
            foreground: t.accent.foreground,
            onTap: onReports,
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, size: 20, color: foreground),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                  color: Theme.of(context).extension<AppThemeTokens>()!.tokens.foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
