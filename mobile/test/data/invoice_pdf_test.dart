import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:gym_manager/data/invoice_pdf.dart';

void main() {
  Future<Uint8List> build() => buildInvoicePdf(
        gymName: 'Iron Gym',
        address: '123 Main St',
        phone: '9876543210',
        email: 'gym@example.com',
        memberName: 'Alice Smith',
        amountText: '₹1,500',
        methodText: 'Bank Transfer',
        invoiceNumber: 'INV-2601-0001',
        paidAtText: '13 Jan 2026',
        planName: 'Monthly',
        notes: 'Paid in full',
        status: 'paid',
      );

  test('produces a non-empty PDF document', () async {
    final Uint8List bytes = await build();
    expect(bytes, isNotEmpty);
    expect(ascii.decode(bytes.take(5).toList()), '%PDF-');
  });

  test('renders without a plan or notes', () async {
    final Uint8List bytes = await buildInvoicePdf(
      gymName: 'Gym',
      memberName: 'Bob',
      amountText: '₹500',
      methodText: 'Cash',
      invoiceNumber: 'INV-2601-0002',
      paidAtText: '13 Jan 2026',
      status: 'voided',
    );
    expect(ascii.decode(bytes.take(5).toList()), '%PDF-');
  });
}
