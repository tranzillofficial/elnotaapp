import 'package:flutter/material.dart';
import '../../../core/database/database_impl.dart';
import '../../../core/printing/invoice_export_service.dart';
import '../../../core/utils/money_utils.dart';
import '../../../core/utils/ui_text.dart';
import '../../accounting/models/accounting_snapshot.dart';

class InvoiceReceipt extends StatelessWidget {
  const InvoiceReceipt({super.key,required this.invoice,required this.account,required this.business,required this.items,this.paper=ReceiptPaper.mm80});
  final InvoiceRow invoice;
  final CustomerAccount account;
  final BusinessInfo business;
  final List<InvoiceItemRow> items;
  final ReceiptPaper paper;
  double get width=>switch(paper){ReceiptPaper.a4=>620,ReceiptPaper.mm80=>288,ReceiptPaper.mm58=>192};
  @override
  Widget build(BuildContext context) {
    final narrow=paper!=ReceiptPaper.a4;
    final style=TextStyle(color:Colors.black,fontSize:paper==ReceiptPaper.mm58?10:12,height:1.45,fontFamily:'ElNotaArabic');
    Widget pair(String label,String value,{bool bold=false})=>Padding(padding:const EdgeInsets.symmetric(vertical:3),child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Expanded(child:Text(label,style:bold?const TextStyle(fontWeight:FontWeight.w700):null)),const SizedBox(width:8),
      Flexible(child:Text(value,textAlign:TextAlign.end,style:bold?const TextStyle(fontWeight:FontWeight.w700):null)),
    ]));
    return Directionality(textDirection:TextDirection.rtl,child:DefaultTextStyle(style:style,child:Container(width:width,color:Colors.white,padding:EdgeInsets.all(narrow?12:24),child:Column(
      mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.stretch,children:[
        Text(business.name.isEmpty?'اسم النشاط غير محدد':business.name,textAlign:TextAlign.center,style:TextStyle(fontSize:narrow?17:24,fontWeight:FontWeight.w700)),
        if(business.phone.isNotEmpty) Text(business.phone,textAlign:TextAlign.center),
        if(business.address.isNotEmpty) Text(business.address,textAlign:TextAlign.center),
        const Divider(color:Colors.black),
        Text('فاتورة ${invoice.invoiceNumber??shortId(invoice.id)}',textAlign:TextAlign.center,style:const TextStyle(fontWeight:FontWeight.w700)),
        pair('العميل',account.customer.name),pair('التاريخ',dateText(invoice.invoiceDate)),
        if(invoice.dueDate!=null) pair('الاستحقاق',dateText(invoice.dueDate!)),
        pair('الحالة',switch(invoice.status){'posted'=>'مسجلة','draft'=>'مسودة','voided'=>'ملغاة',_=>invoice.status}),
        const Divider(color:Colors.black),
        if(invoice.isManualAmount) pair('مبلغ يدوي',MoneyUtils.formatMinor(invoice.totalMinor))
        else ...items.map((i)=>Padding(padding:const EdgeInsets.symmetric(vertical:5),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
          Text(i.description,style:const TextStyle(fontWeight:FontWeight.w600)),
          pair('${i.quantity} × ${MoneyUtils.formatMinor(i.unitPriceMinor)}',MoneyUtils.formatMinor(i.lineTotal)),
          if(i.discountMinor>0) Text('خصم الصنف: ${MoneyUtils.formatMinor(i.discountMinor)}'),
        ]))),
        const Divider(color:Colors.black),pair('الإجمالي',MoneyUtils.formatMinor(invoice.totalMinor)),
        if(invoice.discountMinor>0) pair('الخصم',MoneyUtils.formatMinor(invoice.discountMinor)),
        pair('صافي الفاتورة',MoneyUtils.formatMinor(invoice.netMinor),bold:true),
        const Divider(color:Colors.black),
        pair('رصيد حساب العميل الحالي',MoneyUtils.formatMinor(account.balance.outstandingMinor.abs()),bold:true),
        Text(account.balance.outstandingMinor<0?'رصيد مقدم لصالح العميل':'الدفعات محسوبة على إجمالي حساب العميل',textAlign:TextAlign.center),
        if(invoice.notes?.isNotEmpty==true) ...[const SizedBox(height:8),Text(invoice.notes!)],
        const SizedBox(height:10),const Text('شكرًا لتعاملكم معنا',textAlign:TextAlign.center),
      ]))));
  }
}
