import 'dart:async';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'supabase_service.dart';

class AccountAccess {
  const AccountAccess({
    this.active = false,
    this.cloudUntil,
    this.catalogOverride = false,
  });
  final bool active, catalogOverride;
  final DateTime? cloudUntil;
  bool cloudAt(DateTime now) =>
      active && cloudUntil != null && cloudUntil!.isAfter(now);
  bool catalogAt(DateTime now) => active && (cloudAt(now) || catalogOverride);
  factory AccountAccess.fromMap(Map<String, dynamic> row) => AccountAccess(
    active:
        row['activated_at'] != null &&
        row['suspended_at'] == null &&
        row['deleted_at'] == null,
    cloudUntil: DateTime.tryParse(row['cloud_until'] as String? ?? ''),
    catalogOverride: row['catalog_enabled'] == true,
  );
}

class AccountAccessService extends GetxService {
  AccountAccessService({this.automaticallyRefresh = true});
  final bool automaticallyRefresh;
  static AccountAccessService get to => Get.find();
  final access = const AccountAccess().obs;
  final loading = false.obs;
  final onlineVerified = false.obs;
  Timer? _timer;
  StreamSubscription<dynamic>? _auth;
  bool get cloudEnabled => access.value.cloudAt(DateTime.now());
  bool get catalogEnabled => access.value.catalogAt(DateTime.now());
  String? get _uid => SupabaseService.to.client?.auth.currentUser?.id;
  @override
  void onInit() {
    super.onInit();
    if (!automaticallyRefresh) return;
    _auth = SupabaseService.to.client?.auth.onAuthStateChange.listen((_) {
      refreshAccess();
    });
    refreshAccess();
    _timer = Timer.periodic(const Duration(minutes: 5), (_) => refreshAccess());
  }

  Future<void> refreshAccess() async {
    final uid = _uid;
    onlineVerified.value = false;
    if (uid == null) {
      access.value = const AccountAccess();
      return;
    }
    final cached = GetStorage().read<Map>('access:$uid');
    access.value = cached == null
        ? const AccountAccess()
        : AccountAccess.fromMap(Map<String, dynamic>.from(cached));
    if (loading.value) return;
    loading.value = true;
    try {
      final client = SupabaseService.to.client!;
      final row = await client
          .from('elnota_accounts')
          .select('activated_at,cloud_until,suspended_at,deleted_at')
          .eq('user_id', uid)
          .maybeSingle();
      bool override = false;
      try {
        final feature = await client
            .from('elnota_feature_access')
            .select('catalog_enabled')
            .eq('user_id', uid)
            .maybeSingle();
        override = feature?['catalog_enabled'] == true;
      } catch (_) {
        /* Older backend has no override contract. Deny the override. */
      }
      if (_uid != uid) return;
      final values = <String, dynamic>{...?row, 'catalog_enabled': override};
      access.value = AccountAccess.fromMap(values);
      onlineVerified.value = true;
      await GetStorage().write('access:$uid', values);
    } catch (_) {
      /* Keep this account's last verified entitlement for offline work. */
    } finally {
      loading.value = false;
    }
  }

  @override
  void onClose() {
    _timer?.cancel();
    _auth?.cancel();
    super.onClose();
  }
}
