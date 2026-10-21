import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'web_import_preview.dart';

/// Local preflight storage only. Deliberately cannot write to domain tables,
/// activate accounts, upload snapshots or mark outbox operations acknowledged.
class WebCompatibilityRepository {
  WebCompatibilityRepository(this._db);
  final GeneratedDatabase _db;

  WebImportPreview preview(dynamic input) => WebImportPreview.inspect(input);

  Future<String> stage({required String sourceUserId, required dynamic input,
      int? sourceRevision}) async {
    if (sourceUserId.trim().isEmpty || (sourceRevision != null && sourceRevision < 0)) {
      throw const FormatException('مصدر النسخة غير صالح');
    }
    final result = preview(input);
    final id = const Uuid().v4();
    await _db.customStatement('''INSERT INTO web_document_staging
      (id,source_user_id,workspace_id,document_json,validation_json,source_revision,created_at)
      VALUES (?,?,?,?,?,?,?)''', [id, sourceUserId, 'staging:$sourceUserId',
      result.originalJson, jsonEncode(result.report), sourceRevision,
      DateTime.now().millisecondsSinceEpoch]);
    return id;
  }

  Future<WebImportPreview?> readStaged({required String id, required String sourceUserId}) async {
    final rows = await _db.customSelect(
      'SELECT document_json FROM web_document_staging WHERE id=? AND source_user_id=?',
      variables: [Variable.withString(id), Variable.withString(sourceUserId)],
    ).get();
    return rows.isEmpty ? null : preview(jsonDecode(rows.single.read<String>('document_json')));
  }
}
