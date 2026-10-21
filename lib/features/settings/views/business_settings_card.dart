import 'package:flutter/material.dart';
import '../../../core/utils/ui_text.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../accounting/models/accounting_snapshot.dart';
import '../../accounting/repositories/accounting_repository.dart';
class BusinessSettingsCard extends StatefulWidget {
  const BusinessSettingsCard({super.key});
  @override
  State<BusinessSettingsCard> createState()=>_BusinessSettingsCardState();
}
class _BusinessSettingsCardState extends State<BusinessSettingsCard> {
  final repo=AccountingRepository();
  late final stream=repo.watch();
  Future<void> edit(BusinessInfo info) async {
    final name=TextEditingController(text:info.name),phone=TextEditingController(text:info.phone),address=TextEditingController(text:info.address);
    var busy=false;String? error;
    final route=DialogRoute<void>(context:context,barrierDismissible:false,builder:(context)=>StatefulBuilder(builder:(context,update)=>AlertDialog(
      title:Text(ui('بيانات النشاط والفاتورة','Business and invoice details')),
      content:SizedBox(width:360,child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
        TextField(controller:name,enabled:!busy,decoration:InputDecoration(labelText:ui('اسم النشاط','Business name'))),const SizedBox(height:12),
        TextField(controller:phone,enabled:!busy,keyboardType:TextInputType.phone,decoration:InputDecoration(labelText:ui('الهاتف','Phone'))),const SizedBox(height:12),
        TextField(controller:address,enabled:!busy,maxLines:2,decoration:InputDecoration(labelText:ui('العنوان','Address'))),
        if(error!=null) Text(error!,style:TextStyle(color:Theme.of(context).colorScheme.error)),
      ]))),actions:[TextButton(onPressed:busy?null:()=>Navigator.pop(context),child:Text(ui('إلغاء','Cancel'))),FilledButton(onPressed:busy?null:() async {
        if(name.text.trim().isEmpty) {update(()=>error=ui('اكتب اسم النشاط','Enter a business name'));return;}
        update(()=>busy=true);
        try {await repo.saveBusiness(BusinessInfo(name:name.text,phone:phone.text,address:address.text));if(context.mounted) Navigator.pop(context);}
        catch(e) {if(context.mounted) update(() {busy=false;error=e.toString();});}
      },child:Text(ui('حفظ','Save')))],
    )));
    await Navigator.of(context).push(route);
    await route.completed;
    name.dispose();phone.dispose();address.dispose();
  }
  @override
  Widget build(BuildContext context)=>StreamBuilder<AccountingSnapshot>(stream:stream,builder:(context,snapshot)=>Card(child:ListTile(
    leading:const Icon(Icons.storefront_outlined,size:20),title:Text(snapshot.data?.business.name.isNotEmpty==true?snapshot.data!.business.name:ui('بيانات النشاط والفاتورة','Business and invoice details')),
    subtitle:Text(ui('الاسم والهاتف والعنوان الظاهرون على الفاتورة','Name, phone and address shown on receipts')),trailing:const Icon(Icons.edit_outlined,size:18),
    onTap:snapshot.hasError?()=>showErrorSnack(ui('تعذر تحميل بيانات النشاط','Unable to load business details')):()=>edit(snapshot.data?.business??const BusinessInfo()),
  )));
}
