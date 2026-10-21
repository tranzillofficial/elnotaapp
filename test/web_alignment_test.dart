import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:elnota/core/database/app_database.dart';
import 'package:elnota/core/database/database_impl.dart';
import 'package:elnota/core/database/web_compatibility_repository.dart';
import 'package:elnota/core/database/web_import_preview.dart';
import 'package:elnota/core/database/web_ledger_models.dart';
import 'package:elnota/core/database/web_models.dart';
import 'package:elnota/core/sync/web_ledger_document.dart';

Map<String, dynamic> fixture() => {
  ...WebLedgerDocument.empty(),
  'customers': [{'id':'c1','name':'عميل تجريبي','phone':'010','address':'القاهرة','notes':''}],
  'products': [{'id':'p1','name':'منتج','price':250,'barcode':'622','image':'data:image/png;base64,AA==',
    'archived':false,'category':'قسم','boxQuantity':12,'itemNumber':'A1','priceMissing':false}],
  'categories':['قسم'], 'catalogImports':['catalog1'], 'fourFieldCatalog':true,
  'futureField': {'preserve':true},
  'invoices': [
    {'id':'i1','number':'INV-1','customerId':'c1','date':'2026-10-20','dueDate':'2026-11-20',
      'notes':'','method':'installment','entryMode':'products',
      'lines':[{'productId':'p1','name':'منتج','price':250,'quantity':2}],
      'payments':[{'id':'ip1','amount':100,'date':'2026-10-20','note':'مقدم'}],
      'installmentPlan': {'months':4,'financedAmount':400,'firstDueDate':'2026-11-20'}},
    {'id':'i2','number':'INV-2','customerId':'c1','date':'2026-10-20','dueDate':'',
      'notes':'يدوي','method':'credit','entryMode':'amount',
      'lines':[{'productId':'manual-1','name':'مبلغ يدوي','price':300,'quantity':1}], 'payments':[]},
    {'id':'void','number':'INV-3','customerId':'c1','date':'2026-10-20','dueDate':'',
      'notes':'','method':'cash','voided':true,
      'lines':[{'productId':'p1','name':'منتج','price':100,'quantity':1}],
      'payments':[{'id':'void-p','amount':100,'date':'2026-10-20','note':''}]},
  ],
  'customerPayments':[{'id':'cp1','customerId':'c1','amount':150,'date':'2026-10-21','note':'دفعة حساب'}],
};

class _VersionOneDatabase extends AppDatabase {
  _VersionOneDatabase(super.executor);
  @override
  int get schemaVersion => 1;
  @override
  MigrationStrategy get migration => MigrationStrategy(onCreate: (_) => AppDao(this).createTables());
}

