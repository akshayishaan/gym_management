import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Client-side invoice PDF, ported from the web `app/dashboard/payments/[id]/invoice`.
///
/// This is the **only hardcoded-color surface in the app** (per CLAUDE.md):
/// the invoice always renders on a white background with a fixed black / gray /
/// green palette (green for the amount and "PAID" status, gray for muted text),
/// never the per-gym `primaryColor` or dark-mode tokens. The web invoice's
/// `print:` styles collapse to the same white/gray/green scheme, so this PDF is
/// the faithful mobile equivalent.
///
/// [amountText]/[methodText]/[paidAtText] are pre-formatted display strings
/// (via `formatCurrency`/`capitalizeWords`/`formatDate`) so this builder stays a
/// pure layout function with no business formatting.
Future<Uint8List> buildInvoicePdf({
  required String gymName,
  String? address,
  String? phone,
  String? email,
  required String memberName,
  required String amountText,
  required String methodText,
  required String invoiceNumber,
  required String paidAtText,
  String? planName,
  String? notes,
  required String status, // 'paid' | 'voided' | 'refunded'
}) async {
  final PdfColor black = PdfColor.fromHex('#111827');
  final PdfColor muted = PdfColor.fromHex('#6B7280');
  final PdfColor green = PdfColor.fromHex('#2A9D69');
  final PdfColor greenTint = PdfColor.fromHex('#E8F5EE');
  final PdfColor warning = PdfColor.fromHex('#F6A313');
  final PdfColor warningTint = PdfColor.fromHex('#FEF3E2');
  final PdfColor neutralTint = PdfColor.fromHex('#F3F4F6');
  final PdfColor divider = PdfColor.fromHex('#D1D5DB');

  final String statusLabel = status.toUpperCase();
  final PdfColor statusText;
  final PdfColor statusFill;
  switch (status) {
    case 'paid':
      statusText = green;
      statusFill = greenTint;
      break;
    case 'refunded':
      statusText = warning;
      statusFill = warningTint;
      break;
    default: // voided
      statusText = muted;
      statusFill = neutralTint;
      break;
  }

  final String itemDescription =
      (planName != null && planName.isNotEmpty) ? planName : 'Membership Fee';

  final pw.Document doc = pw.Document();

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: <pw.Widget>[
            // ── Header: gym identity (left) + receipt meta (right) ─────────
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: <pw.Widget>[
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: <pw.Widget>[
                      pw.Container(
                        width: 44,
                        height: 44,
                        alignment: pw.Alignment.center,
                        decoration: pw.BoxDecoration(
                          color: green,
                          borderRadius: pw.BorderRadius.circular(12),
                        ),
                        child: pw.Text(
                          gymName.isEmpty ? '' : gymName[0].toUpperCase(),
                          style: const pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 12),
                      pw.Text(
                        gymName,
                        style: pw.TextStyle(
                          color: black,
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      if (address != null && address.isNotEmpty) ...<pw.Widget>[
                        pw.SizedBox(height: 4),
                        pw.Text(
                          address,
                          style: pw.TextStyle(color: muted, fontSize: 10),
                        ),
                      ],
                      if (phone != null && phone.isNotEmpty)
                        pw.Text(
                          phone,
                          style: pw.TextStyle(color: muted, fontSize: 10),
                        ),
                      if (email != null && email.isNotEmpty)
                        pw.Text(
                          email,
                          style: pw.TextStyle(color: muted, fontSize: 10),
                        ),
                    ],
                  ),
                ),
                pw.SizedBox(width: 16),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: <pw.Widget>[
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: pw.BoxDecoration(
                        color: statusFill,
                        borderRadius: pw.BorderRadius.circular(999),
                      ),
                      child: pw.Text(
                        statusLabel,
                        style: pw.TextStyle(
                          color: statusText,
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 14),
                    pw.Text(
                      'Receipt',
                      style: pw.TextStyle(
                        color: muted,
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      invoiceNumber,
                      style: pw.TextStyle(
                        color: black,
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      paidAtText,
                      style: pw.TextStyle(color: muted, fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: 20),
            _dashedDivider(divider),
            pw.SizedBox(height: 16),

            // ── Received from ──────────────────────────────────────────────
            pw.Container(
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                color: neutralTint,
                borderRadius: pw.BorderRadius.circular(12),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: <pw.Widget>[
                  pw.Text(
                    'RECEIVED FROM',
                    style: pw.TextStyle(
                      color: muted,
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    memberName,
                    style: pw.TextStyle(
                      color: black,
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // ── Line item ──────────────────────────────────────────────────
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: <pw.Widget>[
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: <pw.Widget>[
                      pw.Text(
                        itemDescription,
                        style: pw.TextStyle(
                          color: black,
                          fontSize: 13,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      if (notes != null && notes.isNotEmpty) ...<pw.Widget>[
                        pw.SizedBox(height: 4),
                        pw.Text(
                          notes,
                          style: pw.TextStyle(color: muted, fontSize: 10),
                        ),
                      ],
                    ],
                  ),
                ),
                pw.SizedBox(width: 16),
                pw.Text(
                  amountText,
                  style: pw.TextStyle(
                    color: black,
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 16),
            _dashedDivider(divider),
            pw.SizedBox(height: 16),

            // ── Method + total ─────────────────────────────────────────────
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: <pw.Widget>[
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: <pw.Widget>[
                      pw.Text(
                        'PAYMENT METHOD',
                        style: pw.TextStyle(
                          color: muted,
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        methodText,
                        style: pw.TextStyle(
                          color: black,
                          fontSize: 13,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: <pw.Widget>[
                    pw.Text(
                      'TOTAL PAID',
                      style: pw.TextStyle(
                        color: muted,
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      amountText,
                      style: pw.TextStyle(
                        color: green,
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: 28),
            pw.Text(
              'Thank you for training with us.',
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                color: muted,
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        );
      },
    ),
  );

  return doc.save();
}

/// A thin dashed separator line, approximating the web invoice's
/// `border-dashed` dividers (the `pdf` package has no dashed-border primitive).
pw.Widget _dashedDivider(PdfColor color) {
  const int dashes = 60;
  return pw.Row(
    children: List<pw.Widget>.generate(
      dashes,
      (_) => pw.Container(
        width: 4,
        height: 1,
        margin: const pw.EdgeInsets.only(right: 4),
        color: color,
      ),
    ),
  );
}
