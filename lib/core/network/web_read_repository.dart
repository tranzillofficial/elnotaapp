import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/web_contract.dart';
import '../database/web_models.dart';

/// Optional, explicitly constructed read adapter for a later integration.
/// Nothing registers or calls this adapter during application startup.
/// It has no INSERT/UPDATE/DELETE/RPC write path.
class WebReadRepository {
  WebReadRepository(this._client);
  final SupabaseClient _client;

  String get _userId {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('سجّل الدخول لقراءة بيانات حسابك');
    return user.id;
  }

  Future<WebAccount?> account() async {
    final json = await _client.from(ElnotaWebContract.accounts).select()
        .eq('user_id', _userId).maybeSingle();
    return json == null ? null : WebAccount(json);
  }

  Future<WebCloudSnapshot?> cloudSnapshot() async {
    final json = await _client.from(ElnotaWebContract.cloud).select()
        .eq('user_id', _userId).maybeSingle();
    return json == null ? null : WebCloudSnapshot(json);
  }

  Future<List<WebActivationRequest>> requests({int offset = 0, int limit = 50}) async {
    _checkPage(offset, limit);
    final rows = await _client.from(ElnotaWebContract.requests).select()
        .eq('user_id', _userId).order('created_at').order('id').range(offset, offset + limit - 1);
    return rows.map(WebActivationRequest.new).toList();
  }

  Future<List<WebCatalogImport>> catalogImports({int offset = 0, int limit = 50}) async {
    _checkPage(offset, limit);
    final rows = await _client.from(ElnotaWebContract.catalogImports).select()
        .eq('user_id', _userId).order('created_at').order('id').range(offset, offset + limit - 1);
    return rows.map(WebCatalogImport.new).toList();
  }

  void _checkPage(int offset, int limit) {
    if (offset < 0 || limit < 1 || limit > 100) throw ArgumentError('Invalid page');
  }
}
