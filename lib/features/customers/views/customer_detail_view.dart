import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/utils/app_routes.dart';
import '../../../core/utils/money_utils.dart';
import '../../../core/utils/ui_text.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../accounting/models/accounting_snapshot.dart';
import '../../accounting/repositories/accounting_repository.dart';
import '../../accounting/views/accounting_pages.dart';

class CustomerDetailView extends StatefulWidget {
  const CustomerDetailView({super.key,this.customerId,this.repository});
  final String? customerId;
  final AccountingRepository? repository;
  @override
  State<CustomerDetailView> createState()=>_CustomerDetailViewState();
}
class _CustomerDetailViewState extends State<CustomerDetailView> {
  late final id=widget.customerId??((Get.arguments as Map<String,dynamic>?)?['id'] as String?)??'';
  late final repo=widget.repository??AccountingRepository();
  late final stream=repo.watch();
  @override
  Widget build(BuildContext context)=>StreamBuilder<AccountingSnapshot>(stream:stream,builder:(context,snapshot) {
    final data=snapshot.data, account=snapshot.data?.customer(id);
    final invoices=data?.invoices.where((i)=>i.customerId==id).toList()??[];
    final payments=data?.payments.where((p)=>p.customerId==id).toList()??[];
    return DefaultTabController(length:2,child:Scaffold(
      appBar:AppBar(title:Text(account?.customer.name??ui('حساب العميل','Customer account')),actions:[
        IconButton(tooltip:ui('تعديل العميل','Edit customer'),onPressed:account==null?null:()=>Get.toNamed(AppRoutes.customerCreate,arguments:{'id':id}),icon:const Icon(Icons.edit_outlined)),
      ],bottom:TabBar(tabs:[Tab(text:'${ui('الفواتير','Invoices')} (${invoices.length})'),Tab(text:'${ui('المدفوعات','Payments')} (${payments.length})')])),
      body:snapshot.hasError?AppErrorWidget(message:ui('تعذر تحميل الحساب','Unable to load account'),onRetry:repo.refresh):
        data==null?const AppLoadingWidget():account==null?AppErrorWidget(message:ui('العميل غير موجود','Customer not found')):
        Column(children:[
          Padding(padding:const EdgeInsets.all(12),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
            if(account.customer.phone?.isNotEmpty==true) Text(account.customer.phone!),
            if(account.customer.address.isNotEmpty) Text(account.customer.address),
            if(account.customer.notes?.isNotEmpty==true) Text(account.customer.notes!),
            const SizedBox(height:8),Wrap(spacing:8,runSpacing:8,children:[
              MetricTile(label:ui('إجمالي الفواتير','Total invoiced'),value:MoneyUtils.formatMinor(account.balance.totalInvoicedMinor)),
              MetricTile(label:ui('إجمالي الدفعات','Total received'),value:MoneyUtils.formatMinor(account.balance.totalPaymentsMinor)),
              MetricTile(label:account.balance.outstandingMinor<0?ui('رصيد مقدم','Credit'):ui('المتبقي','Outstanding'),value:MoneyUtils.formatMinor(account.balance.outstandingMinor.abs())),
            ]),
            const SizedBox(height:8),Wrap(spacing:8,runSpacing:4,children:[
              FilledButton.icon(onPressed:()=>Get.toNamed(AppRoutes.paymentCreate,arguments:{'customer_id':id}),icon:const Icon(Icons.payments_outlined,size:18),label:Text(ui('تسجيل دفعة','Add payment'))),
              OutlinedButton.icon(onPressed:()=>Get.toNamed(AppRoutes.invoiceCreate,arguments:{'customer_id':id}),icon:const Icon(Icons.add,size:18),label:Text(ui('فاتورة جديدة','New invoice'))),
            ]),
          ])),
          Expanded(child:TabBarView(children:[
            invoices.isEmpty?AppEmptyWidget(message:ui('لا توجد فواتير','No invoices')):ListView.builder(padding:const EdgeInsets.all(12),itemCount:invoices.length,itemBuilder:(context,i)=>InvoiceTile(invoice:invoices[i],customer:account.customer.name)),
            payments.isEmpty?AppEmptyWidget(message:ui('لا توجد دفعات','No payments')):ListView.builder(padding:const EdgeInsets.all(12),itemCount:payments.length,itemBuilder:(context,i)=>PaymentTile(payment:payments[i],customer:account.customer.name)),
          ])),
        ]),
    ));
  });
}
