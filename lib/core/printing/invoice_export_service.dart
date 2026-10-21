import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'esc_pos_raster.dart';

enum ReceiptPaper { a4,mm80,mm58 }
class InvoiceExportService {
  Future<Uint8List> capture(GlobalKey key,{double pixelRatio=2}) async {
    await WidgetsBinding.instance.endOfFrame;
    final boundary=key.currentContext?.findRenderObject();
    if(boundary is! RenderRepaintBoundary || boundary.debugNeedsPaint) throw StateError('انتظر اكتمال معاينة الفاتورة');
    if(boundary.size.height*pixelRatio>20000) throw StateError('الفاتورة طويلة جدًا لصورة واحدة. قسّم البنود إلى أكثر من فاتورة.');
    final image=await boundary.toImage(pixelRatio:pixelRatio);
    try {
      final data=await image.toByteData(format:ui.ImageByteFormat.png);
      if(data==null) throw StateError('تعذر إنشاء صورة الفاتورة');
      return data.buffer.asUint8List(data.offsetInBytes,data.lengthInBytes);
    } finally { image.dispose(); }
  }
  Future<bool> saveImage(Uint8List bytes,String filename) async {
    final path=await FilePicker.platform.saveFile(dialogTitle:'حفظ صورة الفاتورة',fileName:filename,
      type:FileType.custom,allowedExtensions:['png'],bytes:bytes);
    return path!=null;
  }
  Future<ShareResult> shareImage(Uint8List bytes,String filename,Rect origin) => SharePlus.instance.share(ShareParams(
    files:[XFile.fromData(bytes,mimeType:'image/png',name:filename)],fileNameOverrides:[filename],
    title:'فاتورة',sharePositionOrigin:origin,
  ));
  Future<Uint8List> pdf(Uint8List png,ReceiptPaper paper) async {
    final codec=await ui.instantiateImageCodec(png);
    final image=(await codec.getNextFrame()).image;
    final document=pw.Document();
    try {
      final width=paper==ReceiptPaper.a4?PdfPageFormat.a4.width:((paper==ReceiptPaper.mm80?80:58)*PdfPageFormat.mm);
      final margin=paper==ReceiptPaper.a4?24.0:3*PdfPageFormat.mm;
      final usable=width-margin*2;
      final maxRows=paper==ReceiptPaper.a4?((PdfPageFormat.a4.height-margin*2)*image.width/usable).floor():image.height;
      for(var top=0;top<image.height;top+=maxRows) {
        final rows=(image.height-top).clamp(0,maxRows);
        final recorder=ui.PictureRecorder();
        final canvas=ui.Canvas(recorder);
        canvas.drawImageRect(image,ui.Rect.fromLTWH(0,top.toDouble(),image.width.toDouble(),rows.toDouble()),
          ui.Rect.fromLTWH(0,0,image.width.toDouble(),rows.toDouble()),ui.Paint());
        final picture=recorder.endRecording();
        final slice=await picture.toImage(image.width,rows);
        picture.dispose();
        final data=await slice.toByteData(format:ui.ImageByteFormat.png);
        slice.dispose();
        if(data==null) throw StateError('تعذر تجهيز الطباعة');
        final memory=pw.MemoryImage(data.buffer.asUint8List(data.offsetInBytes,data.lengthInBytes));
        final height=paper==ReceiptPaper.a4?PdfPageFormat.a4.height:rows*usable/image.width+margin*2;
        document.addPage(pw.Page(pageFormat:PdfPageFormat(width,height,marginAll:margin),
          build:(_)=>pw.Align(alignment:pw.Alignment.topCenter,child:pw.Image(memory,width:usable))));
      }
      return document.save();
    } finally { image.dispose();codec.dispose(); }
  }
  Future<bool> printSystem(Uint8List png,ReceiptPaper paper,String name) async {
    final bytes=await pdf(png,paper);
    return Printing.layoutPdf(name:name,onLayout:(_) async=>bytes);
  }
  Future<Uint8List> thermal(Uint8List png,{required int dots,bool cut=false}) async {
    final codec=await ui.instantiateImageCodec(png,targetWidth:dots);
    final image=(await codec.getNextFrame()).image;
    try {
      final data=await image.toByteData(format:ui.ImageByteFormat.rawRgba);
      if(data==null) throw StateError('تعذر إنشاء بيانات الطباعة');
      return EscPosRaster.encodeRgba(rgba:data.buffer.asUint8List(data.offsetInBytes,data.lengthInBytes),width:image.width,height:image.height,cut:cut);
    } finally {image.dispose();codec.dispose();}
  }
}
