import 'dart:convert';
import '../sync/web_ledger_document.dart';

/// Pure preflight. It neither merges records nor replaces a Flutter workspace.
/// Original keys, dates, fractional quantities and future fields stay intact.
class WebImportPreview {
  WebImportPreview._(this.document, this.blockers);
  final Map<String, dynamic> document;
  final List<String> blockers;

  static WebImportPreview inspect(dynamic input) {
    final document = WebLedgerDocument.read(input);
    final blockers = <String>[];
    for (final p in document['products'] as List) {
      try { WebLedgerDocument.minor(p['price']); }
      on FormatException { blockers.add('product_price_precision:${p['id']}'); }
    }
    for (final invoice in document['invoices'] as List) {
      var lineSum = 0;
      for (final line in invoice['lines'] as List) {
        final quantity = line['quantity'] as num;
        if (quantity != quantity.round()) {
          blockers.add('fractional_quantity:${invoice['id']}');
        }
        try { WebLedgerDocument.minor(line['price']); }
        on FormatException { blockers.add('line_price_precision:${invoice['id']}'); }
        lineSum += WebLedgerDocument.lineMinor(line);
      }
      if (lineSum != WebLedgerDocument.total(invoice)) {
        blockers.add('invoice_rounding:${invoice['id']}');
      }
      // A source document with a Flutter extension cannot be interpreted by
      // a v1-only importer until its richer financial semantics are reviewed.
      if ((invoice as Map).keys.any((k) => k.toString().startsWith('_flutter'))) {
        blockers.add('flutter_extension:${invoice['id']}');
      }
    }
    return WebImportPreview._(document, List.unmodifiable(blockers.toSet()));
  }

  int get customers => (document['customers'] as List).length;
  int get products => (document['products'] as List).length;
  int get invoices => (document['invoices'] as List).length;
  int get invoicePayments => (document['invoices'] as List)
      .fold<int>(0, (count, i) => count + (i['payments'] as List).length);
  int get customerPayments => (document['customerPayments'] as List? ?? const []).length;
  bool get needsReview => blockers.isNotEmpty;

  /// Totals count historical invoice receipts and account receipts once each.
  /// Voided invoices and their embedded receipts do not affect balances.
  Map<String, int> get balancesMinor {
    final result = <String, int>{
      for (final c in document['customers'] as List) c['id'] as String: 0,
    };
    for (final i in document['invoices'] as List) {
      if (i['voided'] == true) continue;
      final id = i['customerId'] as String;
      result[id] = result[id]! + WebLedgerDocument.total(i);
      for (final p in i['payments'] as List) {
        result[id] = result[id]! - WebLedgerDocument.minor(p['amount']);
      }
    }
    for (final p in (document['customerPayments'] as List? ?? const [])) {
      final id = p['customerId'] as String;
      result[id] = result[id]! - WebLedgerDocument.minor(p['amount']);
    }
    return result;
  }

  Map<String, dynamic> get report => {
    'customers': customers, 'products': products, 'invoices': invoices,
    'invoicePayments': invoicePayments, 'customerPayments': customerPayments,
    'balancesMinor': balancesMinor, 'blockers': blockers,
    'applied': false,
  };

  String get originalJson => jsonEncode(document);
}
