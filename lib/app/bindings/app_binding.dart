import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../core/database/app_database.dart';
import '../../core/network/connectivity_service.dart';
import '../../core/services/locale_service.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/theme_service.dart';
import '../../core/sync/services/sync_service.dart';
import '../../features/auth/services/auth_service.dart';

/// Root application binding.
/// Core services are registered in [initServices] before [runApp].
class AppBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<ThemeService>()) {
      Get.put<ThemeService>(ThemeService(), permanent: true);
    }
    if (!Get.isRegistered<LocaleService>()) {
      Get.put<LocaleService>(LocaleService(), permanent: true);
    }
    if (!Get.isRegistered<DatabaseService>()) {
      Get.put<DatabaseService>(DatabaseService(), permanent: true);
    }
    if (!Get.isRegistered<ConnectivityService>()) {
      Get.put<ConnectivityService>(ConnectivityService(), permanent: true);
    }
    if (!Get.isRegistered<SupabaseService>()) {
      Get.put<SupabaseService>(SupabaseService(), permanent: true);
    }
    if (!Get.isRegistered<AuthService>()) {
      Get.put<AuthService>(AuthService(), permanent: true);
    }
    if (!Get.isRegistered<SyncService>()) {
      Get.put<SyncService>(SyncService(), permanent: true);
    }
  }
}

/// Initialises services before [runApp].
/// Call this once from [main] before the app widget tree is built.
Future<void> initServices() async {
  await GetStorage.init();
  Get.put<ThemeService>(ThemeService(), permanent: true);
  Get.put<LocaleService>(LocaleService(), permanent: true);
  // Open database and attach DAO.
  final dbSvc = Get.put<DatabaseService>(DatabaseService(), permanent: true);
  final db = await AppDatabase.open();
  dbSvc.attach(db);

  // Cloud sync & connectivity services
  Get.put<ConnectivityService>(ConnectivityService(), permanent: true);
  Get.put<SupabaseService>(SupabaseService(), permanent: true);
  Get.put<AuthService>(AuthService(), permanent: true);
  Get.put<SyncService>(SyncService(), permanent: true);
}
