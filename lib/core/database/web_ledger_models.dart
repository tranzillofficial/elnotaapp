import 'dart:convert';
import '../sync/web_ledger_document.dart';

/// Lossless JSON boundary models. Field names follow the website exactly.
/// Existing Flutter models/SQL keep their native names and financial precision.
class WebLedgerEntity {
  WebLedgerEntity(Map<String, dynamic> json)
      : _data = jsonDecode(jsonEncode(json)) as Map<String, dynamic>;
  final Map<String, dynamic> _data;
  Map<String, dynamic> toJson() => jsonDecode(jsonEncode(_data)) as Map<String, dynamic>;
}

class WebCustomer extends WebLedgerEntity {
  WebCustomer(super.json);
  String get id => _data['id'] as String;
  String get name => _data['name'] as String;
  String get phone => _data['phone'] as String;
  String get address => _data['address'] as String;
  String get notes => _data['notes'] as String;
}

class WebProduct extends WebLedgerEntity {
  WebProduct(super.json);
  String get id => _data['id'] as String;
  String get name => _data['name'] as String;
  num get price => _data['price'] as num;
  int get unitPriceMinor => WebLedgerDocument.minor(price);
  String get barcode => _data['barcode'] as String;
  String? get image => _data['image'] as String?;
  bool get archived => _data['archived'] == true;
  String? get category => _data['category'] as String?;
  int? get boxQuantity => _data['boxQuantity'] as int?;
  String? get itemNumber => _data['itemNumber'] as String?;
  bool get priceMissing => _data['priceMissing'] == true;
}

class WebPayment extends WebLedgerEntity {
  WebPayment(super.json);
  String get id => _data['id'] as String;
  String? get customerId => _data['customerId'] as String?;
  int get amountMinor => WebLedgerDocument.minor(_data['amount']);
  String get date => _data['date'] as String;
  String get note => _data['note'] as String;
}

class WebInvoice extends WebLedgerEntity {
  WebInvoice(super.json);
  String get id => _data['id'] as String;
  String get number => _data['number'] as String;
  String get customerId => _data['customerId'] as String;
  String get date => _data['date'] as String;
  String get dueDate => _data['dueDate'] as String;
  String get notes => _data['notes'] as String;
  String get method => _data['method'] as String;
  String? get entryMode => _data['entryMode'] as String?;
  bool get voided => _data['voided'] == true;
  int get totalMinor => WebLedgerDocument.total(_data);
  List<Map<String, dynamic>> get lines => (_data['lines'] as List)
      .map((r) => Map<String, dynamic>.from(r as Map)).toList();
  List<WebPayment> get payments => (_data['payments'] as List)
      .map((r) => WebPayment(Map<String, dynamic>.from(r as Map))).toList();
  WebInstallmentPlan? get installmentPlan => _data['installmentPlan'] == null
      ? null : WebInstallmentPlan(Map<String, dynamic>.from(_data['installmentPlan'] as Map));
}

class WebInstallmentPlan extends WebLedgerEntity {
  WebInstallmentPlan(super.json);
  int get months => _data['months'] as int;
  int get financedAmountMinor => WebLedgerDocument.minor(_data['financedAmount']);
  String get firstDueDate => _data['firstDueDate'] as String;
}

class WebBusinessSettings extends WebLedgerEntity {
  WebBusinessSettings(super.json);
  String get businessName => _data['businessName'] as String;
  String get phone => _data['phone'] as String;
  String get address => _data['address'] as String;
  String get currency => _data['currency'] as String;
}
