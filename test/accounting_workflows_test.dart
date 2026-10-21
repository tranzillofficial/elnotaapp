import 'dart:typed_data';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:elnota/core/database/app_database.dart';
import 'package:elnota/core/database/database_impl.dart';
import 'package:elnota/core/printing/esc_pos_raster.dart';
import 'package:elnota/core/utils/money_utils.dart';
import 'package:elnota/features/accounting/repositories/accounting_repository.dart';

void main() {
  late AppDatabase db;
  late AppDao dao;
  setUp(() {db=AppDatabase(NativeDatabase.memory());dao=AppDao(db);});
  tearDown(() async {await dao.close();await db.close();});

  test('two invoices, customer receipt and discount agree across all screen projections',() async {
    final customer=await dao.createCustomer(name:'Test customer',address:'Cairo');
    await dao.createAndPostInvoice(customerId:customer,totalMinor:50000,isManualAmount:true,discountMinor:5000);
    await dao.createAndPostInvoice(customerId:customer,totalMinor:30000,isManualAmount:false,
      items:[{'description':'Product','quantity':3,'unit_price_minor':10000}]);
    await dao.addPayment(customerId:customer,amountMinor:25000,idempotencyKey:'payment-1');
    await dao.addPayment(customerId:customer,amountMinor:25000,idempotencyKey:'payment-1');
    final snapshot=await AccountingRepository(dao:dao).read();
    expect(snapshot.outstandingMinor,50000);
    expect(snapshot.invoices.length,2);
    expect(snapshot.payments.length,1);
    expect(snapshot.receivedMinor,25000);
    expect(snapshot.customer(customer)!.customer.address,'Cairo');
    expect((await dao.balance(customer)).outstandingMinor,50000);
    await expectLater(dao.softDeleteCustomer(customer),throwsStateError);
  });

  test('failed invoice cannot leave draft, items, ledger or outbox behind',() async {
    final customer=await dao.createCustomer(name:'Test');
    final before=await dao.readWorkspaceData();
    await db.customStatement("CREATE TRIGGER fail_invoice BEFORE INSERT ON ledger_entries BEGIN SELECT RAISE(ABORT,'forced_failure'); END");
    await expectLater(dao.createAndPostInvoice(customerId:customer,totalMinor:50000,isManualAmount:false,
      items:[{'description':'Product','quantity':1,'unit_price_minor':50000}]),throwsA(anything));
    final after=await dao.readWorkspaceData();
    for(final table in ['invoices','invoice_items','ledger_entries']) {expect(after[table],before[table]);}
    final outbox=await dao.getPendingOutbox();
    expect(outbox.length,1); // Only the original customer create operation.
  });

  test('all local reads and writes enforce the selected workspace',() async {
    final other=AppDao(db,workspaceId:'other');
    try {
      final id=await dao.createCustomer(name:'Account A');
      expect((await other.readWorkspaceData())['customers'],isEmpty);
      await expectLater(other.addPayment(customerId:id,amountMinor:100,idempotencyKey:'bad'),throwsStateError);
      await expectLater(other.updateCustomer(id:id,name:'Wrong'),throwsStateError);
      expect((await dao.watchCustomer(id).first)!.name,'Account A');
    } finally {await other.close();}
  });

  test('queries emit again after customer edit, invoice posting and payment without reopening a screen',() async {
    final values=<int>[];
    final subscription=AccountingRepository(dao:dao).watch().listen((s)=>values.add(s.outstandingMinor));
    final id=await dao.createCustomer(name:'Original');
    await dao.updateCustomer(id:id,name:'Updated',address:'Giza');
    await dao.createAndPostInvoice(customerId:id,totalMinor:10000,isManualAmount:true);
    await dao.addPayment(customerId:id,amountMinor:3000,idempotencyKey:'live-1');
    await Future<void>.delayed(const Duration(milliseconds:30));
    expect(values,isNotEmpty);
    expect(values.last,7000);
    expect((await dao.watchCustomer(id).first)!.address,'Giza');
    await subscription.cancel();
  });

  test('signed adjustments and advance credit use the same balance in details and overview',() async {
    final id=await dao.createCustomer(name:'Credit');
    await dao.createAndPostInvoice(customerId:id,totalMinor:10000,isManualAmount:true);
    await dao.addPayment(customerId:id,amountMinor:15000,idempotencyKey:'advance');
    await db.customStatement("INSERT INTO ledger_entries VALUES ('adj','default',?,'adj','adjustment',2000,NULL,1,1)",[id]);
    expect((await dao.balance(id)).outstandingMinor,-3000);
    final snapshot=await AccountingRepository(dao:dao).read();
    expect(snapshot.creditMinor,3000);
    expect(snapshot.outstandingMinor,0);
  });

  test('money input accepts Arabic digits and rejects truncation and malformed decimals',() {
    expect(MoneyUtils.parseToMinor('١٢٣٫٤٥'),12345);
    expect(MoneyUtils.parseToMinor('-0.05'),-5);
    expect(MoneyUtils.parseToMinor('1,250.99'),125099);
    for(final value in ['1.005','1.xx','1.','1,23','NaN']) {expect(MoneyUtils.parseToMinor(value),isNull,reason:value);}
  });

  test('ESC/POS raster preserves bit order, band boundaries and optional cut',() {
    final rgba=Uint8List(9*129*4)..fillRange(0,9*129*4,255);
    // First and ninth pixel black on the first row.
    for(final pixel in [0,8]) {for(var c=0;c<3;c++) {rgba[pixel*4+c]=0;}}
    final bytes=EscPosRaster.encodeRgba(rgba:rgba,width:9,height:129);
    expect(bytes.take(10),[0x1b,0x40,0x1d,0x76,0x30,0,2,0,128,0]);
    expect(bytes[10],128);expect(bytes[11],128);
    expect(bytes.sublist(266,274),[0x1d,0x76,0x30,0,2,0,1,0]);
    expect(bytes.sublist(bytes.length-3),[0x1b,0x64,4]);
    final transparent=Uint8List(4); // Transparent black must print white.
    final clear=EscPosRaster.encodeRgba(rgba:transparent,width:1,height:1,cut:true);
    expect(clear[10],0);
    expect(clear.sublist(clear.length-3),[0x1d,0x56,0]);
    expect(()=>EscPosRaster.encodeRgba(rgba:Uint8List(1),width:1,height:1),throwsArgumentError);
  });
}
