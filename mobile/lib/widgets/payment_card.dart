import 'package:flutter/material.dart';
import 'package:gym_api/gym_api.dart';

import '../data/formatters.dart';
import '../theme/colors.dart';
import '../theme/theme.dart';
import 'app_surface.dart';
import 'avatar.dart';

/// The action a user picks from a payment card's overflow menu.
enum PaymentCardAction { invoice, void_, refund, reverse }

/// A single payment in the Payments list, ported from the web `PaymentCard`.
///
/// Renders the member avatar/name, an optional Voided/Refunded badge, the plan
/// (or "Dues payment") label, the amount (struck-through + muted when not
/// paid), the invoice number/date, a method badge, and an overflow menu with
/// View invoice / Void / Refund / Reverse actions. Actions are callback-driven
/// so this widget stays pure and unit-testable.
class PaymentCard extends StatelessWidget {
  const PaymentCard({
    super.key,
    required this.payment,
    required this.currency,
    required this.onInvoice,
    required this.onVoid,
    required this.onRefund,
    required this.onReverse,
  });

  final PaymentListResponsePaymentsInner payment;
  final String currency;
  final VoidCallback onInvoice;
  final VoidCallback onVoid;
  final VoidCallback onRefund;
  final VoidCallback onReverse;

  bool get _isPaid =>
      payment.status == PaymentListResponsePaymentsInnerStatusEnum.paid;

  bool get _canReverse =>
      _isPaid &&
      payment.kind == PaymentListResponsePaymentsInnerKindEnum.planPurchase &&
      payment.membershipId != null &&
      payment.membershipStatus !=
          PaymentListResponsePaymentsInnerMembershipStatusEnum.reversed;

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens ext = Theme.of(context).extension<AppThemeTokens>()!;
    final ThemeTokens t = ext.tokens;
    final PaymentListResponsePaymentsInner p = payment;

    return AppSurface(
      borderRadius: BorderRadius.circular(t.radius * 1.42),
      padding: const EdgeInsets.all(16),
      color: _isPaid ? null : withOpacity(t.muted.value, 0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Avatar(
                name: p.memberName,
                size: 48,
                background: withOpacity(t.success.value, 0.10),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            p.memberName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: t.foreground,
                            ),
                          ),
                        ),
                        if (p.status ==
                            PaymentListResponsePaymentsInnerStatusEnum.voided) ...<
                          Widget
                        >[
                          const SizedBox(width: 6),
                          _Pill(
                            label: 'Voided',
                            foreground: t.secondary.foreground,
                            background: t.secondary.value,
                            border: t.secondary.value,
                          ),
                        ],
                        if (p.status ==
                            PaymentListResponsePaymentsInnerStatusEnum
                                .refunded) ...<Widget>[
                          const SizedBox(width: 6),
                          _Pill(
                            label: 'Refunded',
                            foreground: Theme.of(context).brightness ==
                                    Brightness.dark
                                ? t.warning.value
                                : t.warning.foreground,
                            background: withOpacity(t.warning.value, 0.15),
                            border: withOpacity(t.warning.value, 0.25),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      p.planName ?? 'Dues payment',
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
              const SizedBox(width: 12),
              Text(
                formatCurrency(p.amount, currency),
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _isPaid ? t.success.value : t.muted.foreground,
                  decoration:
                      _isPaid ? TextDecoration.none : TextDecoration.lineThrough,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: withOpacity(t.border, 0.6)),
              ),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    '${p.invoiceNumber} · ${formatDate(p.paidAt)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: t.muted.foreground,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _MethodBadge(payment: p, tokens: t),
                const SizedBox(width: 4),
                _MoreButton(
                  tokens: t,
                  onTap: () => _openMenu(context, t),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openMenu(BuildContext context, ThemeTokens t) async {
    final PaymentCardAction? action = await showModalBottomSheet<
        PaymentCardAction>(
      context: context,
      backgroundColor: t.card.value,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(t.radius * 1.77),
        ),
      ),
      builder: (BuildContext sheetContext) {
        final ThemeTokens st =
            Theme.of(sheetContext).extension<AppThemeTokens>()!.tokens;
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Center(
                  child: Container(
                    width: 40,
                    height: 6,
                    decoration: BoxDecoration(
                      color: st.muted.value,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _MenuTile(
                  icon: Icons.download_outlined,
                  label: 'View invoice',
                  tokens: st,
                  onTap: () =>
                      Navigator.pop(sheetContext, PaymentCardAction.invoice),
                ),
                if (_isPaid) ...<Widget>[
                  _MenuTile(
                    icon: Icons.block,
                    label: 'Void payment',
                    tokens: st,
                    onTap: () =>
                        Navigator.pop(sheetContext, PaymentCardAction.void_),
                  ),
                  _MenuTile(
                    icon: Icons.restore,
                    label: 'Refund payment',
                    tokens: st,
                    onTap: () =>
                        Navigator.pop(sheetContext, PaymentCardAction.refund),
                  ),
                ],
                if (_canReverse)
                  _MenuTile(
                    icon: Icons.undo,
                    label: 'Reverse plan purchase',
                    tokens: st,
                    destructive: true,
                    onTap: () =>
                        Navigator.pop(sheetContext, PaymentCardAction.reverse),
                  ),
              ],
            ),
          ),
        );
      },
    );

