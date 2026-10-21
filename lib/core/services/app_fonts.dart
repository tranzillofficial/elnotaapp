import 'package:flutter/services.dart';

/// Bundled so Arabic preview, PNG and thermal raster work without a font CDN.
Future<void> loadAppFonts() async {
  final arabic=FontLoader('ElNotaArabic')..addFont(rootBundle.load('assets/fonts/NotoNaskhArabic.ttf'));
  await arabic.load();
}
