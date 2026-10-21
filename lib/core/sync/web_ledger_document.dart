import 'dart:convert';

/// The production website's v1 wire format. Unknown fields are retained.
/// SQLite remains the UI store; this adapter never migrates the live server.
class WebLedgerDocument {
  WebLedgerDocument._();

  static Map<String, dynamic> empty() => {
    'schemaVersion': 1,
    'customers': <dynamic>[], 'products': <dynamic>[],
    'invoices': <dynamic>[], 'customerPayments': <dynamic>[],
    'settings': {'businessName': 'متجري', 'phone': '', 'address': '', 'currency': 'جنيه'},
    'updatedAt': DateTime.now().toUtc().toIso8601String(),
  };

  static Map<String, dynamic> read(dynamic value) {
    if (value is! Map) throw const FormatException('نسخة النوتة غير صالحة');
    final root = Map<String, dynamic>.from(value);
    final data = Map<String, dynamic>.from(root['data'] is Map ? root['data'] as Map : root);
    if (data['schemaVersion'] != 1 || data['settings'] is! Map ||
        data['updatedAt'] is! String) {
      throw const FormatException('صيغة النسخة غير مدعومة');
    }
    for (final key in ['businessName', 'phone', 'address', 'currency']) {
      if (data['settings'][key] is! String) throw const FormatException('بيانات المتجر غير صالحة');
    }
    final ids = <String, Set<String>>{};
    for (final key in ['customers', 'products', 'invoices', 'customerPayments']) {
      if (!data.containsKey(key) && key == 'customerPayments') {
        ids[key] = <String>{};
        continue;
      }
      if (data[key] is! List) throw FormatException('قائمة $key غير صالحة');
      ids[key] = <String>{};
      for (final row in data[key] as List) {
        if (row is! Map || row['id'] is! String || (row['id'] as String).isEmpty ||
            !ids[key]!.add(row['id'] as String)) {
          throw FormatException('معرّف مكرر أو غير صالح في $key');
        }
      }
    }
    for (final row in data['customers'] as List) {
      for (final key in ['name', 'phone', 'address', 'notes']) {
        if (row[key] is! String) throw const FormatException('بيانات عميل غير صالحة');
      }
    }
    for (final row in data['products'] as List) {
      if (row['name'] is! String || row['barcode'] is! String || !_nonnegative(row['price'])) {
        throw const FormatException('بيانات منتج غير صالحة');
      }
      if (row['boxQuantity'] != null &&
          (row['boxQuantity'] is! int || row['boxQuantity'] <= 0)) {
        throw const FormatException('عدد وحدات العبوة غير صالح');
      }
    }
    final paymentIds = <String>{};
    void payment(dynamic p) {
      if (p is! Map || p['id'] is! String || !paymentIds.add(p['id'] as String) ||
          minor(p['amount']) <= 0 || p['note'] is! String) {
        throw const FormatException('دفعة غير صالحة أو مكررة');
      }
      date(p['date']);
    }
    for (final row in data['invoices'] as List) {
      if (!ids['customers']!.contains(row['customerId']) ||
          !['cash', 'credit', 'installment'].contains(row['method']) ||
          row['number'] is! String || row['notes'] is! String ||
          row['lines'] is! List || (row['lines'] as List).isEmpty || row['payments'] is! List) {
        throw const FormatException('بيانات فاتورة غير صالحة');
      }
      date(row['date']);
      if (row['dueDate'] != '') date(row['dueDate']);
      for (final line in row['lines'] as List) {
        if (line is! Map || line['name'] is! String || line['productId'] is! String ||
            !_nonnegative(line['price'])) {
          throw const FormatException('صنف فاتورة غير صالح');
        }
        lineMinor(line);
      }
      for (final p in row['payments'] as List) { payment(p); }
      final paid = (row['payments'] as List).fold<int>(0, (s, p) => s + minor(p['amount']));
      if (paid > total(row)) throw const FormatException('دفعات الفاتورة تتجاوز إجماليها');
      if (row['installmentPlan'] != null) {
        final p = row['installmentPlan'];
        if (p is! Map || row['method'] != 'installment' || p['months'] is! int ||
            p['months'] < 1 || p['months'] > 120 || minor(p['financedAmount']) <= 0 ||
            minor(p['financedAmount']) > total(row) || minor(p['financedAmount']) < p['months']) {
          throw const FormatException('خطة تقسيط غير صالحة');
        }
        date(p['firstDueDate']);
      }
    }
    for (final row in (data['customerPayments'] as List? ?? const [])) {
      if (!ids['customers']!.contains(row['customerId'])) throw const FormatException('عميل الدفعة غير موجود');
      payment(row);
    }
    return jsonDecode(jsonEncode(data)) as Map<String, dynamic>;
  }

