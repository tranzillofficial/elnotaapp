/// Money formatting utilities for ElNota.
/// All amounts are stored as integer minor units (piasters for EGP).
/// Never uses double/float for calculations.
library;

class MoneyUtils {
  MoneyUtils._();

  static const int _factor = 100; // 1 EGP = 100 piasters

  /// Convert minor units to display string with 2 decimal places.
  /// Example: 150025 → '1,500.25'
  static String formatMinor(int minor, {String symbol = 'ج.م'}) {
    final isNeg = minor < 0;
    final abs = minor.abs();
    final whole = abs ~/ _factor;
    final frac = abs % _factor;
    final fracStr = frac.toString().padLeft(2, '0');
    // Thousands separator
    final wholeStr = _addThousands(whole);
    final formatted = '$wholeStr.$fracStr';
    return isNeg ? '($formatted $symbol)' : '$formatted $symbol';
  }

  /// Returns a human-readable amount without symbol.
  static String formatMinorNoSymbol(int minor) {
    final isNeg = minor < 0;
    final abs = minor.abs();
    final whole = abs ~/ _factor;
    final frac = abs % _factor;
    final fracStr = frac.toString().padLeft(2, '0');
    final wholeStr = _addThousands(whole);
    return isNeg ? '-$wholeStr.$fracStr' : '$wholeStr.$fracStr';
  }

  /// Alias for formatMinorNoSymbol.
  static String minorToDisplay(int minor) => formatMinorNoSymbol(minor);

  /// Parse a string like '1500.25' or '1500' into minor units.
  /// Returns null if input is invalid.
  static int? parseToMinor(String input) {
    final clean = input.trim().replaceAll(',', '');
    if (clean.isEmpty) return null;
    final parts = clean.split('.');
    if (parts.length > 2) return null;
    final whole = int.tryParse(parts[0]);
    if (whole == null) return null;
    int frac = 0;
    if (parts.length == 2) {
      final fracStr = parts[1].length > 2 ? parts[1].substring(0, 2) : parts[1].padRight(2, '0');
      frac = int.tryParse(fracStr) ?? 0;
    }
    return whole * _factor + frac;
  }

  static String _addThousands(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}