void main() {
  test('website document round-trips every field and keeps receipt provenance', () {
    final source = fixture();
    final preview = WebImportPreview.inspect({'application':'ElNota','data':source});
    expect(preview.needsReview, isFalse);
    expect(preview.balancesMinor, {'c1':55000}); // 500 + 300 - 100 - 150
    expect(preview.invoicePayments, 2); // Includes void receipt in original only.
    expect(preview.customerPayments, 1);
    expect(jsonDecode(preview.originalJson), source);
    final invoice = WebInvoice(Map<String,dynamic>.from(source['invoices'][0] as Map));
    expect(invoice.installmentPlan!.months, 4);
    expect(invoice.installmentPlan!.financedAmountMinor, 40000);
    expect(invoice.payments.single.amountMinor, 10000);
    final product = WebProduct(Map<String,dynamic>.from(source['products'][0] as Map));
    expect(product.boxQuantity, 12);
    expect(product.toJson(), source['products'][0]);
  });

  test('fractional quantity/price are preserved and require review, never truncated', () {
    final source = fixture();
    source['products'][0]['price'] = 0.001;
    source['invoices'][1]['lines'][0]['quantity'] = 1.5;
    source['invoices'][1].remove('entryMode');
    final preview = WebImportPreview.inspect(source);
    expect(preview.blockers, contains('product_price_precision:p1'));
    expect(preview.blockers, contains('fractional_quantity:i2'));
    expect(preview.document['products'][0]['price'], 0.001);
    expect(preview.document['invoices'][1]['lines'][0]['quantity'], 1.5);
    expect(() => WebLedgerDocument.minor(0.001), throwsFormatException);
  });

  test('duplicate IDs, orphan references and duplicate receipt IDs are rejected', () {
    final duplicate = fixture();
    duplicate['customers'].add(Map<String, String>.from(duplicate['customers'][0] as Map));
    expect(() => WebImportPreview.inspect(duplicate), throwsFormatException);
    final orphan = fixture();
    orphan['customerPayments'][0]['customerId'] = 'other';
    expect(() => WebImportPreview.inspect(orphan), throwsFormatException);
    final receipts = fixture();
    receipts['customerPayments'][0]['id'] = 'ip1';
    expect(() => WebImportPreview.inspect(receipts), throwsFormatException);
  });

  test('account and request DTOs retain server-owned fields without granting access', () {
    final json = {'user_id':'user','email':'test@example.com','business_name':'Store',
      'activated_at':'2026-10-01T00:00:00Z','cloud_until':'2026-12-01T00:00:00Z',
      'printing_enabled':true,'suspended_at':'2026-10-20T00:00:00Z',
      'suspended_activation_at':'2026-10-01T00:00:00Z','future':42};
    final account = WebAccount(json);
    expect(account.cloudActiveAt(DateTime.utc(2026,10,21)), isFalse);
    expect(account.toJson(), json);
    final request = WebActivationRequest.pending(userId:'user',plan:'basic',phone:'01012345678',reference:'transfer');
    expect(request.containsKey('amount'), isFalse);
    expect(request.containsKey('submitted_email'), isFalse);
    expect(request['status'], 'pending');
  });

  test('real Drift v1 file upgrades/reopens without changing money or pending ops', () async {
    final dir = await Directory.systemTemp.createTemp('elnota-upgrade-');
    final file = File('${dir.path}/test.sqlite');
    try {
      final old = _VersionOneDatabase(NativeDatabase(file));
      await old.customStatement("INSERT INTO customers VALUES ('c','default','Test','010','note',7,100,101,NULL)");
      await old.customStatement("INSERT INTO invoices VALUES ('i','default','c','INV-1','posted',80000,5000,'note',1,100,NULL,3,100,101,NULL)");
      await old.customStatement("INSERT INTO sync_outbox VALUES ('op','default','invoice','i','create','{}',0,100,2,NULL,'pending','retry')");
      await old.close();
      final upgraded = AppDatabase(NativeDatabase(file));
      final invoice = (await upgraded.customSelect('SELECT * FROM invoices').get()).single.data;
      expect(invoice['total_minor'], 80000);
      expect(invoice['discount_minor'], 5000);
      expect(invoice['entry_mode'], 'amount');
      expect((await upgraded.customSelect('SELECT status,attempts FROM sync_outbox').get()).single.data,
        {'status':'pending','attempts':2});
      final repo = WebCompatibilityRepository(upgraded);
      final id = await repo.stage(sourceUserId:'source-user',sourceRevision:3,input:fixture());
      expect((await repo.readStaged(id:id,sourceUserId:'source-user'))!.balancesMinor['c1'],55000);
      expect(await repo.readStaged(id:id,sourceUserId:'other-user'),isNull);
      expect((await upgraded.customSelect('SELECT COUNT(*) AS n FROM customers').get()).single.read<int>('n'),1);
      expect((await upgraded.customSelect('SELECT COUNT(*) AS n FROM ledger_entries').get()).single.read<int>('n'),0);
      await upgraded.close();
      final reopened = AppDatabase(NativeDatabase(file));
      expect((await WebCompatibilityRepository(reopened).readStaged(id:id,sourceUserId:'source-user'))!.customers,1);
      await reopened.close();
    } finally {
      await dir.delete(recursive:true);
    }
  });
}
