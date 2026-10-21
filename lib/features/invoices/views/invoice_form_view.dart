import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/utils/app_routes.dart';
import '../../../core/utils/money_utils.dart';
import '../../../core/utils/ui_text.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../accounting/models/accounting_snapshot.dart';
import '../../accounting/repositories/accounting_repository.dart';
import '../../accounting/views/accounting_pages.dart';

class InvoiceFormView extends StatefulWidget {
  const InvoiceFormView({super.key,this.repository,this.initialCustomerId});
  final AccountingRepository? repository;
  final String? initialCustomerId;
  @override
  State<InvoiceFormView> createState()=>_InvoiceFormViewState();
}
class _InvoiceFormViewState extends State<InvoiceFormView> {
  late final repo=widget.repository??AccountingRepository();
  late final stream=repo.watch();
  final amount=TextEditingController(),discount=TextEditingController(),notes=TextEditingController();
  final lines=<Map<String,dynamic>>[];
  String? customerId,error;
  bool manual=true,busy=false;
  DateTime date=DateUtils.dateOnly(DateTime.now());
  DateTime? due;
  int get total=>manual?(MoneyUtils.parseToMinor(amount.text)??0):lines.fold<int>(0,(s,l)=>s+(l['quantity'] as int)*(l['unit_price_minor'] as int));
  int get discountMinor=>MoneyUtils.parseToMinor(discount.text)??0;
  @override
  void initState() {super.initState();customerId=widget.initialCustomerId??((Get.arguments as Map<String,dynamic>?)?['customer_id'] as String?);}
  @override
  void dispose() {amount.dispose();discount.dispose();notes.dispose();super.dispose();}
  Future<void> addLine({int? index}) async {
    final existing=index==null?null:lines[index];
    final name=TextEditingController(text:existing?['description'] as String? ?? ''),
      quantity=TextEditingController(text:'${existing?['quantity']??1}'),
      price=TextEditingController(text:existing==null?'':MoneyUtils.formatMinorNoSymbol(existing['unit_price_minor'] as int));
    String? validation;
    final route=DialogRoute<Map<String,dynamic>>(context:context,builder:(context)=>StatefulBuilder(builder:(context,update)=>AlertDialog(
      title:Text(ui('صنف الفاتورة','Invoice item')),
      content:SizedBox(width:340,child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
        TextField(controller:name,autofocus:true,decoration:InputDecoration(labelText:ui('اسم الصنف','Description'))),
        const SizedBox(height:12),TextField(controller:quantity,keyboardType:TextInputType.number,decoration:InputDecoration(labelText:ui('الكمية','Quantity'))),
        const SizedBox(height:12),TextField(controller:price,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:InputDecoration(labelText:ui('سعر الوحدة','Unit price'))),
        if(validation!=null) Text(validation!,style:TextStyle(color:Theme.of(context).colorScheme.error)),
      ]))),actions:[TextButton(onPressed:()=>Navigator.pop(context),child:Text(ui('إلغاء','Cancel'))),FilledButton(onPressed:(){
        final q=int.tryParse(quantity.text),p=MoneyUtils.parseToMinor(price.text);
        if(name.text.trim().isEmpty||q==null||q<=0||p==null||p<0) {update(()=>validation=ui('راجع الاسم والكمية والسعر','Check description, quantity and price'));return;}
        Navigator.pop(context,{'description':name.text.trim(),'quantity':q,'unit_price_minor':p,'discount_minor':0});
      },child:Text(ui('حفظ','Save')))],
    )));
    final result=await Navigator.of(context).push(route);
    await route.completed;
    name.dispose();quantity.dispose();price.dispose();
    if(result!=null && mounted) setState(() {if(index==null) {lines.add(result);} else {lines[index]=result;}});
  }
  Future<void> save() async {
    if(busy) return;
    final parsedDiscount=discount.text.trim().isEmpty?0:MoneyUtils.parseToMinor(discount.text);
    if(customerId==null||total<=0||(manual&&MoneyUtils.parseToMinor(amount.text)==null)||parsedDiscount==null||parsedDiscount<0||parsedDiscount>total||(!manual&&lines.isEmpty)) {
      setState(()=>error=ui('راجع العميل والمبلغ والخصم. المبالغ بخانتين عشريتين كحد أقصى.','Check customer, amount and discount. Use up to two decimals.'));return;
    }
    if(due!=null&&due!.isBefore(date)) {setState(()=>error=ui('الاستحقاق لا يسبق تاريخ الفاتورة','Due date cannot precede invoice date'));return;}
    setState(() {busy=true;error=null;});
    try {
      final id=await repo.dao.createAndPostInvoice(customerId:customerId!,totalMinor:total,isManualAmount:manual,
        items:manual?[]:lines,discountMinor:parsedDiscount,notes:notes.text.trim(),invoiceDate:date,dueDate:due);
      if(mounted) Get.offNamed(AppRoutes.invoiceDetail,arguments:{'invoice_id':id});
    } catch(e) {if(mounted) setState(()=>error=e.toString());}
    finally {if(mounted) setState(()=>busy=false);}
  }
  @override
  Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:Text(ui('فاتورة جديدة','New invoice'))),body:StreamBuilder<AccountingSnapshot>(stream:stream,builder:(context,snapshot){
    if(snapshot.hasError) return AppErrorWidget(message:ui('تعذر تحميل العملاء','Unable to load customers'),onRetry:repo.refresh);
    final data=snapshot.data;if(data==null) return const AppLoadingWidget();
    return Align(alignment:Alignment.topCenter,child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:760),child:ListView(padding:const EdgeInsets.all(16),children:[
      OutlinedButton.icon(onPressed:busy?null:() async {final selected=await chooseCustomer(context,data);if(selected!=null&&mounted) setState(()=>customerId=selected);},
        icon:const Icon(Icons.person_outline,size:18),label:Text(customerId==null?ui('اختيار العميل','Choose customer'):data.customerName(customerId!))),
      const SizedBox(height:12),SegmentedButton<bool>(segments:[ButtonSegment(value:true,label:Text(ui('مبلغ يدوي','Amount'))),ButtonSegment(value:false,label:Text(ui('أصناف','Items')))],
        selected:{manual},onSelectionChanged:busy?null:(s)=>setState(()=>manual=s.first)),
      const SizedBox(height:12),
      if(manual) TextField(controller:amount,enabled:!busy,onChanged:(_)=>setState((){}),keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:InputDecoration(labelText:ui('قيمة الفاتورة','Invoice amount'),suffixText:ui('ج.م','EGP')))
      else ...[
        ...lines.asMap().entries.map((e)=>Card(child:ListTile(onTap:busy?null:()=>addLine(index:e.key),title:Text(e.value['description'] as String),
          subtitle:Text('${e.value['quantity']} × ${MoneyUtils.formatMinor(e.value['unit_price_minor'] as int)}'),
          trailing:IconButton(tooltip:ui('حذف الصنف','Remove item'),onPressed:busy?null:()=>setState(()=>lines.removeAt(e.key)),icon:const Icon(Icons.close,size:18))))),
        TextButton.icon(onPressed:busy?null:()=>addLine(),icon:const Icon(Icons.add,size:18),label:Text(ui('إضافة صنف','Add item'))),
      ],
      const SizedBox(height:12),TextField(controller:discount,enabled:!busy,onChanged:(_)=>setState((){}),keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:InputDecoration(labelText:ui('خصم اختياري','Optional discount'))),
      const SizedBox(height:12),Wrap(spacing:8,runSpacing:4,children:[
        OutlinedButton.icon(onPressed:busy?null:() async {final d=await showDatePicker(context:context,initialDate:date,firstDate:DateTime(2000),lastDate:DateTime(2100));if(d!=null&&mounted) setState(()=>date=d);},icon:const Icon(Icons.calendar_today_outlined,size:18),label:Text(dateText(date))),
        OutlinedButton.icon(onPressed:busy?null:() async {final d=await showDatePicker(context:context,initialDate:due??date,firstDate:date,lastDate:DateTime(2100));if(d!=null&&mounted) setState(()=>due=d);},icon:const Icon(Icons.event_outlined,size:18),label:Text(due==null?ui('تاريخ الاستحقاق','Due date'):dateText(due!))),
        if(due!=null) IconButton(tooltip:ui('مسح الاستحقاق','Clear due date'),onPressed:busy?null:()=>setState(()=>due=null),icon:const Icon(Icons.close,size:18)),
      ]),
      const SizedBox(height:12),TextField(controller:notes,enabled:!busy,maxLines:3,decoration:InputDecoration(labelText:ui('وصف أو ملاحظات','Description or notes'))),
      const SizedBox(height:12),Card(child:Padding(padding:const EdgeInsets.all(12),child:Wrap(spacing:20,runSpacing:4,children:[
        Text('${ui('الإجمالي','Total')}: ${MoneyUtils.formatMinor(total)}'),Text('${ui('الصافي','Net')}: ${MoneyUtils.formatMinor(total-discountMinor)}'),
      ]))),
      if(error!=null) Padding(padding:const EdgeInsets.all(8),child:Text(error!,style:TextStyle(color:Theme.of(context).colorScheme.error))),
      const SizedBox(height:12),FilledButton.icon(onPressed:busy?null:save,icon:busy?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.check,size:18),label:Text(ui('حفظ وعرض الفاتورة','Save and view invoice'))),
    ])));
  }));
}
