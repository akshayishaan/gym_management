import 'package:flutter/material.dart';
import 'package:gym_api/gym_api.dart';

import '../data/formatters.dart';
import '../theme/colors.dart';
import '../theme/theme.dart';
import 'app_snackbar.dart';
import 'app_surface.dart';
import 'avatar.dart';
import 'status_badge.dart';

enum _MemberAction { view, renew, edit, whatsapp, sms, delete }

/// A member list card mirroring the web `MemberCard`: avatar + name/plan +
/// status badge + overflow menu, then a footer row with contact/expiry on the
/// left and a due/paid indicator on the right.
class MemberCard extends StatelessWidget {
  const MemberCard({
    super.key,
    required this.member,
    required this.currency,
    required this.onTap,
    required this.onRenew,
    required this.onEdit,
    required this.onDelete,
  });

  final MemberResponse member;
  final String currency;
  final VoidCallback onTap;
  final VoidCallback onRenew;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  String _reminderMessage() {
    final String expiry = member.membershipExpiry != null
        ? formatDate(member.membershipExpiry!)
        : 'soon';
    return 'Hi ${member.name}, your gym membership expires on $expiry. '
        'Please renew to continue! 💪';
  }

  Future<void> _handleAction(
    BuildContext context,
    _MemberAction action,
    String reminder,
  ) async {
    switch (action) {
      case _MemberAction.view:
        onTap();
        break;
      case _MemberAction.renew:
        onRenew();
        break;
      case _MemberAction.edit:
        onEdit();
        break;
      case _MemberAction.whatsapp:
        final bool ok =
            await launchExternal(buildWhatsAppLink(member.phone, reminder));
        if (!ok && context.mounted) {
          showAppSnackBar(context, 'Could not open WhatsApp', isError: true);
        }
        break;
      case _MemberAction.sms:
        final bool ok =
            await launchExternal(buildSmsLink(member.phone, reminder));
        if (!ok && context.mounted) {
          showAppSnackBar(context, 'Could not open SMS', isError: true);
        }
        break;
      case _MemberAction.delete:
        await _confirmDelete(context);
        break;
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        final AppThemeTokens ext =
            Theme.of(dialogContext).extension<AppThemeTokens>()!;
        final ThemeTokens t = ext.tokens;
        return AlertDialog(
          title: const Text('Delete Member'),
          content: Text.rich(
            TextSpan(
              text: 'Are you sure you want to delete ',
              children: <InlineSpan>[
                TextSpan(
                  text: member.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const TextSpan(text: '? This action cannot be undone.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(
                'Delete',
                style: TextStyle(color: t.destructive.value),
              ),
            ),
          ],
        );
      },
    );
    if (confirmed == true) onDelete();
  }

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens ext = Theme.of(context).extension<AppThemeTokens>()!;
    final ThemeTokens t = ext.tokens;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final MemberDisplayStatus? status = member.status;
    final bool canRenew = status == MemberDisplayStatus.expired ||
        status == MemberDisplayStatus.expiring;

    final String phonePart =
        member.phone.isNotEmpty ? member.phone : 'No phone number';
    final String untilPart = member.membershipExpiry != null
        ? ' · until ${formatDate(member.membershipExpiry!)}'
        : '';

    final Color dueColor = isDark ? t.warning.value : t.warning.foreground;

    return AppSurface(
      onTap: onTap,
      borderRadius: BorderRadius.circular(25.6), // 1.6rem
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Avatar(name: member.name, size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      member.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: t.foreground,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      member.planName ?? 'No plan assigned',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: t.muted.foreground,
                      ),
                    ),
                  ],
                ),
              ),
              if (status != null) ...<Widget>[
                StatusBadge(
                  variant: variantFromDisplayStatus(status),
                  label: displayStatusLabel(status),
                  days: member.daysUntilExpiry,
                ),
                const SizedBox(width: 4),
              ],
              PopupMenuButton<_MemberAction>(
                icon: Icon(Icons.more_horiz, color: t.foreground),
                padding: EdgeInsets.zero,
                iconSize: 22,
                onSelected: (_MemberAction a) =>
                    _handleAction(context, a, _reminderMessage()),
                itemBuilder: (BuildContext context) =>
                    <PopupMenuEntry<_MemberAction>>[
                  const PopupMenuItem<_MemberAction>(
                    value: _MemberAction.view,
                    child: _MenuItem(
                        icon: Icons.visibility_outlined, label: 'View Details'),
                  ),
                  if (canRenew)
                    PopupMenuItem<_MemberAction>(
                      value: _MemberAction.renew,
                      child: _MenuItem(
                        icon: Icons.refresh,
                        label: 'Renew Membership',
                        color: t.primary.value,
                      ),
                    ),
                  const PopupMenuItem<_MemberAction>(
                    value: _MemberAction.edit,
                    child: _MenuItem(icon: Icons.edit_outlined, label: 'Edit'),
                  ),
                  if (member
                      .phone.isNotEmpty) ...<PopupMenuEntry<_MemberAction>>[
                    const PopupMenuDivider(),
                    PopupMenuItem<_MemberAction>(
                      value: _MemberAction.whatsapp,
                      child: _MenuItem(
                        icon: Icons.chat_outlined,
                        label: 'WhatsApp',
                        iconColor: t.success.value,
                      ),
                    ),
                    PopupMenuItem<_MemberAction>(
                      value: _MemberAction.sms,
                      child: _MenuItem(
                        icon: Icons.sms_outlined,
                        label: 'SMS',
                        iconColor: t.primary.value,
                      ),
                    ),
                    const PopupMenuDivider(),
                  ],
                  PopupMenuItem<_MemberAction>(
                    value: _MemberAction.delete,
                    child: _MenuItem(
                      icon: Icons.delete_outline,
                      label: 'Delete',
                      color: t.destructive.value,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              border:
                  Border(top: BorderSide(color: withOpacity(t.border, 0.6))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Expanded(
                  child: Text(
                    '$phonePart$untilPart',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: t.muted.foreground,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  member.dueAmount > 0
                      ? '${formatCurrency(member.dueAmount, currency)} due'
                      : 'Paid',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: member.dueAmount > 0 ? dueColor : t.success.value,
                  ),
                ),
              ],
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
    this.iconColor,
  });

  final IconData icon;
  final String label;

  /// Applied to both icon and text when set.
  final Color? color;

  /// Overrides just the icon color.
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens ext = Theme.of(context).extension<AppThemeTokens>()!;
    final ThemeTokens t = ext.tokens;
    final Color effectiveIconColor = iconColor ?? color ?? t.muted.foreground;
    final Color effectiveTextColor = color ?? t.foreground;

    return Row(
      children: <Widget>[
        Icon(icon, size: 18, color: effectiveIconColor),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(fontSize: 14, color: effectiveTextColor),
        ),
      ],
    );
  }
}
