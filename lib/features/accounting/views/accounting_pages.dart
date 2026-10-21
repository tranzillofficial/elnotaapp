import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/utils/app_routes.dart';
import '../../../core/database/database_impl.dart';
import '../../../core/utils/money_utils.dart';
import '../../../core/utils/ui_text.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/sync_status_badge.dart';
import '../models/accounting_snapshot.dart';
import '../repositories/accounting_repository.dart';

enum AccountingSection { overview,customers,invoices,payments }

Future<String?> chooseCustomer(BuildContext context,AccountingSnapshot data) async {
  if(data.customers.isEmpty) {
    await Get.toNamed(AppRoutes.customerCreate);
    return null;
  }
  return showDialog<String>(context:context,builder:(context) {
    var search='';
    return StatefulBuilder(builder:(context,setState)=>AlertDialog(
      title:Text(ui('اختيار العميل','Choose customer')),
      content:SizedBox(width:360,height:360,child:Column(children:[
        TextField(autofocus:true,decoration:InputDecoration(hintText:ui('اسم العميل أو الهاتف','Name or phone'),prefixIcon:const Icon(Icons.search)),
          onChanged:(v)=>setState(()=>search=v.toLowerCase())),
        const SizedBox(height:8),
        Expanded(child:ListView(children:data.customers.where((c)=>'${c.customer.name} ${c.customer.phone??''}'.toLowerCase().contains(search)).map((c)=>ListTile(
          dense:true,title:Text(c.customer.name),subtitle:Text(c.customer.phone??''),
          onTap:()=>Navigator.pop(context,c.customer.id))).toList())),
      ])),
      actions:[TextButton(onPressed:()=>Navigator.pop(context),child:Text(ui('إلغاء','Cancel')))],
    ));
  });
}

