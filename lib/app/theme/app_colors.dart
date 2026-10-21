import 'package:flutter/material.dart';

/// Design-token colour palette for ElNota.
/// Source: docs/DESIGN.md visual tokens.
abstract class AppColors {
  // ── Light palette ──────────────────────────────────────────────────────────
  static const Color canvasLight = Color(0xFFF7F6F2);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceVariantLight = Color(0xFFF0EFE9);
  static const Color textPrimaryLight = Color(0xFF1F2528);
  static const Color textSecondaryLight = Color(0xFF687078);
  static const Color borderLight = Color(0xFFE7E7E1);

  // ── Dark palette ───────────────────────────────────────────────────────────
  static const Color canvasDark = Color(0xFF121619);
  static const Color surfaceDark = Color(0xFF1C2226);
  static const Color surfaceVariantDark = Color(0xFF242B30);
  static const Color textPrimaryDark = Color(0xFFF3F5F4);
  static const Color textSecondaryDark = Color(0xFF8FA4AE);
  static const Color borderDark = Color(0xFF30383C);

  // ── Semantic / brand ───────────────────────────────────────────────────────
  /// Primary accent: restrained green — trust and money.
  static const Color accent = Color(0xFF246B5A);
  static const Color accentDark = Color(0xFF2D8570);

  static const Color danger = Color(0xFFC44B46);
  static const Color warning = Color(0xFFB7791F);
  static const Color success = Color(0xFF2E7D52);
  static const Color info = Color(0xFF1B6B9E);

  // ── Sync status indicators ─────────────────────────────────────────────────
  static const Color syncPending = Color(0xFFB7791F);   // warning amber
  static const Color syncOk = Color(0xFF2E7D52);         // success green
  static const Color syncFailed = Color(0xFFC44B46);     // danger red
  static const Color savedLocally = Color(0xFF1B6B9E);   // info blue
}
