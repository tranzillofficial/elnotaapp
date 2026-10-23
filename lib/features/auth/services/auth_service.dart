import 'package:flutter/foundation.dart';
import '../../../core/database/app_database.dart';
import '../../../core/sync/services/sync_service.dart';
import 'package:get/get.dart';
import '../../../core/services/supabase_service.dart';
import '../models/user_session.dart';
import '../../../core/utils/app_runtime.dart';

class AuthService extends GetxService {
  static AuthService get to => Get.find<AuthService>();

  final Rx<UserSession?> currentSession = Rx<UserSession?>(null);
  final RxBool isLoading = false.obs;

  bool get isAuthenticated => currentSession.value != null;
  String get activeWorkspaceId =>
      currentSession.value?.workspaceId ?? 'default';

  @override
  void onInit() {
    super.onInit();
    _restoreLocalSession();
  }

  void _restoreLocalSession() {
    if (AppRuntime.demo) {
      currentSession.value = const UserSession(
        userId: 'demo',
        email: 'demo@elnota.local',
        workspaceId: 'default',
        workspaceName: 'النوتة — حساب ديمو',
      );
      return;
    }
    final user = Get.isRegistered<SupabaseService>()
        ? SupabaseService.to.client?.auth.currentUser
        : null;
    if (user != null) {
      currentSession.value = UserSession(
        userId: user.id,
        email: user.email ?? '',
        workspaceId: user.appMetadata['workspace_id'] as String? ?? user.id,
        workspaceName:
            user.userMetadata?['workspace_name'] as String? ?? 'النوتة',
      );
      return;
    }
    if (kIsWeb) {
      currentSession.value = null;
      return;
    }
    // Default local workspace for offline-first accounting
    currentSession.value = const UserSession(
      userId: 'local_user',
      email: 'merchant@elnota.local',
      workspaceId: 'default',
      workspaceName: 'النوتة - محلي',
      role: 'owner',
    );
  }

  Future<void> acceptServerSession() async {
    if (AppRuntime.demo) {
      throw StateError('الديمو لا يدعم الدخول إلى حساب حقيقي');
    }
    final user = SupabaseService.to.client?.auth.currentUser;
    if (user == null) throw StateError('Authenticated session required');
    if (Get.isRegistered<DatabaseService>()) {
      if (Get.isRegistered<SyncService>()) {
        await Get.delete<SyncService>(force: true);
      }
      await DatabaseService.to.switchAccount(user.id);
      Get.put<SyncService>(SyncService(), permanent: true);
    }
    _restoreLocalSession();
  }

  Future<bool> signIn({required String email, required String password}) async {
    if (AppRuntime.demo) return false;
    isLoading.value = true;
    try {
      final supa = SupabaseService.to;
      if (supa.isInitialized && supa.client != null) {
        final res = await supa.client!.auth.signInWithPassword(
          email: email,
          password: password,
        );
        final user = res.user;
        if (user != null) {
          await acceptServerSession();
          return true;
        }
      }
      return false;
    } catch (_) {
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String storeName,
  }) async {
    if (AppRuntime.demo) return false;
    isLoading.value = true;
    try {
      final supa = SupabaseService.to;
      if (supa.isInitialized && supa.client != null) {
        final res = await supa.client!.auth.signUp(
          email: email,
          password: password,
          data: {'workspace_name': storeName},
        );
        final user = res.user;
        if (user != null) {
          if (res.session == null) return false;
          await acceptServerSession();
          return true;
        }
      }
      return false;
    } catch (_) {
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signOut() async {
    if (AppRuntime.demo) return;
    isLoading.value = true;
    try {
      final supa = SupabaseService.to;
      if (supa.isInitialized && supa.client != null) {
        await supa.client!.auth.signOut();
      }
      await supa.clearSecureSession();
      if (Get.isRegistered<DatabaseService>()) {
        if (Get.isRegistered<SyncService>()) {
          await Get.delete<SyncService>(force: true);
        }
        await DatabaseService.to.switchAccount(null);
        Get.put<SyncService>(SyncService(), permanent: true);
      }
      _restoreLocalSession();
    } finally {
      isLoading.value = false;
    }
  }
}