  static bool _nonnegative(dynamic value) => value is num && value.isFinite && value >= 0;

  /// Decimal parsing at the JSON boundary only. Never truncate fractions.
  static int minor(dynamic value) {
    if (value is! num || !value.isFinite) throw const FormatException('مبلغ غير صالح');
    final scaled = value * 100;
    if (!scaled.isFinite || scaled.abs() > 9007199254740991) {
      throw const FormatException('المبلغ خارج النطاق المدعوم');
    }
    final rounded = scaled.round();
    if ((scaled - rounded).abs() > 0.000001 || rounded.abs() > 9007199254740991) {
      throw const FormatException('المبلغ يحتاج مراجعة دقة الكسور');
    }
    return rounded;
  }

  static int lineMinor(dynamic line) {
    final q = line['quantity'];
    if (q is! num || !q.isFinite || q <= 0) throw const FormatException('كمية غير صالحة');
    // Match the website's invoice rounding once after summing the lines.
    return ((line['price'] as num) * q * 100).round();
  }

  static int total(dynamic invoice) => ((invoice['lines'] as List)
      .fold<num>(0, (s, l) => s + (l['price'] as num) * (l['quantity'] as num)) * 100).round();

  static int date(dynamic value) {
    if (value is! String || DateTime.tryParse(value) == null) throw const FormatException('تاريخ غير صالح');
    return DateTime.parse(value).millisecondsSinceEpoch;
  }

  static String day(int millis) => DateTime.fromMillisecondsSinceEpoch(millis)
      .toIso8601String().substring(0, 10);

  static dynamic _canonical(dynamic value) {
    if (value is List) return value.map(_canonical).toList();
    if (value is Map) {
      final keys = value.keys.cast<String>().toList()..sort();
      return {for (final key in keys) key: _canonical(value[key])};
    }
    return value;
  }

  /// Store a canonical baseline in SQLite, no additional crypto dependency.
  static String fingerprint(Map<String, dynamic> data) => jsonEncode(_canonical({
    ...data, 'updatedAt': null, 'syncImages': null,
  }));

  static bool pristine(Map<String, dynamic> d) =>
      ['customers','products','invoices','customerPayments','categories']
          .every((k) => d[k] == null || (d[k] as List).isEmpty) &&
      d['settings']['phone'] == '' && d['settings']['address'] == '';
}

enum SnapshotDirection { push, pull, same, conflict }

SnapshotDirection snapshotDirection({required String local, required String? remote,
    required int revision, String? baseline, int? baselineRevision,
    required bool localPristine, required bool remotePristine}) {
  if (local == remote) return SnapshotDirection.same;
  if (remote == null) return baseline != null ? SnapshotDirection.conflict : SnapshotDirection.push;
  if (baseline == null) {
    if (localPristine) return SnapshotDirection.pull;
    if (remotePristine) return SnapshotDirection.push;
    return SnapshotDirection.conflict;
  }
  final localChanged = local != baseline;
  final remoteChanged = remote != baseline || revision != baselineRevision;
  if (localChanged && remoteChanged) return SnapshotDirection.conflict;
  return localChanged ? SnapshotDirection.push : SnapshotDirection.pull;
}