    if (!context.mounted) return;
    switch (action) {
      case PaymentCardAction.invoice:
        onInvoice();
        break;
      case PaymentCardAction.void_:
        await _confirmVoid(context);
        break;
      case PaymentCardAction.refund:
        await _confirmRefund(context);
        break;
      case PaymentCardAction.reverse:
        await _confirmReverse(context);
        break;
      case null:
        break;
    }
  }

  Future<void> _confirmVoid(BuildContext context) async {
    final bool? ok = await _confirm(
      context,
      title: 'Void this payment?',
      description: payment.kind ==
              PaymentListResponsePaymentsInnerKindEnum.planPurchase
          ? 'The invoice remains in the audit history. Membership access stays '
              'active and the amount becomes due.'
          : 'The invoice remains in the audit history. The amount returns to '
              'outstanding dues.',
      confirmLabel: 'Void payment',
      destructive: false,
    );
    if (ok == true) onVoid();
  }

  Future<void> _confirmRefund(BuildContext context) async {
    final bool? ok = await _confirm(
      context,
      title: 'Refund this payment?',
      description:
          'Record a full refund of ${formatCurrency(payment.amount, currency)}. '
          'Membership access remains unchanged and the amount becomes due again.',
      confirmLabel: 'Record refund',
      destructive: false,
    );
    if (ok == true) onRefund();
  }

  Future<void> _confirmReverse(BuildContext context) async {
    final bool? ok = await _confirm(
      context,
      title: 'Reverse this Plan purchase?',
      description: 'The Membership period will be reversed and this Payment '
          'will be voided. Newer Membership transactions must be reversed '
          'first.',
      confirmLabel: 'Reverse purchase',
      destructive: true,
    );
    if (ok == true) onReverse();
  }

  Future<bool?> _confirm(
    BuildContext context, {
    required String title,
    required String description,
    required String confirmLabel,
    required bool destructive,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        final ThemeTokens dt =
            Theme.of(dialogContext).extension<AppThemeTokens>()!.tokens;
        return AlertDialog(
          title: Text(title),
          content: Text(description),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(
                confirmLabel,
                style: TextStyle(
                  color: destructive
                      ? dt.destructive.value
                      : dt.primary.value,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MethodBadge extends StatelessWidget {
  const _MethodBadge({required this.payment, required this.tokens});

  final PaymentListResponsePaymentsInner payment;
  final ThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = tokens;
    final bool dark = Theme.of(context).brightness == Brightness.dark;

    final String label;
    final Color foreground;
    final Color background;
    final Color border;

    switch (payment.method) {
      case PaymentListResponsePaymentsInnerMethodEnum.cash:
        label = 'Cash';
        foreground = t.success.value;
        background = withOpacity(t.success.value, 0.10);
        border = withOpacity(t.success.value, 0.20);
        break;
      case PaymentListResponsePaymentsInnerMethodEnum.card:
        label = 'Card';
        foreground = t.secondary.foreground;
        background = t.secondary.value;
        border = t.secondary.value;
        break;
      case PaymentListResponsePaymentsInnerMethodEnum.upi:
        label = 'UPI';
        foreground = t.primary.value;
        background = withOpacity(t.primary.value, 0.10);
        border = withOpacity(t.primary.value, 0.20);
        break;
      case PaymentListResponsePaymentsInnerMethodEnum.bankTransfer:
        label = 'Bank';
        foreground = dark ? t.warning.value : t.warning.foreground;
        background = withOpacity(t.warning.value, 0.15);
        border = withOpacity(t.warning.value, 0.25);
        break;
      case PaymentListResponsePaymentsInnerMethodEnum.other:
        label = 'Other';
        foreground = t.muted.foreground;
        background = t.muted.value;
        border = t.muted.value;
        break;
    }

    return _Pill(
      label: label,
      foreground: foreground,
      background: background,
      border: border,
    );
  }
}

class _MoreButton extends StatelessWidget {
  const _MoreButton({required this.tokens, required this.onTap});

  final ThemeTokens tokens;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: tokens.muted.value,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.more_horiz,
            size: 20,
            color: tokens.muted.foreground,
          ),
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.tokens,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final ThemeTokens tokens;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final Color color = destructive
        ? tokens.destructive.value
        : tokens.foreground;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        child: Row(
          children: <Widget>[
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.foreground,
    required this.background,
    required this.border,
  });

  final String label;
  final Color foreground;
  final Color background;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          height: 1.2,
          color: foreground,
        ),
      ),
    );
  }
}
