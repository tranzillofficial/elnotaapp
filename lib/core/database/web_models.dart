import 'dart:convert';
import 'web_contract.dart';

/// Lossless server DTO. No mutating API is exposed by this model layer.
class WebRecord {
  WebRecord(Map<String, dynamic> json)
    : _json = jsonDecode(jsonEncode(json)) as Map<String, dynamic>;
  final Map<String, dynamic> _json;
  String get id => (_json['id'] ?? _json['user_id']) as String;
  String get userId => _json['user_id'] as String;
  Map<String, dynamic> toJson() => jsonDecode(jsonEncode(_json)) as Map<String, dynamic>;
  String? text(String key) => _json[key] as String?;
  DateTime? time(String key) => text(key) == null ? null : DateTime.parse(text(key)!);
}

class WebAccount extends WebRecord {
  WebAccount(super.json);
  String get email => text('email')!;
  String get businessName => text('business_name') ?? '';
  DateTime? get activatedAt => time('activated_at');
  DateTime? get cloudUntil => time('cloud_until');
  String? get cloudPlan => text('cloud_plan');
  bool get printingEnabled => _json['printing_enabled'] == true;
  bool get suspended => _json['suspended_at'] != null;
  bool get deleted => _json['deleted_at'] != null;
  bool get canWrite => activatedAt != null && !suspended && !deleted;
  bool cloudActiveAt(DateTime now) => canWrite && cloudUntil != null && cloudUntil!.isAfter(now);
}

class WebActivationRequest extends WebRecord {
  WebActivationRequest(super.json);
  String get plan => text('plan')!;
  String get status => text('status')!;
  String? get submittedEmail => text('submitted_email');
  String? get submittedBusinessName => text('submitted_business_name');

  /// Computed amount and stamped sender/reviewer are server-owned fields.
  static Map<String, dynamic> pending({required String userId, required String plan,
      required String phone, required String reference}) {
    if (!ElnotaWebContract.plans.contains(plan) || phone.length < 7 || phone.length > 30 ||
        reference.length < 3 || reference.length > 500) {
      throw const FormatException('طلب تفعيل غير صالح');
    }
    return {'user_id': userId, 'plan': plan, 'phone': phone,
      'reference': reference, 'status': 'pending'};
  }
}

class WebCloudSnapshot extends WebRecord {
  WebCloudSnapshot(super.json);
  int get revision => (_json['revision'] as num).toInt();
  Map<String, dynamic> get data => Map<String, dynamic>.from(_json['data'] as Map);
}

class WebDeviceBackup extends WebRecord {
  WebDeviceBackup(super.json);
  String get deviceId => text('device_id')!;
  String get backupDay => text('backup_day')!;
  DateTime get capturedAt => time('captured_at')!;
  DateTime? get uploadedAt => time('uploaded_at');
  int? get sizeBytes => (_json['size_bytes'] as num?)?.toInt();
}

class WebCatalogImport extends WebRecord {
  WebCatalogImport(super.json);
  Map<String, dynamic> get payload => Map<String, dynamic>.from(_json['payload'] as Map);
}
