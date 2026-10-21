import 'dart:typed_data';

/// ESC/POS GS v 0 raster bands. Arabic is shaped by Flutter before encoding.
/// Each band is bounded so common receipt-printer buffers can accept it.
abstract final class EscPosRaster {
  static Uint8List encodeRgba({required Uint8List rgba,required int width,required int height,bool cut=false}) {
    if(width<=0 || width>832 || height<=0 || height>20000 || rgba.length!=width*height*4) {
      throw ArgumentError('Invalid thermal raster dimensions');
    }
    final bytes=BytesBuilder(copy:false)..add([0x1b,0x40]);
    final rowBytes=(width+7)~/8;
    for(var top=0;top<height;top+=128) {
      final rows=(height-top).clamp(0,128);
      final band=Uint8List(rowBytes*rows);
      for(var y=0;y<rows;y++) {
        for(var x=0;x<width;x++) {
          final i=((top+y)*width+x)*4;
          final alpha=rgba[i+3];
          // Composite transparency onto white before thresholding.
          final luminance=(rgba[i]*299+rgba[i+1]*587+rgba[i+2]*114)~/1000;
          final onWhite=(luminance*alpha+255*(255-alpha))~/255;
          if(onWhite<160) band[y*rowBytes+x~/8]|=0x80>>(x%8);
        }
      }
      bytes.add([0x1d,0x76,0x30,0,rowBytes&255,rowBytes>>8,rows&255,rows>>8]);
      bytes.add(band);
    }
    bytes.add([0x1b,0x64,4]);
    if(cut) bytes.add([0x1d,0x56,0]);
    return bytes.takeBytes();
  }
}
