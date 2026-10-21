import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../database/app_database.dart';
import '../database/database_impl.dart';

class BackupService {
  BackupService({AppDao? dao}) : _dao = dao ?? DatabaseService.to.dao;

  final AppDao _dao;

  /// Creates a complete JSON snapshot map of local accounting tables.
  Future<Map<String, dynamic>> createSnapshot() async {
    final customers = await _dao.watchCustomers().first;
    final customersData = customers.map((c) => {
      'id': c.id,
      'workspace_id': c.workspaceId,
      'name': c.name,
      'phone': c.phone,
      'notes': c.notes,
      'version': c.version,
      'created_at': c.createdAt.millisecondsSinceEpoch,
      'updated_at': c.updatedAt.millisecondsSinceEpoch,
    }).toList();

    return {
      'schema_version': 1,
      'exported_at': DateTime.now().toIso8601String(),
      'customers': customersData,
    };
  }

  /// Exports snapshot to a JSON file and opens share sheet.
  Future<void> exportAndShareBackup() async {
    final snapshot = await createSnapshot();
    final jsonStr = jsonEncode(snapshot);

    final now = DateTime.now();
    final fileName =
        'elnota_backup_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}.json';

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsString(jsonStr);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: 'ElNota Accounting Backup',
      ),
    );
  }
}
