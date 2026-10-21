import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/network/connectivity_service.dart';
import '../../../core/services/locale_service.dart';
import '../../../core/services/theme_service.dart';
import '../../../core/sync/services/sync_service.dart';
import '../../../core/utils/app_constants.dart';
import '../../../core/utils/app_routes.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../auth/services/auth_service.dart';
import '../controllers/settings_controller.dart';

/// Settings screen.
/// Groups: Appearance (theme + language), About.
/// Phase 3 will add Account, Business, Backup & Sync, and Security groups.
class SettingsView extends GetView<SettingsController> {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('settings_title'.tr)),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // ── Appearance ─────────────────────────────────────────────────────
          SectionHeader(title: 'settings_appearance'.tr),
          _ThemeSelector(),
          const SizedBox(height: 4),
          _LanguageSelector(),

          // ── Cloud & Sync ───────────────────────────────────────────────────
          const SectionHeader(title: 'السحابة والمزامنة'),
          const _SyncSettingsCard(),

          // ── About ──────────────────────────────────────────────────────────
          SectionHeader(title: 'settings_about'.tr),
          _AboutTile(),
        ],
      ),
    );
  }
}

// ─── Theme selector ───────────────────────────────────────────────────────────

class _ThemeSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final svc = ThemeService.to;
      return Card(
        child: RadioGroup<String>(
          groupValue: svc.mode.name,
          onChanged: (val) {
            if (val == 'light') svc.setLight();
            if (val == 'dark') svc.setDark();
            if (val == 'system') svc.setSystem();
          },
          child: Column(
            children: [
              _SettingsTile(
                icon: Icons.light_mode_outlined,
                title: 'settings_theme_light'.tr,
                trailing: const Radio<String>(value: 'light'),
                onTap: svc.setLight,
              ),
              const Divider(height: 1, indent: 56),
              _SettingsTile(
                icon: Icons.dark_mode_outlined,
                title: 'settings_theme_dark'.tr,
                trailing: const Radio<String>(value: 'dark'),
                onTap: svc.setDark,
              ),
              const Divider(height: 1, indent: 56),
              _SettingsTile(
                icon: Icons.brightness_auto_outlined,
                title: 'settings_theme_system'.tr,
                trailing: const Radio<String>(value: 'system'),
                onTap: svc.setSystem,
              ),
            ],
          ),
        ),
      );
    });
  }
}

// ─── Language selector ────────────────────────────────────────────────────────

class _LanguageSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final svc = LocaleService.to;
      return Card(
        child: RadioGroup<String>(
          groupValue: svc.locale.languageCode,
          onChanged: (val) {
            if (val == AppConstants.localeAr) svc.setArabic();
            if (val == AppConstants.localeEn) svc.setEnglish();
          },
          child: Column(
            children: [
              _SettingsTile(
                icon: Icons.language_rounded,
                title: 'العربية',
                trailing: const Radio<String>(value: AppConstants.localeAr),
                onTap: svc.setArabic,
              ),
              const Divider(height: 1, indent: 56),
              _SettingsTile(
                icon: Icons.language_rounded,
                title: 'English',
                trailing: const Radio<String>(value: AppConstants.localeEn),
                onTap: svc.setEnglish,
              ),
            ],
          ),
        ),
      );
    });
  }
}

// ─── About tile ───────────────────────────────────────────────────────────────

class _AboutTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: _SettingsTile(
        icon: Icons.info_outline_rounded,
        title: AppConstants.appName,
        subtitle:
            '${'settings_version'.tr} ${AppConstants.appVersion}',
        onTap: () {},
      ),
    );
  }
}

// ─── Reusable tile ────────────────────────────────────────────────────────────

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, size: 20),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: trailing,
      onTap: onTap,
      dense: true,
    );
  }
}

class _SyncSettingsCard extends StatelessWidget {
  const _SyncSettingsCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = Get.isRegistered<AuthService>() ? AuthService.to : null;
    final sync = Get.isRegistered<SyncService>() ? SyncService.to : null;
    final conn = Get.isRegistered<ConnectivityService>()
        ? ConnectivityService.to
        : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User / Workspace row
            Obx(() {
              final user = auth?.currentSession.value;
              return Row(
                children: [
                  CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(
                      Icons.storefront_rounded,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.workspaceName ?? 'المتجر الرئيسي',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          user?.email ?? 'merchant@elnota.local',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.swap_horiz_rounded),
                    label: Text('auth_logout'.tr.isNotEmpty ? 'auth_logout'.tr : 'تبديل'),
                    onPressed: () => Get.toNamed(AppRoutes.login),
                  ),
                ],
              );
            }),
            const Divider(height: 24),

            // Sync Status
            Obx(() {
              final isOnline = conn?.isOnline.value ?? false;
              final summary = sync?.summary.value;
              final pending = summary?.pendingCount ?? 0;
              final isSyncing = summary?.isSyncing ?? false;

              return Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isOnline ? Icons.wifi : Icons.wifi_off,
                            size: 16,
                            color: isOnline ? Colors.green : Colors.orange,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isOnline ? 'متصل بالإنترنت' : 'غير متصل (يعمل محليًا)',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                      Text(
                        pending > 0
                            ? '$pending قيد المزامنة'
                            : 'جميع العمليات متزامنة',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: pending > 0 ? Colors.orange[800] : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: isSyncing
                        ? null
                        : () async {
                            final ok = await sync?.syncNow();
                            if (ok == true) {
                              showSuccessSnack('تمت المزامنة بنجاح');
                            } else {
                              showErrorSnack('تعذرت المزامنة — تم حفظ العمليات محليًا');
                            }
                          },
                    icon: isSyncing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.sync_rounded),
                    label: Text(isSyncing ? 'جارٍ المزامنة…' : 'مزامنة فورية الآن'),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}
