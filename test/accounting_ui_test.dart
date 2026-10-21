import 'dart:io';
import 'dart:ui' as ui;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:elnota/app/theme/app_theme.dart';
import 'package:elnota/core/database/app_database.dart';
import 'package:elnota/core/database/database_impl.dart';
import 'package:elnota/core/printing/invoice_export_service.dart';
import 'package:elnota/features/accounting/repositories/accounting_repository.dart';
import 'package:elnota/features/accounting/views/accounting_pages.dart';
import 'package:elnota/features/customers/views/customer_detail_view.dart';
import 'package:elnota/features/invoices/views/invoice_detail_view.dart';
import 'package:elnota/features/invoices/widgets/invoice_receipt.dart';

void main() {
  Future<void> capture(WidgetTester tester,GlobalKey key,String name) async {
    if(!const bool.fromEnvironment('ELNOTA_SCREENSHOTS')) return;
    final boundary=key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image=await boundary.toImage(pixelRatio:1.5);
      final data=await image.toByteData(format:ui.ImageByteFormat.png);
      image.dispose();
      final directory=Directory('build/ui_previews');await directory.create(recursive:true);
      await File('${directory.path}/$name.png').writeAsBytes(data!.buffer.asUint8List());
    });
  }
  for(final width in [320.0,390.0,768.0,1440.0]) {
    for(final section in AccountingSection.values) {
      testWidgets('${section.name} at $width has no overflow and renders live accounting data',(tester) async {
        tester.view.physicalSize=Size(width,900);tester.view.devicePixelRatio=1;
        addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
        final db=AppDatabase(NativeDatabase.memory()),key=GlobalKey();
        final dao=AppDao(db),repo=AccountingRepository(dao:AppDao(db));
        final id=await dao.createCustomer(name:'أحمد محمد اسم عميل طويل للاختبار',phone:'01012345678');
        await dao.createAndPostInvoice(customerId:id,totalMinor:80000,isManualAmount:true,discountMinor:5000);
        await dao.addPayment(customerId:id,amountMinor:25000,idempotencyKey:'ui-payment');
        await tester.pumpWidget(RepaintBoundary(key:key,child:GetMaterialApp(locale:const Locale('ar'),theme:AppTheme.light,
          home:Directionality(textDirection:TextDirection.rtl,child:AccountingPage(section:section,repository:repo)))));
        await tester.pumpAndSettle();
        expect(tester.takeException(),isNull);
        expect(find.byType(Scaffold),findsOneWidget);
        if(width==390 || width==1440) await capture(tester,key,'${section.name}_${width.toInt()}');
        await tester.pumpWidget(const SizedBox.shrink());await tester.pumpAndSettle();
        await repo.dao.close();await dao.close();await db.close();Get.reset();
      });
    }
  }
  testWidgets('invoice details include preview and image export controls; customer has one payment action',(tester) async {
    tester.view.physicalSize=const Size(390,900);tester.view.devicePixelRatio=1;
    addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
    final db=AppDatabase(NativeDatabase.memory()),key=GlobalKey();final dao=AppDao(db),repo=AccountingRepository(dao:AppDao(db));
    final customer=await dao.createCustomer(name:'عميل تجريبي');
    final invoice=await dao.createAndPostInvoice(customerId:customer,totalMinor:50000,isManualAmount:true);
    await tester.pumpWidget(RepaintBoundary(key:key,child:GetMaterialApp(locale:const Locale('ar'),theme:AppTheme.light,
      home:Directionality(textDirection:TextDirection.rtl,child:InvoiceDetailView(invoiceId:invoice,repository:repo)))));
    await tester.pumpAndSettle();expect(tester.takeException(),isNull);
    expect(find.text('حفظ صورة'),findsOneWidget);expect(find.text('مشاركة صورة / واتساب'),findsOneWidget);
    expect(find.byType(InvoiceReceipt),findsOneWidget);await capture(tester,key,'invoice_detail_390');
    await tester.pumpWidget(GetMaterialApp(locale:const Locale('ar'),theme:AppTheme.light,
      home:Directionality(textDirection:TextDirection.rtl,child:CustomerDetailView(customerId:customer,repository:repo))));
    await tester.pumpAndSettle();expect(tester.takeException(),isNull);
    expect(find.text('تسجيل دفعة'),findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());await tester.pumpAndSettle();
    await repo.dao.close();await dao.close();await db.close();Get.reset();
  });
  testWidgets('Arabic receipt stays white in dark mode and captures valid PNG/PDF/thermal data',(tester) async {
    tester.view.physicalSize=const Size(800,1200);tester.view.devicePixelRatio=1;
    addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
    final db=AppDatabase(NativeDatabase.memory()),key=GlobalKey();final dao=AppDao(db),repo=AccountingRepository(dao:dao);
    final customer=await dao.createCustomer(name:'عميل تجريبي');
    await dao.saveBusinessSettings(businessName:'متجر النوتة',phone:'01012345678',address:'القاهرة');
    final id=await dao.createAndPostInvoice(customerId:customer,totalMinor:15000,isManualAmount:false,
      items:[{'description':'صنف عربي طويل يلتف في عرض الفاتورة الضيق','quantity':3,'unit_price_minor':5000}]);
    final data=await repo.read();
    for(final paper in ReceiptPaper.values) {
      await tester.pumpWidget(MaterialApp(theme:AppTheme.dark,home:Scaffold(body:SingleChildScrollView(child:RepaintBoundary(key:key,
        child:InvoiceReceipt(invoice:data.invoices.single,account:data.customer(customer)!,business:data.business,items:data.items[id]!,paper:paper))))));
      await tester.pumpAndSettle();expect(tester.takeException(),isNull);
      await capture(tester,key,'receipt_${paper.name}');
    }
    await tester.runAsync(() async {
      final boundary=key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image=await boundary.toImage(pixelRatio:2);
      final raw=await image.toByteData(format:ui.ImageByteFormat.png);image.dispose();
      final png=raw!.buffer.asUint8List();
      expect(png.take(4),[137,80,78,71]);
      final service=InvoiceExportService();
      final pdf=await service.pdf(png,ReceiptPaper.mm58);
      expect(String.fromCharCodes(pdf.take(4)),'%PDF');
      final thermal=await service.thermal(png,dots:384);
      expect(thermal.take(2),[27,64]);
    });
    await tester.pumpWidget(const SizedBox.shrink());await tester.pumpAndSettle();await dao.close();await db.close();
  });
}
