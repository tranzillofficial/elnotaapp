import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/printing/bluetooth_printer_service.dart';
import '../../../core/printing/invoice_export_service.dart';
import '../../../core/utils/money_utils.dart';
import '../../../core/utils/ui_text.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../accounting/models/accounting_snapshot.dart';
import '../../accounting/repositories/accounting_repository.dart';
import '../widgets/invoice_receipt.dart';

class InvoiceDetailView extends StatefulWidget {
  const InvoiceDetailView({super.key,this.invoiceId,this.repository});
  final String? invoiceId;
  final AccountingRepository? repository;
  @override
  State<InvoiceDetailView> createState()=>_InvoiceDetailViewState();
}
class _InvoiceDetailViewState extends State<InvoiceDetailView> {
  late final repo=widget.repository??AccountingRepository();
  late final stream=repo.watch();
  late final id=widget.invoiceId??((Get.arguments as Map<String,dynamic>?)?['invoice_id'] as String?)??'';
  final receiptKey=GlobalKey();
  final export=InvoiceExportService();
  final bluetooth=BluetoothPrinterService();
  ReceiptPaper paper=ReceiptPaper.mm80;
  bool busy=false;
  String? error;
  String get filename=>'Invoice_${shortId(id)}.png';
  Future<void> _run(Future<void> Function() action) async {
    if(busy) return;
    setState(() {busy=true;error=null;});
    try {await action();} catch(e) {if(mounted) setState(()=>error=e.toString());}
    finally {if(mounted) setState(()=>busy=false);}
  }
  Rect get shareOrigin {
    final box=context.findRenderObject();
    if(box is RenderBox && box.hasSize) return box.localToGlobal(Offset.zero)&box.size;
    return const Rect.fromLTWH(0,0,1,1);
  }
  Future<void> _bluetooth() async {
    if(paper==ReceiptPaper.a4) {setState(()=>paper=ReceiptPaper.mm80);}
    final printers=await bluetooth.paired();
    if(!mounted) return;
    if(printers.isEmpty) throw StateError(ui('اربط الطابعة من إعدادات بلوتوث الهاتف ثم حاول مجددًا.','Pair the printer in phone Bluetooth settings, then retry.'));
    var selected=printers.first.address;
    var cut=false;
    final accepted=await showDialog<bool>(context:context,builder:(context)=>StatefulBuilder(builder:(context,update)=>AlertDialog(
      title:Text(ui('طابعة بلوتوث','Bluetooth printer')),
      content:SizedBox(width:340,child:Column(mainAxisSize:MainAxisSize.min,children:[
        Text(ui('لطابعات ESC/POS Bluetooth Classic. تأكد من اختيار عرض الورق الصحيح.','For ESC/POS Bluetooth Classic printers. Select the matching paper width.')),
        const SizedBox(height:12),DropdownButtonFormField<String>(initialValue:selected,isExpanded:true,items:printers.map((p)=>DropdownMenuItem(value:p.address,child:Text('${p.name}\n${p.address}',maxLines:2))).toList(),onChanged:(v)=>update(()=>selected=v??selected)),
        CheckboxListTile(dense:true,contentPadding:EdgeInsets.zero,value:cut,onChanged:(v)=>update(()=>cut=v??false),title:Text(ui('قص الورق إذا كانت الطابعة تدعمه','Cut paper if supported'))),
      ])),actions:[TextButton(onPressed:()=>Navigator.pop(context,false),child:Text(ui('إلغاء','Cancel'))),
        FilledButton(onPressed:()=>Navigator.pop(context,true),child:Text(ui('طباعة','Print')))],
    )));
    if(accepted!=true) return;
    final png=await export.capture(receiptKey);
    final bytes=await export.thermal(png,dots:paper==ReceiptPaper.mm58?384:576,cut:cut);
    await bluetooth.print(address:selected,bytes:bytes);
    if(mounted) showSuccessSnack(ui('تم إرسال الفاتورة للطابعة','Invoice sent to the printer'));
  }
  @override
  Widget build(BuildContext context)=>StreamBuilder<AccountingSnapshot>(stream:stream,builder:(context,snapshot) {
    final data=snapshot.data;
    final invoices=data?.invoices.where((i)=>i.id==id).toList();
    final invoice=invoices?.isNotEmpty==true?invoices!.first:null;
    final account=invoice==null?null:data?.customer(invoice.customerId);
    return Scaffold(appBar:AppBar(title:Text(ui('تفاصيل الفاتورة','Invoice details'))),
      body:snapshot.hasError?AppErrorWidget(message:ui('تعذر تحميل الفاتورة','Unable to load invoice'),onRetry:repo.refresh):data==null?const AppLoadingWidget():
        invoice==null||account==null?AppErrorWidget(message:ui('الفاتورة أو العميل غير موجود','Invoice or customer not found')):
        ListView(padding:const EdgeInsets.all(16),children:[
          Wrap(spacing:8,runSpacing:8,crossAxisAlignment:WrapCrossAlignment.center,children:[
            Text(invoice.invoiceNumber??shortId(invoice.id),style:Theme.of(context).textTheme.titleMedium),
            Chip(label:Text(invoiceStatus(invoice.status)),visualDensity:VisualDensity.compact),
            Text('${ui('صافي الفاتورة','Invoice net')}: ${MoneyUtils.formatMinor(invoice.netMinor)}'),
          ]),
          const SizedBox(height:8),Wrap(spacing:8,runSpacing:8,children:[
            SizedBox(width:155,child:DropdownButtonFormField<ReceiptPaper>(initialValue:paper,decoration:InputDecoration(labelText:ui('مقاس الورق','Paper size'),isDense:true),
              items:const [DropdownMenuItem(value:ReceiptPaper.a4,child:Text('A4')),DropdownMenuItem(value:ReceiptPaper.mm80,child:Text('80 mm')),DropdownMenuItem(value:ReceiptPaper.mm58,child:Text('58 mm'))],
              onChanged:busy?null:(v)=>setState(()=>paper=v??paper))),
            FilledButton.icon(onPressed:busy?null:()=>_run(() async {final png=await export.capture(receiptKey);await export.printSystem(png,paper,'Invoice_${shortId(id)}');}),
              icon:const Icon(Icons.print_outlined,size:18),label:Text(ui('طباعة النظام','System print'))),
            if(bluetooth.supported) OutlinedButton.icon(onPressed:busy?null:()=>_run(_bluetooth),icon:const Icon(Icons.bluetooth,size:18),label:Text(ui('طباعة بلوتوث','Bluetooth print'))),
            OutlinedButton.icon(onPressed:busy?null:()=>_run(() async {
              final png=await export.capture(receiptKey);final result=await export.shareImage(png,filename,shareOrigin);
              if(result.status.name=='unavailable' && mounted) showErrorSnack(ui('المشاركة غير متاحة هنا. احفظ الصورة وشاركها يدويًا.','Sharing is unavailable. Save the image and share it manually.'));
            }),icon:const Icon(Icons.share_outlined,size:18),label:Text(ui('مشاركة صورة / واتساب','Share image / WhatsApp'))),
            OutlinedButton.icon(onPressed:busy?null:()=>_run(() async {final png=await export.capture(receiptKey);final saved=await export.saveImage(png,filename);if(saved&&mounted) showSuccessSnack(ui('تم حفظ صورة الفاتورة','Invoice image saved'));}),
              icon:const Icon(Icons.download_outlined,size:18),label:Text(ui('حفظ صورة','Save image'))),
          ]),
          Padding(padding:const EdgeInsets.symmetric(vertical:8),child:Text(ui('اختر WhatsApp من قائمة المشاركة. الطباعة الحرارية على الكمبيوتر عبر تعريف الطابعة في النظام.','Choose WhatsApp in the share sheet. Desktop thermal printing uses the installed printer driver.'),style:Theme.of(context).textTheme.bodySmall)),
          if(busy) const LinearProgressIndicator(),
          if(error!=null) Padding(padding:const EdgeInsets.all(8),child:Text(error!,style:TextStyle(color:Theme.of(context).colorScheme.error))),
          const SizedBox(height:12),
          Center(child:SingleChildScrollView(scrollDirection:Axis.horizontal,child:RepaintBoundary(key:receiptKey,child:InvoiceReceipt(
            invoice:invoice,account:account,business:data.business,items:data.items[invoice.id]??[],paper:paper)))),
        ]));
  });
}
