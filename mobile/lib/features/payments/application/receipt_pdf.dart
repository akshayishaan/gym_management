import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/utils/money.dart';
import '../domain/payment.dart';

/// Builds the one-page receipt PDF for a paid [Payment].
///
/// Uses the bundled Roboto, which has the rupee sign (Lato and the built-in
/// PDF fonts do not). If the asset cannot load, falls back to the built-in
/// font and writes "Rs" instead.
Future<Uint8List> buildReceiptPdf({
  required Payment payment,
  String? gymName,
}) async {
  pw.Font regular;
  pw.Font bold;
  var hasRupee = true;
  try {
    regular = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Roboto-Regular.ttf'),
    );
    bold = pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Bold.ttf'));
  } catch (_) {
    regular = pw.Font.helvetica();
    bold = pw.Font.helveticaBold();
    hasRupee = false;
  }
  String money(num v) {
    final s = formatInr(v);
    return hasRupee ? s : s.replaceFirst('₹', 'Rs ');
  }

  final at = payment.paidAt ?? payment.createdAt;
  final dateLabel = at == null
      ? '-'
      : '${DateFormat('d MMM y').format(at.toLocal())}, '
            '${DateFormat.jm().format(at.toLocal())}';
  final planName = (payment.planName ?? '').isNotEmpty
      ? payment.planName!
      : (payment.kind == 'dues' ? 'Dues payment' : 'Membership payment');
  final features = payment.planFeatures ?? const <String>[];

  pw.Widget row(String label, String value) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 4),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
        ),
        pw.SizedBox(width: 24),
        pw.Flexible(
          child: pw.Text(
            value,
            textAlign: pw.TextAlign.right,
            style: pw.TextStyle(font: bold, fontSize: 11),
          ),
        ),
      ],
    ),
  );

  final doc = pw.Document(
    title: 'Receipt ${payment.invoiceNumber}',
    theme: pw.ThemeData.withFont(base: regular, bold: bold),
  );
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (gymName != null && gymName.isNotEmpty)
            pw.Text(gymName, style: pw.TextStyle(font: bold, fontSize: 22)),
          pw.SizedBox(height: 2),
          pw.Text(
            'Payment Receipt',
            style: const pw.TextStyle(fontSize: 13, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 16),
          pw.Divider(color: PdfColors.grey400),
          row('Receipt number', payment.invoiceNumber),
          row('Date', dateLabel),
          row('Member', payment.memberName),
          row('Payment type', payment.typeLabel),
          row('Payment method', payment.methodLabel),
          if ((payment.reference ?? '').isNotEmpty)
            row('Reference', payment.reference!),
          pw.Divider(color: PdfColors.grey400),
          pw.SizedBox(height: 8),
          pw.Text(planName, style: pw.TextStyle(font: bold, fontSize: 14)),
          if (features.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 4),
              child: pw.Text(
                features.join(' • '),
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey700,
                ),
              ),
            )
          else if ((payment.notes ?? '').isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 4),
              child: pw.Text(
                payment.notes!,
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey700,
                ),
              ),
            ),
          pw.SizedBox(height: 16),
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Amount paid', style: pw.TextStyle(font: bold)),
                pw.Text(
                  money(payment.amount),
                  style: pw.TextStyle(font: bold, fontSize: 20),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
  return doc.save();
}
