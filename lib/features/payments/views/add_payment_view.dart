import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../../../core/utils/money_utils.dart';
import '../../../core/utils/ui_text.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../accounting/models/accounting_snapshot.dart';
import '../../accounting/repositories/accounting_repository.dart';
import '../../accounting/views/accounting_pages.dart';

class AddPaymentView extends StatefulWidget {
  const AddPaymentView({super.key});
  @override
  State<AddPaymentView> createState()=>_AddPaymentViewState();
}
class _AddPaymentViewState extends State<AddPaymentView> {
  final repo=AccountingRepository();
  late final stream=repo.watch();
  final amount=TextEditingController(),notes=TextEditingController();
  final operationId=const Uuid().v4();
  String? customerId;
  DateTime date=DateUtils.dateOnly(DateTime.now());
  bool busy=false;
  String? error;
  @override
  void initState() { super.initState(); customerId=(Get.arguments as Map<String,dynamic>?)?['customer_id'] as String?; }
  @override
  void dispose() { amount.dispose();notes.dispose();super.dispose(); }
  Future<void> save() async {
    if(busy) return;
    final value=MoneyUtils.parseToMinor(amount.text);
    if(customerId==null || value==null || value<=0) { setState(()=>error=ui('اختار عميل واكتب مبلغًا صحيحًا بخانتين عشريتين كحد أقصى','Select a customer and enter a positive amount with up to two decimals'));return; }
    setState(() {busy=true;error=null;});
    try {
      await repo.dao.addPayment(customerId:customerId!,amountMinor:value,idempotencyKey:operationId,notes:notes.text.trim(),paymentDate:date);
      if(mounted) { Get.back(result:true);showSuccessSnack(ui('تم تسجيل الدفعة على حساب العميل','Payment saved to the customer account')); }
    } catch(e) { if(mounted) setState(()=>error=e.toString()); }
    finally { if(mounted) setState(()=>busy=false); }
  }
  @override
  Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:Text(ui('تسجيل دفعة','Add payment'))),body:StreamBuilder<AccountingSnapshot>(stream:stream,builder:(context,snapshot) {
    if(snapshot.hasError) return AppErrorWidget(message:ui('تعذر تحميل الحساب','Unable to load accounts'),onRetry:repo.refresh);
    final data=snapshot.data;
    if(data==null) return const AppLoadingWidget();
    final account=customerId==null?null:data.customer(customerId!);
    final value=MoneyUtils.parseToMinor(amount.text)??0;
    return Align(alignment:Alignment.topCenter,child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:560),child:ListView(padding:const EdgeInsets.all(16),children:[
      OutlinedButton.icon(onPressed:busy?null:() async { final selected=await chooseCustomer(context,data);if(selected!=null&&mounted) setState(()=>customerId=selected); },
        icon:const Icon(Icons.person_outline),label:Text(account?.customer.name??ui('اختيار العميل','Choose customer'))),
      if(account!=null) Padding(padding:const EdgeInsets.symmetric(vertical:8),child:Text('${ui('رصيد الحساب الحالي','Current account balance')}: ${MoneyUtils.formatMinor(account.balance.outstandingMinor)}')),
      TextField(controller:amount,enabled:!busy,autofocus:account!=null,keyboardType:const TextInputType.numberWithOptions(decimal:true),
        onChanged:(_)=>setState((){}),decoration:InputDecoration(labelText:ui('مبلغ الدفعة','Payment amount'),suffixText:ui('ج.م','EGP'))),
      const SizedBox(height:12),
      OutlinedButton.icon(onPressed:busy?null:() async {final chosen=await showDatePicker(context:context,initialDate:date,firstDate:DateTime(2000),lastDate:DateTime(2100));if(chosen!=null&&mounted) setState(()=>date=chosen);},
        icon:const Icon(Icons.calendar_today_outlined,size:18),label:Text(dateText(date))),
      const SizedBox(height:12),TextField(controller:notes,enabled:!busy,maxLines:3,decoration:InputDecoration(labelText:ui('ملاحظات اختيارية','Optional notes'))),
      if(account!=null && value>0) Padding(padding:const EdgeInsets.symmetric(vertical:12),child:Text('${ui('الرصيد بعد الدفعة','Balance after payment')}: ${MoneyUtils.formatMinor(account.balance.outstandingMinor-value)}\n${ui('الرصيد السالب يظهر كرصيد مقدم لصالح العميل.','A negative balance is customer credit.')}')),
      if(error!=null) Padding(padding:const EdgeInsets.symmetric(vertical:8),child:Text(error!,style:TextStyle(color:Theme.of(context).colorScheme.error))),
      const SizedBox(height:12),FilledButton.icon(onPressed:busy?null:save,icon:busy?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.check,size:18),
        label:Text(ui('حفظ الدفعة','Save payment'))),
    ])));
  }));
}