class AccountingPage extends StatefulWidget {
  const AccountingPage({super.key,required this.section,this.repository});
  final AccountingSection section;
  final AccountingRepository? repository;
  @override
  State<AccountingPage> createState()=>_AccountingPageState();
}
class _AccountingPageState extends State<AccountingPage> {
  late final repo=widget.repository??AccountingRepository();
  late final stream=repo.watch();
  String search='',filter='all';
  DateTimeRange? range;
  bool sortByBalance=true;
  String get title=>switch(widget.section){
    AccountingSection.overview=>ui('الرئيسية','Overview'),AccountingSection.customers=>ui('العملاء','Customers'),
    AccountingSection.invoices=>ui('الفواتير','Invoices'),AccountingSection.payments=>ui('المدفوعات','Payments')};
  Future<void> _create(AccountingSnapshot data) async {
    if(widget.section==AccountingSection.customers) { await Get.toNamed(AppRoutes.customerCreate); return; }
    final id=await chooseCustomer(context,data);
    if(id!=null) { await Get.toNamed(widget.section==AccountingSection.payments?AppRoutes.paymentCreate:AppRoutes.invoiceCreate,arguments:{'customer_id':id}); }
  }
  bool _matchesDate(DateTime date)=>range==null || (!date.isBefore(range!.start) && date.isBefore(range!.end.add(const Duration(days:1))));
  Future<void> _dates() async {
    final selected=await showDateRangePicker(context:context,firstDate:DateTime(2000),lastDate:DateTime(2100),initialDateRange:range);
    if(selected!=null && mounted) setState(()=>range=selected);
  }
  @override
  Widget build(BuildContext context)=>StreamBuilder<AccountingSnapshot>(stream:stream,builder:(context,snapshot) {
    final data=snapshot.data;
    return Scaffold(
      appBar:AppBar(title:Text(title),actions:[const SyncStatusBadge(),IconButton(tooltip:ui('تحديث','Refresh'),onPressed:repo.refresh,icon:const Icon(Icons.refresh))]),
      body:snapshot.hasError?AppErrorWidget(message:ui('تعذر تحميل البيانات','Unable to load data'),onRetry:repo.refresh):data==null?const AppLoadingWidget():
        widget.section==AccountingSection.overview?_overview(data):_list(data),
      floatingActionButton:data==null?null:FloatingActionButton.extended(heroTag:'create_${widget.section.name}',onPressed:()=>_create(data),
        icon:const Icon(Icons.add),label:Text(switch(widget.section){
          AccountingSection.customers=>ui('إضافة عميل','Add customer'),AccountingSection.payments=>ui('تسجيل دفعة','Add payment'),_=>ui('فاتورة جديدة','New invoice')})),
    );
  });
  Widget _overview(AccountingSnapshot data) {
    final recent=data.invoices.take(6).toList();
    final today=DateUtils.dateOnly(DateTime.now());
    final todayReceived=data.payments.where((p)=>DateUtils.dateOnly(p.paymentDate)==today).fold<int>(0,(s,p)=>s+p.amountMinor);
    return ListView(padding:const EdgeInsets.fromLTRB(16,8,16,96),children:[
      Text(data.business.name.isEmpty?ui('حسابات نشاطك','Your business accounts'):data.business.name,style:Theme.of(context).textTheme.titleMedium),
      const SizedBox(height:8),
      Wrap(spacing:10,runSpacing:10,children:[
        MetricTile(label:ui('العملاء','Customers'),value:'${data.customers.length}'),
        MetricTile(label:ui('إجمالي المستحق','Outstanding'),value:MoneyUtils.formatMinor(data.outstandingMinor)),
        MetricTile(label:ui('إجمالي المحصل','Total received'),value:MoneyUtils.formatMinor(data.receivedMinor)),
        MetricTile(label:ui('تحصيل اليوم','Received today'),value:MoneyUtils.formatMinor(todayReceived)),
      ]),
      const SizedBox(height:12),
      Wrap(spacing:8,runSpacing:4,children:[
        OutlinedButton.icon(onPressed:()=>Get.toNamed(AppRoutes.customerCreate),icon:const Icon(Icons.person_add_outlined,size:18),label:Text(ui('عميل جديد','New customer'))),
        OutlinedButton.icon(onPressed:() async {final id=await chooseCustomer(context,data);if(id!=null) await Get.toNamed(AppRoutes.paymentCreate,arguments:{'customer_id':id});},
          icon:const Icon(Icons.payments_outlined,size:18),label:Text(ui('تسجيل دفعة','Add payment'))),
      ]),
      const SizedBox(height:12),Text(ui('أحدث الفواتير','Recent invoices'),style:Theme.of(context).textTheme.titleSmall),
      if(recent.isEmpty) Padding(padding:const EdgeInsets.symmetric(vertical:20),child:Text(ui('أضف أول عميل وفاتورة لبدء حساباتك.','Add your first customer and invoice to get started.'))),
      ...recent.map((i)=>InvoiceTile(invoice:i,customer:data.customerName(i.customerId))),
      const SizedBox(height:12),Text(ui('أعلى الحسابات المستحقة','Largest outstanding accounts'),style:Theme.of(context).textTheme.titleSmall),
      ...([...data.customers]..sort((a,b)=>b.balance.outstandingMinor.compareTo(a.balance.outstandingMinor))).where((c)=>c.balance.outstandingMinor>0).take(5).map((c)=>CustomerAccountTile(account:c)),
      if(data.creditMinor>0) Padding(padding:const EdgeInsets.symmetric(vertical:8),child:Text('${ui('أرصدة مقدمة للعملاء','Customer credit')}: ${MoneyUtils.formatMinor(data.creditMinor)}')),
    ]);
  }
  Widget _list(AccountingSnapshot data) {
    final section=widget.section;
    final query=search.toLowerCase();
    final customers=data.customers.where((c)=>'${c.customer.name} ${c.customer.phone??''} ${c.customer.address}'.toLowerCase().contains(query))
      .where((c)=>filter=='all'||(filter=='due'&&c.balance.outstandingMinor>0)||(filter=='credit'&&c.balance.outstandingMinor<0)||(filter=='settled'&&c.balance.outstandingMinor==0)).toList();
    if(sortByBalance) customers.sort((a,b)=>b.balance.outstandingMinor.compareTo(a.balance.outstandingMinor));
    final invoices=data.invoices.where((i)=>'${i.invoiceNumber??i.id} ${data.customerName(i.customerId)} ${i.notes??''}'.toLowerCase().contains(query))
      .where((i)=>(filter=='all'||i.status==filter)&&_matchesDate(i.invoiceDate)).toList();
    final payments=data.payments.where((p)=>'${data.customerName(p.customerId)} ${p.notes??''} ${p.id}'.toLowerCase().contains(query))
      .where((p)=>_matchesDate(p.paymentDate)).toList();
    final count=section==AccountingSection.customers?customers.length:section==AccountingSection.invoices?invoices.length:payments.length;
    final total=section==AccountingSection.customers?customers.fold<int>(0,(s,c)=>s+c.balance.outstandingMinor):section==AccountingSection.invoices?invoices.where((i)=>i.status=='posted').fold<int>(0,(s,i)=>s+i.netMinor):payments.fold<int>(0,(s,p)=>s+p.amountMinor);
    return Column(children:[
      Padding(padding:const EdgeInsets.fromLTRB(16,0,16,8),child:Column(children:[
        TextField(decoration:InputDecoration(hintText:ui('بحث بالاسم أو الرقم','Search name or number'),prefixIcon:const Icon(Icons.search)),onChanged:(v)=>setState(()=>search=v)),
        const SizedBox(height:8),
        Wrap(spacing:8,runSpacing:4,crossAxisAlignment:WrapCrossAlignment.center,children:[
          if(section!=AccountingSection.payments) SizedBox(width:160,child:DropdownButtonFormField<String>(
            initialValue:filter,isExpanded:true,decoration:InputDecoration(labelText:ui('عرض','Show'),isDense:true),
            items:(section==AccountingSection.customers?{'all':ui('كل العملاء','All customers'),'due':ui('عليهم مستحق','Outstanding'),'settled':ui('حساب مسدد','Settled'),'credit':ui('رصيد مقدم','Credit')}:
              {'all':ui('كل الفواتير','All invoices'),'posted':ui('مسجلة','Posted'),'draft':ui('مسودات','Drafts'),'voided':ui('ملغاة','Voided')})
              .entries.map((e)=>DropdownMenuItem(value:e.key,child:Text(e.value,maxLines:1,overflow:TextOverflow.ellipsis))).toList(),onChanged:(v)=>setState(()=>filter=v??'all'))),
          if(section==AccountingSection.customers) TextButton.icon(onPressed:()=>setState(()=>sortByBalance=!sortByBalance),icon:const Icon(Icons.sort,size:18),
            label:Text(sortByBalance?ui('حسب المديونية','By balance'):ui('حسب الاسم','By name')))
          else OutlinedButton.icon(onPressed:_dates,icon:const Icon(Icons.date_range,size:18),label:Text(range==null?ui('كل التواريخ','All dates'):'${dateText(range!.start)} / ${dateText(range!.end)}')),
          if(range!=null) IconButton(tooltip:ui('مسح التاريخ','Clear date'),onPressed:()=>setState(()=>range=null),icon:const Icon(Icons.close,size:18)),
        ]),
        const SizedBox(height:8),Align(alignment:AlignmentDirectional.centerStart,child:Text('$count ${ui('سجل','records')} · ${MoneyUtils.formatMinor(total)}',style:Theme.of(context).textTheme.bodySmall)),
      ])),
      Expanded(child:count==0?AppEmptyWidget(message:ui('لا توجد نتائج','No matching records')):ListView.builder(
        padding:const EdgeInsets.fromLTRB(12,0,12,96),itemCount:count,itemBuilder:(context,index)=>switch(section){
          AccountingSection.customers=>CustomerAccountTile(account:customers[index]),
          AccountingSection.invoices=>InvoiceTile(invoice:invoices[index],customer:data.customerName(invoices[index].customerId)),
          _=>PaymentTile(payment:payments[index],customer:data.customerName(payments[index].customerId)),
        })),
    ]);
  }
}

