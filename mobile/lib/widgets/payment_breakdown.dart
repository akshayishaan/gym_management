import 'package:flutter/material.dart';

import '../data/formatters.dart';
import '../theme/colors.dart';
import '../theme/theme.dart';

/// A single charge/dues line in a [PaymentBreakdown].
class PaymentBreakdownItem {
  const PaymentBreakdownItem({required this.label, required this.value});

  final String label;
  final num value;
}

/// A stacked breakdown card mirroring the web `PaymentBreakdown`.
///
/// Rows (label left, value right) → "Amount paid" → divider → trailing balance
/// row showing either the remaining amount (warning) or the settled label
/// (success).
class PaymentBreakdown extends StatelessWidget {
  const PaymentBreakdown({
    super.key,
    required this.items,
    required this.amountPaid,
    required this.currency,
    this.balanceLabel = 'Due after',
    this.settledLabel = 'Paid in full',
  });

  final List<PaymentBreakdownItem> items;
  final num amountPaid;
  final String currency;
  final String balanceLabel;
  final String settledLabel;

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens ext = Theme.of(context).extension<AppThemeTokens>()!;
    final ThemeTokens t = ext.tokens;

    final num total = items.fold<num>(
      0,
      (num sum, PaymentBreakdownItem i) => sum + i.value,
    );
    final num balance = total > amountPaid ? total - amountPaid : 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: withOpacity(t.muted.value, 0.50),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: withOpacity(t.border, 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (final PaymentBreakdownItem item in items)
            _Row(
              label: item.label,
              value: formatCurrency(item.value, currency),
              muted: t.muted.foreground,
              valueColor: t.foreground,
            ),
          _Row(
            label: 'Amount paid',
            value: formatCurrency(amountPaid, currency),
            muted: t.muted.foreground,
            valueColor: t.foreground,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    balanceLabel,
                    style: TextStyle(fontSize: 14, color: t.muted.foreground),
                  ),
                ),
                _TrailingBadge(
                  balance: balance,
                  balanceText: formatCurrency(balance, currency),
                  settledLabel: settledLabel,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    required this.muted,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color muted;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(label, style: TextStyle(fontSize: 14, color: muted)),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrailingBadge extends StatelessWidget {
  const _TrailingBadge({
    required this.balance,
    required this.balanceText,
    required this.settledLabel,
  });

  final num balance;
  final String balanceText;
  final String settledLabel;

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens ext = Theme.of(context).extension<AppThemeTokens>()!;
    final ThemeTokens t = ext.tokens;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final bool clear = balance <= 0;
    final Color fg;
    final Color bg;
    final Color border;
    final String text;

    if (clear) {
      fg = t.success.value;
      bg = withOpacity(t.success.value, 0.10);
      border = withOpacity(t.success.value, 0.20);
      text = settledLabel;
    } else {
      // Web: `text-warning-foreground dark:text-warning`.
      fg = isDark ? t.warning.value : t.warning.foreground;
      bg = withOpacity(t.warning.value, 0.15);
      border = withOpacity(t.warning.value, 0.25);
      text = balanceText;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}
