import 'package:get/get.dart';
import '../../../core/services/theme_service.dart';
import '../../../core/services/locale_service.dart';
import '../../../core/utils/app_constants.dart';

/// Controller for the Settings screen.
/// Delegates to [ThemeService] and [LocaleService]; no direct storage access.
class SettingsController extends GetxController {
  static SettingsController get to => Get.find<SettingsController>();

  ThemeService get _theme => ThemeService.to;
  LocaleService get _locale => LocaleService.to;

  // ── Observables ─────────────────────────────────────────────────────────────
  bool get isDark => _theme.isDark;
  bool get isArabic => _locale.isArabic;

  String get appVersion => AppConstants.appVersion;

  String get themeModeLabel {
    return switch (_theme.mode.name) {
      'light' => 'settings_theme_light'.tr,
      'dark' => 'settings_theme_dark'.tr,
      _ => 'settings_theme_system'.tr,
    };
  }

  String get localeLabel => isArabic ? 'العربية' : 'English';

  // ── Actions ──────────────────────────────────────────────────────────────────
  void onThemeLightTapped() => _theme.setLight();
  void onThemeDarkTapped() => _theme.setDark();
  void onThemeSystemTapped() => _theme.setSystem();
  void onToggleTheme() => _theme.toggle();

  void onLanguageToggled() => _locale.toggleLocale();
  void onArabicSelected() => _locale.setArabic();
  void onEnglishSelected() => _locale.setEnglish();
}
