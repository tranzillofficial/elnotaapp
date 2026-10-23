import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/widgets/design_widgets.dart';
import '../../../core/utils/app_routes.dart';
import '../controllers/admin_controller.dart';
import '../repositories/admin_repository.dart';

class AdminDashboardView extends StatefulWidget {
  const AdminDashboardView({super.key});
  @override
  State<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<AdminDashboardView> {
  late final AdminController ctrl = Get.put(AdminController(AdminRepository()));
  int tab = 0;
  String search = '';
  Future<bool> confirm(String title, String message) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('تأكيد'),
            ),
          ],
        ),
      ) ??
      false;
  @override
  void dispose() {
    Get.delete<AdminController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final body = Obx(() {
      if (ctrl.loading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (!ctrl.allowed.value) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.admin_panel_settings_outlined, size: 42),
              const SizedBox(height: 16),
              Text(
                ctrl.error.value ?? 'هذه اللوحة متاحة للمسؤولين المعتمدين فقط',
              ),
              TextButton(
                onPressed: ctrl.refreshData,
                child: const Text('إعادة التحقق'),
              ),
              TextButton(
                onPressed: () => Get.toNamed(AppRoutes.login),
                child: const Text('تسجيل الدخول'),
              ),
            ],
          ),
        );
      }
      final accounts = ctrl.accountRows
          .where(
            (a) => '${a['email']} ${a['business_name']}'.toLowerCase().contains(
              search.toLowerCase(),
            ),
          )
          .toList();
      return ListView(
        padding: EdgeInsets.all(
          MediaQuery.sizeOf(context).width < 600 ? 16 : 32,
        ),
        children: [
          DesignHeader(
            title: 'لوحة الإدارة',
            subtitle: 'الحسابات وطلبات التفعيل والاشتراكات',
            actions: [DesignAction('تحديث', Icons.refresh, ctrl.refreshData)],
          ),
          DesignPanel(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 16,
                runSpacing: 12,
                children: [
                  DesignPill(
                    AdminRepository.writesEnabled
                        ? 'إجراءات بتأكيد المسؤول'
                        : 'وضع القراءة فقط',
                  ),
                  const Text(
                    'لا تتضمن هذه اللوحة حذف الحسابات أو تعديل دفاتر العملاء.',
                    style: TextStyle(color: designMuted),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          DesignStats(
            children: [
              DesignStat(
                'الحسابات المعروضة',
                '${ctrl.accountRows.length}',
                Icons.people_outline,
              ),
              DesignStat(
                'المفعّلة في الصفحة',
                '${ctrl.accountRows.where((a) => a['activated_at'] != null && a['deleted_at'] == null && a['suspended_at'] == null).length}',
                Icons.verified_outlined,
              ),
              DesignStat(
                'طلبات معلقة في الصفحة',
                '${ctrl.requestRows.length}',
                Icons.pending_actions,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 20,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 0, label: Text('الحسابات')),
                  ButtonSegment(value: 1, label: Text('طلبات التفعيل')),
                ],
                selected: {tab},
                showSelectedIcon: false,
                onSelectionChanged: (v) => setState(() => tab = v.first),
              ),
              SizedBox(
                width: 340,
                child: TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'ابحث بالبريد أو اسم النشاط',
                  ),
                  onChanged: (v) => setState(() => search = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (ctrl.error.value != null)
            Text(ctrl.error.value!, style: const TextStyle(color: Colors.red)),
          DesignPanel(
            child: tab == 0
                ? DesignTable(
                    minWidth: 1050,
                    rowHeight: 62,
                    headers: const [
                      'النشاط',
                      'البريد',
                      'الحساب',
                      'السحابة حتى',
                      'الطباعة',
                      'الإجراءات',
                    ],
                    rows: accounts.map((a) {
                      final active =
                          a['activated_at'] != null &&
                          a['suspended_at'] == null &&
                          a['deleted_at'] == null;
                      return <Widget>[
                        Text(
                          '${a['business_name']}'.isEmpty
                              ? '—'
                              : '${a['business_name']}',
                        ),
                        Text('${a['email']}'),
                        DesignPill(
                          a['deleted_at'] != null
                              ? 'مؤرشف'
                              : a['suspended_at'] != null
                              ? 'موقوف'
                              : active
                              ? 'مفعّل'
                              : 'بانتظار التفعيل',
                          color: active ? designGreen : Colors.orange,
                        ),
                        Text(
                          a['cloud_until'] == null
                              ? '—'
                              : designDate(
                                  DateTime.parse(
                                    a['cloud_until'] as String,
                                  ).toLocal(),
                                ),
                        ),
                        DesignPill(
                          a['printing_enabled'] == true
                              ? 'مفعّلة'
                              : 'غير مفعّلة',
                        ),
                        TextButton(
                          onPressed:
                              !AdminRepository.writesEnabled || ctrl.busy.value
                              ? null
                              : () async {
                                  final enabled = a['printing_enabled'] != true;
                                  if (await confirm(
                                    'صلاحية الطباعة',
                                    '${enabled ? 'تفعيل' : 'إيقاف'} الطباعة للحساب ${a['email']}؟',
                                  )) {
                                    await ctrl.changePrinting(
                                      a['user_id'] as String,
                                      enabled,
                                    );
                                  }
                                },
                          child: const Text('تغيير الطباعة'),
                        ),
                      ];
                    }).toList(),
                  )
                : DesignTable(
                    minWidth: 1050,
                    rowHeight: 64,
                    headers: const [
                      'الحساب',
                      'الخطة',
                      'المبلغ',
                      'الهاتف',
                      'مرجع الدفع',
                      'المراجعة',
                    ],
                    rows: ctrl.requestRows
                        .map(
                          (r) => <Widget>[
                            Text(
                              ctrl.accountRows
                                          .where(
                                            (a) => a['user_id'] == r['user_id'],
                                          )
                                          .firstOrNull?['email']
                                      as String? ??
                                  '${r['user_id']}',
                            ),
                            Text(
                              r['plan'] == 'basic'
                                  ? 'تفعيل دائم'
                                  : r['plan'] == 'cloud_month'
                                  ? 'سحابة شهرية'
                                  : 'سحابة سنوية',
                            ),
                            Text(designMoney((r['amount'] as int) * 100)),
                            Text('${r['phone']}'),
                            Text('${r['reference']}'),
                            Wrap(
                              spacing: 8,
                              children: [
                                for (final approve in [true, false])
                                  TextButton(
                                    onPressed:
                                        !AdminRepository.writesEnabled ||
                                            ctrl.busy.value
                                        ? null
                                        : () async {
                                            if (await confirm(
                                              approve
                                                  ? 'قبول الطلب'
                                                  : 'رفض الطلب',
                                              'راجع مرجع الدفع ${r['reference']} والحساب ${r['user_id']} قبل التأكيد.',
                                            )) {
                                              await ctrl.reviewRequest(
                                                r['id'] as String,
                                                approve,
                                              );
                                            }
                                          },
                                    child: Text(approve ? 'قبول' : 'رفض'),
                                  ),
                              ],
                            ),
                          ],
                        )
                        .toList(),
                  ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'صفحة ${ctrl.page.value + 1} · حتى 50 سجلًا لكل جدول',
                style: const TextStyle(color: designMuted),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: ctrl.page.value == 0
                        ? null
                        : () {
                            ctrl.page.value--;
                            ctrl.refreshData();
                          },
                    icon: const Icon(Icons.chevron_right),
                  ),
                  IconButton(
                    onPressed:
                        (tab == 0
                                ? ctrl.accountRows.length
                                : ctrl.requestRows.length) <
                            50
                        ? null
                        : () {
                            ctrl.page.value++;
                            ctrl.refreshData();
                          },
                    icon: const Icon(Icons.chevron_left),
                  ),
                ],
              ),
            ],
          ),
        ],
      );
    });
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, box) => Row(
            children: [
              if (box.maxWidth >= 600)
                DesignSidebar(
                  selected: 4,
                  onSelect: (i) =>
                      Get.offAllNamed(AppRoutes.home, arguments: {'tab': i}),
                ),
              Expanded(child: body),
            ],
          ),
        ),
      ),
    );
  }
}
