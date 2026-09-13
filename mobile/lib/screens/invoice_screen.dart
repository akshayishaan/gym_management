import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_api/gym_api.dart';
import 'package:printing/printing.dart';

import '../core/settings/gym_settings_controller.dart';
import '../core/settings/gym_settings_state.dart';
import '../data/formatters.dart';
import '../data/invoice_pdf.dart';
import '../data/payment_providers.dart';
import '../layout/shell.dart';
import '../widgets/app_snackbar.dart';

// The invoice's hardcoded palette (the one hardcoded-color surface in the app),
// mirroring `data/invoice_pdf.dart`. These are fixed — never theme tokens — so
// the receipt renders identically in light/dark mode and across gyms.
const Color _kInk = Color(0xFF111827);
const Color _kMuted = Color(0xFF6B7280);
const Color _kGreen = Color(0xFF2A9D69);
const Color _kGreenTint = Color(0xFFE8F5EE);
const Color _kWarning = Color(0xFFF6A313);
const Color _kWarningTint = Color(0xFFFEF3E2);
const Color _kNeutralTint = Color(0xFFF3F4F6);
const Color _kDivider = Color(0xFFD1D5DB);

/// Full-screen invoice: fetches the payment, renders a white receipt preview,
/// and shares a client-side PDF via `pdf` + `printing`.
class InvoiceScreen extends ConsumerWidget {
  const InvoiceScreen({super.key, required this.paymentId});

  final String paymentId;

  Future<void> _share(BuildContext context, WidgetRef ref) async {
    final GymSettingsState settings =
        ref.read(gymSettingsControllerProvider);
    final PaymentResponse? payment =
        ref.read(paymentProvider(paymentId)).valueOrNull;

    if (payment == null) {
      showAppSnackBar(context, 'Invoice is still loading', isError: true);
      return;
    }

    final Uint8List bytes = await buildInvoicePdf(
      gymName: settings.gymName,
      address: settings.address,
      phone: settings.phone,
      email: settings.email,
      memberName: payment.memberName,
      amountText: formatCurrency(payment.amount, settings.currency),
      methodText: capitalizeWords(payment.method.value.replaceAll('_', ' ')),
      invoiceNumber: payment.invoiceNumber,
      paidAtText: formatDate(payment.paidAt),
      planName: payment.planName,
      notes: payment.notes,
      status: payment.status.value,
    );

    await Printing.sharePdf(
      bytes: bytes,
      filename: '${payment.invoiceNumber}.pdf',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GymSettingsState settings =
        ref.watch(gymSettingsControllerProvider);
    final AsyncValue<PaymentResponse> paymentAsync =
        ref.watch(paymentProvider(paymentId));

    return AppShell(
      mode: ShellMode.stack,
      title: 'Invoice',
      selectedIndex: 2,
      onSelectTab: (_) {},
      onBack: () => Navigator.of(context).maybePop(),
      actions: <Widget>[
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: FilledButton.icon(
            onPressed: paymentAsync.valueOrNull == null
                ? null
                : () => _share(context, ref),
            style: FilledButton.styleFrom(
              backgroundColor: _kGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            icon: const Icon(Icons.ios_share, size: 16),
            label: const Text('Share'),
          ),
        ),
      ],
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 448),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: paymentAsync.when(
              data: (PaymentResponse payment) =>
                  _InvoiceCard(payment: payment, settings: settings),
              loading: () => const _InvoiceSkeleton(),
              error: (Object e, StackTrace st) => _buildError(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.error_outline, size: 32, color: _kMuted),
          SizedBox(height: 12),
          Text(
            'Invoice could not load',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _kInk,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Please try again.',
            style: TextStyle(fontSize: 13, color: _kMuted),
          ),
        ],
      ),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  const _InvoiceCard({required this.payment, required this.settings});

  final PaymentResponse payment;
  final GymSettingsState settings;

  @override
  Widget build(BuildContext context) {
    final PaymentResponse p = payment;

    final (Color statusText, Color statusFill) = switch (p.status.value) {
      'paid' => (_kGreen, _kGreenTint),
      'refunded' => (_kWarning, _kWarningTint),
      _ => (_kMuted, _kNeutralTint),
    };

    final String itemDescription = (p.planName != null && p.planName!.isNotEmpty)
        ? p.planName!
        : 'Membership Fee';
    final String methodText =
        capitalizeWords(p.method.value.replaceAll('_', ' '));
    final String amountText = formatCurrency(p.amount, settings.currency);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: _kDivider),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // ── Header ───────────────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _kGreen,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        settings.gymName.isEmpty
                            ? ''
                            : settings.gymName[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      settings.gymName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: _kInk,
                      ),
                    ),
                    if (settings.address != null &&
                        settings.address!.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 4),
                      Text(
                        settings.address!,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: _kMuted,
                        ),
                      ),
                    ],
                    if (settings.phone != null &&
                        settings.phone!.isNotEmpty)
                      Text(
                        settings.phone!,
                        style: const TextStyle(fontSize: 12, color: _kMuted),
                      ),
                    if (settings.email != null && settings.email!.isNotEmpty)
                      Text(
                        settings.email!,
                        style: const TextStyle(fontSize: 12, color: _kMuted),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusFill,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      p.status.value.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                        color: statusText,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Receipt',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.8,
                      color: _kMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    p.invoiceNumber,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _kInk,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatDate(p.paidAt),
                    style: const TextStyle(fontSize: 12, color: _kMuted),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),
          const _DashedLine(color: _kDivider),
          const SizedBox(height: 16),

          // ── Received from ────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _kNeutralTint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'RECEIVED FROM',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                    color: _kMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  p.memberName,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _kInk,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Line item ────────────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      itemDescription,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _kInk,
                      ),
                    ),
                    if (p.notes != null && p.notes!.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 4),
                      Text(
                        p.notes!,
                        style: const TextStyle(fontSize: 12, color: _kMuted),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Text(
                amountText,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _kInk,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const _DashedLine(color: _kDivider),
          const SizedBox(height: 16),

          // ── Method + total ───────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Payment method',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                        color: _kMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      methodText,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _kInk,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  const Text(
                    'Total paid',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                      color: _kMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    amountText,
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: _kGreen,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 28),
          const Text(
            'Thank you for training with us.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _kMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceSkeleton extends StatelessWidget {
  const _InvoiceSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 320,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
      ),
    );
  }
}

class _DashedLine extends StatelessWidget {
  const _DashedLine({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1,
      width: double.infinity,
      child: CustomPaint(painter: _DashedLinePainter(color)),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  const _DashedLinePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    const double dash = 4;
    const double gap = 3;
    double x = 0;
    while (x < size.width) {
      final double end = (x + dash).clamp(0, size.width);
      canvas.drawLine(Offset(x, 0), Offset(end, 0), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter oldDelegate) =>
      oldDelegate.color != color;
}
