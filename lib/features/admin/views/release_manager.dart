import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/utils/app_runtime.dart';
import '../../../core/widgets/design_widgets.dart';
import '../repositories/admin_repository.dart';

class ReleaseManager extends StatefulWidget {
  const ReleaseManager({super.key});
  @override
  State<ReleaseManager> createState() => _ReleaseManagerState();
}

class _ReleaseManagerState extends State<ReleaseManager> {
  final version = TextEditingController();
  final url = TextEditingController();
  final notes = TextEditingController();
  String platform = 'android';
  bool store = false;
  bool busy = false;
  String? message;
  PlatformFile? file;
  String? supportUrl;

  Future<void> uploadSupport() async {
    if (busy || AppRuntime.demo) return;
    setState(() {
      busy = true;
      message = null;
    });
    try {
      if (!await AdminRepository().isAdmin()) {
        throw StateError('Admin required');
      }
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );
      if (files.isEmpty) return;
      final selected = files.single;
      final size = await selected.length();
      if (selected.extension?.toLowerCase() != 'zip' ||
          size == null ||
          size == 0 ||
          size > 50 * 1024 * 1024) {
        throw StateError('Invalid file');
      }
      final client = SupabaseService.to.client!;
      final path =
          'windows/${DateTime.now().microsecondsSinceEpoch}/elnota-support.zip';
      await client.storage
          .from('elnota-app-releases')
          .uploadBinary(path, await selected.readAsBytes());
      if (mounted) {
        setState(
          () => supportUrl = client.storage
              .from('elnota-app-releases')
              .getPublicUrl(path),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => message =
              'تعذر رفع الملفات المساعدة. استخدم ZIP بحد أقصى 50 ميجابايت.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    version.dispose();
    url.dispose();
    notes.dispose();
    super.dispose();
  }

  Future<void> publish() async {
    if (busy) return;
    if (!RegExp(
      r'^\d+\.\d+\.\d+(?:[-+][a-zA-Z0-9.-]+)?$',
    ).hasMatch(version.text.trim())) {
      setState(() => message = 'اكتب رقم إصدار مثل 1.0.1');
      return;
    }
    final uri = Uri.tryParse(url.text.trim());
    if (store &&
        (uri == null ||
            uri.scheme != 'https' ||
            (platform == 'android'
                ? uri.host != 'play.google.com' ||
                      uri.path != '/store/apps/details' ||
                      !uri.queryParameters.containsKey('id')
                : uri.host != 'apps.apple.com'))) {
      setState(() => message = 'أدخل رابط التطبيق الرسمي في المتجر');
      return;
    }
    if (!store &&
        (file == null ||
            (await file!.length() ?? 0) == 0 ||
            (await file!.length() ?? 0) > 50 * 1024 * 1024)) {
      setState(() => message = 'اختر ملفًا صالحًا بحد أقصى 50 ميجابايت');
      return;
    }
    setState(() {
      busy = true;
      message = null;
    });
    try {
      if (AppRuntime.demo || !await AdminRepository().isAdmin()) {
        throw StateError('صلاحية الإدارة مطلوبة');
      }
      final client = SupabaseService.to.client!;
      var download = url.text.trim();
      if (!store) {
        final extension = file!.extension?.toLowerCase();
        if (!(platform == 'android' ? ['apk'] : ['exe', 'msi', 'zip']).contains(
          extension,
        )) {
          throw StateError('نوع الملف غير مناسب للمنصة');
        }
        final path =
            '$platform/${DateTime.now().microsecondsSinceEpoch}/elnota-${version.text.trim()}.$extension';
        await client.storage
            .from('elnota-app-releases')
            .uploadBinary(path, await file!.readAsBytes());
        download = client.storage
            .from('elnota-app-releases')
            .getPublicUrl(path);
      }
      await client.rpc(
        'elnota_publish_release',
        params: {
          'p_platform': platform,
          'p_version': version.text.trim(),
          'p_distribution': store ? 'store' : 'file',
          'p_url': download,
          'p_notes': notes.text.trim(),
        },
      );
      if (mounted) {
        setState(
          () => message = 'تم نشر الإصدار. يظهر رابط التحميل خلال دقيقة.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => message =
              'تعذر نشر الإصدار. تأكد من صلاحيات الإدارة وتفعيل مخزن الإصدارات. يمكنك إعادة المحاولة؛ لم يتم تعديل بيانات العملاء.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => DesignPanel(
    title: 'الإصدارات والتحميلات',
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'ارفع APK لأندرويد أو مثبّت Windows. يمكن التحويل لرابط المتجر عند توفره. الملفات المنشورة متاحة للجميع؛ لا ترفع مفاتيح توقيع أو ملفات إعدادات خاصة.',
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: platform,
            decoration: const InputDecoration(labelText: 'المنصة'),
            items: const [
              DropdownMenuItem(value: 'android', child: Text('Android')),
              DropdownMenuItem(value: 'windows', child: Text('Windows 64-bit')),
              DropdownMenuItem(value: 'ios', child: Text('iOS')),
            ],
            onChanged: busy
                ? null
                : (value) => setState(() {
                    platform = value!;
                    file = null;
                    store = platform == 'ios';
                  }),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: version,
            enabled: !busy,
            decoration: const InputDecoration(
              labelText: 'رقم الإصدار',
              hintText: '1.0.1',
            ),
          ),
          if (platform != 'windows')
            SwitchListTile(
              title: const Text('استخدام رابط المتجر بدل الملف'),
              value: store,
              onChanged: busy || platform == 'ios'
                  ? null
                  : (value) => setState(() {
                      store = value;
                      file = null;
                    }),
            ),
          if (store)
            TextField(
              controller: url,
              enabled: !busy,
              decoration: const InputDecoration(
                labelText: 'رابط Google Play أو App Store',
              ),
            )
          else
            OutlinedButton.icon(
              onPressed: busy
                  ? null
                  : () async {
                      final result = await FilePicker.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: platform == 'android'
                            ? ['apk']
                            : ['exe', 'msi', 'zip'],
                      );
                      if (mounted && result.isNotEmpty) {
                        setState(() => file = result.single);
                      }
                    },
              icon: const Icon(Icons.upload_file),
              label: Text(file?.name ?? 'اختيار ملف الإصدار (حتى 50 ميجابايت)'),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: notes,
            enabled: !busy,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'ملاحظات الإصدار'),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: busy ? null : publish,
            icon: const Icon(Icons.publish),
            label: Text(
              busy ? 'جارٍ الرفع والنشر…' : 'نشر الإصدار في صفحة التحميلات',
            ),
          ),
          if (message != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(message!),
            ),
          const Divider(height: 32),
          OutlinedButton.icon(
            onPressed: busy ? null : uploadSupport,
            icon: const Icon(Icons.folder_zip_outlined),
            label: const Text('رفع ملفات مساعدة ZIP (حتى 50 ميجابايت)'),
          ),
          if (supportUrl != null)
            SelectableText('رابط الملفات المساعدة: $supportUrl'),
        ],
      ),
    ),
  );
}
