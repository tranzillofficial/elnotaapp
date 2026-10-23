import 'dart:convert';
import 'dart:typed_data';
import 'package:share_plus/share_plus.dart';
import '../database/app_database.dart';
import '../database/database_impl.dart';
import 'account_access_service.dart';

class BackupService {
  BackupService({AppDao? dao}) : _dao = dao ?? DatabaseService.to.dao;
  final AppDao _dao;
  Future<Map<String, dynamic>> createSnapshot() => _dao.exportLocalSnapshot();
  Future<void> exportAndShareBackup() async {
    if (!AccountAccessService.to.cloudEnabled) {
      throw StateError('النسخ الاحتياطي متاح لاشتراك الكلاود فقط');
    }
    final snapshot = await createSnapshot();
    final filename =
        'elnota_backup_${DateTime.now().toIso8601String().substring(0, 10)}.json';
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode(snapshot)));
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(bytes, mimeType: 'application/json', name: filename),
        ],
        fileNameOverrides: [filename],
        subject: 'ElNota Local Backup',
      ),
    );
  }
}
