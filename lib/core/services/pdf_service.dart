import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../utils/money_utils.dart';
import '../../features/customers/models/customer_model.dart';
import '../../features/invoices/models/invoice_model.dart';
import '../../features/payments/models/payment_model.dart';

class PdfService {
  PdfService._();

  static String _shortId(String id) => id.length > 8 ? id.substring(0, 8) : id;

  /// Generates a PDF invoice.
  static Future<Uint8List> generateInvoicePdf({
    required InvoiceModel invoice,
    String? customerName,
    List<InvoiceItemModel> items = const [],
  }) async {
    final pdf = pw.Document();

    final dateStr =
        '${invoice.invoiceDate.year}-${invoice.invoiceDate.month.toString().padLeft(2, '0')}-${invoice.invoiceDate.day.toString().padLeft(2, '0')}';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'ElNota Accounting',
                          style: pw.TextStyle(
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.teal800,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Invoice #${_shortId(invoice.id).toUpperCase()}',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('Date: $dateStr'),
                        pw.Text('Status: ${invoice.status.toUpperCase()}'),
                      ],
                    ),
                  ],
                ),
                pw.Divider(thickness: 1.5, color: PdfColors.teal),
                pw.SizedBox(height: 12),

                // Customer Info
                if (customerName != null) ...[
                  pw.Text('Bill To: $customerName',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 16),
                ],

                // Line items or Manual amount
                if (!invoice.isManualAmount && items.isNotEmpty) ...[
                  pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey300),
                    children: [
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text('Description',
                                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text('Qty',
                                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text('Unit Price',
                                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text('Total',
                                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          ),
                        ],
                      ),
                      ...items.map((i) => pw.TableRow(
                            children: [
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(6),
                                child: pw.Text(i.description),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(6),
                                child: pw.Text('${i.quantity}'),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(6),
                                child: pw.Text(MoneyUtils.formatMinorNoSymbol(i.unitPriceMinor)),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(6),
                                child: pw.Text(MoneyUtils.formatMinorNoSymbol(i.lineTotal)),
                              ),
                            ],
                          )),
                    ],
                  ),
                  pw.SizedBox(height: 16),
                ],

                // Totals
                pw.Container(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Subtotal: ${MoneyUtils.formatMinor(invoice.totalMinor, symbol: 'EGP')}'),
                      if (invoice.discountMinor > 0) ...[
                        pw.SizedBox(height: 4),
                        pw.Text('Discount: - ${MoneyUtils.formatMinor(invoice.discountMinor, symbol: 'EGP')}',
                            style: const pw.TextStyle(color: PdfColors.green700)),
                      ],
                      pw.Divider(thickness: 1, color: PdfColors.grey400),
                      pw.Text(
                        'Total Net: ${MoneyUtils.formatMinor(invoice.netMinor, symbol: 'EGP')}',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.teal900,
                        ),
                      ),
                    ],
                  ),
                ),

                if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
                  pw.SizedBox(height: 24),
                  pw.Text('Notes: ${invoice.notes}', style: const pw.TextStyle(fontSize: 10)),
                ],
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Generates a customer account statement PDF.
  static Future<Uint8List> generateCustomerStatementPdf({
    required CustomerModel customer,
    required CustomerBalanceSummary balance,
    required List<InvoiceModel> invoices,
    required List<PaymentModel> payments,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Account Statement',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.teal800,
                      ),
                    ),
                    pw.Text(
                      'Date: ${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}',
                    ),
                  ],
                ),
                pw.Divider(thickness: 1.5, color: PdfColors.teal),
                pw.SizedBox(height: 8),

                // Customer Details
                pw.Text('Customer: ${customer.name}',
                    style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                if (customer.phone != null) pw.Text('Phone: ${customer.phone}'),
                pw.SizedBox(height: 12),

                // Balance summary box
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.TableBorder.all(color: PdfColors.grey400),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                    color: PdfColors.grey100,
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                    children: [
                      pw.Column(children: [
                        pw.Text('Total Invoiced', style: const pw.TextStyle(fontSize: 10)),
                        pw.Text(
                          MoneyUtils.formatMinor(balance.totalInvoicedMinor, symbol: 'EGP'),
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ]),
                      pw.Column(children: [
                        pw.Text('Total Payments', style: const pw.TextStyle(fontSize: 10)),
                        pw.Text(
                          MoneyUtils.formatMinor(balance.totalPaymentsMinor, symbol: 'EGP'),
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ]),
                      pw.Column(children: [
                        pw.Text('Current Outstanding', style: const pw.TextStyle(fontSize: 10)),
                        pw.Text(
                          MoneyUtils.formatMinor(balance.outstandingMinor.abs(), symbol: 'EGP'),
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            color: balance.hasCredit ? PdfColors.green : PdfColors.red800,
                          ),
                        ),
                      ]),
                    ],
                  ),
                ),
                pw.SizedBox(height: 16),

                // Recent Transactions
                pw.Text('Invoices Summary',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                ...invoices.take(10).map((inv) => pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Invoice #${_shortId(inv.id)} (${inv.invoiceDate.year}-${inv.invoiceDate.month.toString().padLeft(2, '0')}-${inv.invoiceDate.day.toString().padLeft(2, '0')})',
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                        pw.Text(
                          MoneyUtils.formatMinor(inv.netMinor, symbol: 'EGP'),
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ],
                    )),
                pw.SizedBox(height: 12),

                pw.Text('Payments Summary',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                ...payments.take(10).map((pmt) => pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Payment Receipt (${pmt.paymentDate.year}-${pmt.paymentDate.month.toString().padLeft(2, '0')}-${pmt.paymentDate.day.toString().padLeft(2, '0')})',
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                        pw.Text(
                          '- ${MoneyUtils.formatMinor(pmt.amountMinor, symbol: 'EGP')}',
                          style: pw.TextStyle(fontSize: 9, color: PdfColors.green700),
                        ),
                      ],
                    )),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Print document directly using system printer dialog.
  static Future<void> printDocument(Uint8List bytes, {String name = 'Document'}) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => bytes,
      name: name,
    );
  }

  /// Share document via system share sheet.
  static Future<void> shareDocument(Uint8List bytes, {required String filename}) async {
    await Printing.sharePdf(bytes: bytes, filename: filename);
  }
}
