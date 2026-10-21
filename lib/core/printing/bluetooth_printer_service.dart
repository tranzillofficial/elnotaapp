import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class PairedPrinter {
  const PairedPrinter(this.name,this.address);
  final String name,address;
}
class BluetoothPrinterService {
  static const channel=MethodChannel('com.elnota/thermal_print');
  bool get supported=>!kIsWeb && defaultTargetPlatform==TargetPlatform.android;
  Future<List<PairedPrinter>> paired() async {
    if(!supported) throw UnsupportedError('Bluetooth SPP is available on Android. Use the system printer on desktop/iOS.');
    final rows=await channel.invokeListMethod<dynamic>('pairedDevices')??[];
    return rows.map((r)=>PairedPrinter(r['name'] as String,r['address'] as String)).toList();
  }
  Future<void> print({required String address,required Uint8List bytes}) async {
    if(!supported) throw UnsupportedError('Bluetooth SPP requires Android');
    await channel.invokeMethod<void>('printBytes',{'address':address,'bytes':bytes});
  }
}