class MetricTile extends StatelessWidget {
  const MetricTile({super.key,required this.label,required this.value});
  final String label,value;
  @override
  Widget build(BuildContext context)=>SizedBox(width:(MediaQuery.sizeOf(context).width<400?136:180),child:Card(child:Padding(
    padding:const EdgeInsets.all(12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Text(label,style:Theme.of(context).textTheme.bodySmall),const SizedBox(height:4),
      Text(value,style:Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight:FontWeight.w700)),
    ]))));
}

class CustomerAccountTile extends StatelessWidget {
  const CustomerAccountTile({super.key,required this.account});
  final CustomerAccount account;
  @override
  Widget build(BuildContext context) {
    final c=account.customer,b=account.balance;
    return Card(child:ListTile(onTap:()=>Get.toNamed(AppRoutes.customerDetail,arguments:{'id':c.id}),
      title:Text(c.name,maxLines:2,overflow:TextOverflow.ellipsis),subtitle:Text(c.phone??ui('بدون هاتف','No phone')),
      trailing:SizedBox(width:125,child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.end,children:[
        Text(MoneyUtils.formatMinor(b.outstandingMinor.abs()),style:TextStyle(fontWeight:FontWeight.w700,color:b.outstandingMinor>0?Theme.of(context).colorScheme.error:Theme.of(context).colorScheme.primary)),
        Text(b.outstandingMinor<0?ui('رصيد مقدم','Credit'):b.outstandingMinor==0?ui('مسدد','Settled'):ui('مستحق','Outstanding'),style:Theme.of(context).textTheme.labelSmall),
      ]))));
  }
}
class InvoiceTile extends StatelessWidget {
  const InvoiceTile({super.key,required this.invoice,required this.customer});
  final InvoiceRow invoice;
  final String customer;
  @override
  Widget build(BuildContext context)=>Card(child:ListTile(
    onTap:()=>Get.toNamed(AppRoutes.invoiceDetail,arguments:{'invoice_id':invoice.id}),
    title:Text(customer,maxLines:2,overflow:TextOverflow.ellipsis),
    subtitle:Text('${invoice.invoiceNumber??shortId(invoice.id)} · ${dateText(invoice.invoiceDate)}'),
    trailing:SizedBox(width:125,child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.end,children:[
      Text(MoneyUtils.formatMinor(invoice.netMinor),style:const TextStyle(fontWeight:FontWeight.w700)),
      Text(invoiceStatus(invoice.status),style:Theme.of(context).textTheme.labelSmall),
    ]))));
}
class PaymentTile extends StatelessWidget {
  const PaymentTile({super.key,required this.payment,required this.customer});
  final PaymentRow payment;
  final String customer;
  @override
  Widget build(BuildContext context)=>Card(child:ListTile(
    title:Text(customer,maxLines:2,overflow:TextOverflow.ellipsis),subtitle:Text('${dateText(payment.paymentDate)}${payment.notes?.isNotEmpty==true?' · ${payment.notes}':''}',maxLines:2,overflow:TextOverflow.ellipsis),
    trailing:SizedBox(width:125,child:Text(MoneyUtils.formatMinor(payment.amountMinor),textAlign:TextAlign.end,style:TextStyle(fontWeight:FontWeight.w700,color:Theme.of(context).colorScheme.primary))),
    onTap:()=>showDialog<void>(context:context,builder:(context)=>AlertDialog(title:Text(ui('تفاصيل الدفعة','Payment details')),
      content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text(customer),const SizedBox(height:8),Text(MoneyUtils.formatMinor(payment.amountMinor),style:Theme.of(context).textTheme.titleLarge),
        Text(dateText(payment.paymentDate)),if(payment.notes?.isNotEmpty==true) Text(payment.notes!),
        const SizedBox(height:8),Text(ui('دفعة على إجمالي حساب العميل','Payment against the customer account')),
        SelectableText('ID: ${payment.id}',style:Theme.of(context).textTheme.labelSmall),
        const SizedBox(height:8),Text(ui('محفوظة على الجهاز','Saved on this device')),
      ])),actions:[TextButton(onPressed:()=>Navigator.pop(context),child:Text(ui('إغلاق','Close'))),
        TextButton(onPressed:(){Navigator.pop(context);Get.toNamed(AppRoutes.customerDetail,arguments:{'id':payment.customerId});},child:Text(ui('حساب العميل','Customer account')))])),
  ));
}
