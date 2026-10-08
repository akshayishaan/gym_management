import 'package:flutter/material.dart';

import '../../core/utils/money.dart';
import '../colors.dart';
import '../spacing.dart';

/// One-line outcome shown under an amount field, so staff can see what the
/// member will still owe before confirming a payment.
class LatoBalanceLine extends StatelessWidget {
  const LatoBalanceLine({
    super.key,
    required this.text,
    required this.color,
    required this.icon,
  });

  /// Green "paid in full" when nothing remains, red "Due after this payment"
  /// otherwise. [clearedText] words the zero case ("All dues cleared" for a
  /// dues payment).
  factory LatoBalanceLine.afterPayment({
    Key? key,
    required double dueAfter,
    String clearedText = 'Paid in full',
  }) {
    if (dueAfter <= 0) {
      return LatoBalanceLine(
        key: key,
        text: clearedText,
        color: LatoColors.success,
        icon: Icons.check_circle_outline,
      );
    }
    return LatoBalanceLine(
      key: key,
      text: 'Due after this payment: ${_money(dueAfter)}',
      color: LatoColors.error,
      icon: Icons.info_outline,
    );
  }

  final String text;
  final Color color;
  final IconData icon;

  static String _money(double v) => formatInr(v, decimals: v % 1 == 0 ? 0 : 2);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: LatoSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}
