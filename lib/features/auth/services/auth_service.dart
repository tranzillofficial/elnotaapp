import 'package:get/get.dart';
import '../../../core/services/supabase_service.dart';
import '../models/user_session.dart';

class AuthService extends GetxService {
  static AuthService get to => Get.find<AuthService>();

  final Rx<UserSession?> currentSession = Rx<UserSession?>(null);
  final RxBool isLoading = false.obs;

  bool get isAuthenticated => currentSession.value != null;
  String get activeWorkspaceId => currentSession.value?.workspaceId ?? 'default';

  @override
  void onInit() {
    super.onInit();
    _restoreLocalSession();
  }

  void _restoreLocalSession() {
    // Default local workspace for offline-first accounting
    currentSession.value = const UserSession(
      userId: 'local_user',
      email: 'merchant@elnota.local',
      workspaceId: 'default',
      workspaceName: 'النوتة - محلي',
      role: 'owner',
    );
  }

  Future<bool> signIn({required String email, required String password}) async {
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
          final wsId = (user.userMetadata?['workspace_id'] as String?) ?? 'default';
          currentSession.value = UserSession(
            userId: user.id,
            email: user.email ?? email,
            workspaceId: wsId,
            workspaceName: (user.userMetadata?['workspace_name'] as String?) ?? 'متجري',
          );
          if (res.session?.accessToken != null) {
            await supa.saveSecureToken(res.session!.accessToken);
          }
          return true;
        }
      } else {
        // Local mode fallback
        currentSession.value = UserSession(
          userId: 'local_${email.hashCode}',
          email: email,
          workspaceId: 'default',
          workspaceName: 'المتجر الرئيسي',
        );
        return true;
      }
      return false;
    } catch (_) {
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> signUp({required String email, required String password, required String storeName}) async {
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
          final wsId = (user.userMetadata?['workspace_id'] as String?) ?? 'default';
          currentSession.value = UserSession(
            userId: user.id,
            email: user.email ?? email,
            workspaceId: wsId,
            workspaceName: storeName,
          );
          return true;
        }
      } else {
        currentSession.value = UserSession(
          userId: 'local_${email.hashCode}',
          email: email,
          workspaceId: 'default',
          workspaceName: storeName,
        );
        return true;
      }
      return false;
    } catch (_) {
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signOut() async {
    isLoading.value = true;
    try {
      final supa = SupabaseService.to;
      if (supa.isInitialized && supa.client != null) {
        await supa.client!.auth.signOut();
      }
      await supa.clearSecureSession();
      _restoreLocalSession();
    } finally {
      isLoading.value = false;
    }
  }
}
