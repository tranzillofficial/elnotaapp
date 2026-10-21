import 'package:get/get.dart';
String ui(String ar,String en)=>(Get.locale?.languageCode??'ar')=='ar'?ar:en;
String dateText(DateTime date)=>'${date.year}-${date.month.toString().padLeft(2,'0')}-${date.day.toString().padLeft(2,'0')}';
String shortId(String id)=>id.length>8?id.substring(0,8).toUpperCase():id.toUpperCase();
String invoiceStatus(String status)=>switch(status){
  'posted'=>ui('مسجلة','Posted'),'draft'=>ui('مسودة','Draft'),'voided'=>ui('ملغاة','Voided'),_=>status};
