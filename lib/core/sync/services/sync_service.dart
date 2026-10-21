import 'dart:async';
import 'package:get/get.dart';
import '../../database/app_database.dart';
import '../../database/database_impl.dart';
import '../models/sync_operation.dart';

/// Local observability while the web/Flutter contracts are being aligned.
/// The old implementation addressed non-existent sync_inbox/outbox_events
/// tables and advanced a cursor without applying records. It was not sync.
/// A reviewed transport and financial reconciliation are required before any
/// cloud writes can be enabled. Pending operations are never acknowledged here.
class SyncService extends GetxService {
  static SyncService get to => Get.find<SyncService>();
  SyncService({AppDao? dao}) : _dao = dao ?? DatabaseService.to.dao;
  final AppDao _dao;
  final Rx<SyncSummary> summary = const SyncSummary(pendingCount: 0).obs;
  StreamSubscription<int>? _pendingCountSub;

  bool get supportsCloudSync => false;

  @override
  void onInit() {
    super.onInit();
    _pendingCountSub = _dao.watchPendingOutboxCount().listen((count) {
      summary.value = SyncSummary(
        pendingCount: count,
        lastSuccessAt: summary.value.lastSuccessAt,
        lastError: summary.value.lastError,
      );
    });
  }

  Future<bool> syncNow() async {
    summary.value = SyncSummary(
      pendingCount: summary.value.pendingCount,
      lastSuccessAt: summary.value.lastSuccessAt,
      lastError: 'البيانات محفوظة على الجهاز. ربط المزامنة بين Flutter والموقع لم يُفعّل بعد.',
    );
    return false;
  }

  Future<bool> pushPendingOutbox({int batchSize = 50}) => syncNow();
  Future<bool> pullRemoteChanges() => syncNow();

  @override
  void onClose() {
    _pendingCountSub?.cancel();
    super.onClose();
  }
}
