import 'package:flutter/material.dart';

import '../spacing.dart';
import 'lato_status_chip.dart';

/// Wire value and label for each payment method the backend accepts.
const latoPaymentMethods = <(String value, String label)>[
  ('cash', 'Cash'),
  ('upi', 'UPI'),
  ('card', 'Card'),
  ('bank_transfer', 'Bank'),
  ('other', 'Other'),
];

/// Row of selectable payment-method pills: lime when selected, neutral
/// otherwise (same look as the Payments filter pills), 48dp tap areas.
class LatoPaymentMethodPills extends StatelessWidget {
  const LatoPaymentMethodPills({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: LatoSpacing.sm,
      children: [
        for (final (value, label) in latoPaymentMethods)
          Semantics(
            button: true,
            selected: selected == value,
            child: InkWell(
              borderRadius: LatoRadius.chip,
              onTap: () => onSelected(value),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Center(
                  widthFactor: 1,
                  child: LatoStatusChip(
                    label: label,
                    tone: selected == value
                        ? LatoChipTone.primary
                        : LatoChipTone.neutral,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
