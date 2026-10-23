import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/widgets/design_widgets.dart';
import '../../../core/utils/app_routes.dart';
import '../../../core/widgets/sync_status_badge.dart';
import '../models/customer_model.dart';
import '../repositories/customer_repository.dart';

class CustomersListView extends StatefulWidget {
  const CustomersListView({super.key});
  @override
  State<CustomersListView> createState() => _CustomersListViewState();
}

class _CustomersListViewState extends State<CustomersListView> {
  String query = '';
  int filter = 0;
  int page = 0;
  bool newest = true;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: AccountDataBuilder(
        builder: (context, data) {
          final all = data.customers;
          final filtered =
              all.where((c) {
                final balance = data.balances[c.id];
                final due = balance?.outstandingMinor;
                return (c.name.contains(query) ||
                        (c.phone ?? '').contains(query)) &&
                    (filter == 0 ||
                        filter == 1 && due != null && due > 0 ||
                        filter == 2 && due != null && due <= 0);
              }).toList()..sort(
                (a, b) => newest
                    ? b.createdAt.compareTo(a.createdAt)
                    : a.name.compareTo(b.name),
              );
          final pages = (filtered.length / 7).ceil();
          final current = pages == 0 ? 0 : page.clamp(0, pages - 1);
          final visible = filtered.skip(current * 7).take(7).toList();
          return ListView(
            padding: EdgeInsets.all(
              MediaQuery.sizeOf(context).width < 600 ? 16 : 38,
            ),
            children: [
              DesignHeader(
                title: 'العملاء',
                subtitle: 'حسابات عملائك ومدفوعاتهم في مكان واحد',
                actions: [
                  const SyncStatusBadge(),
                  DesignAction(
                    'عميل جديد',
                    Icons.add,
                    () => Get.toNamed(AppRoutes.customerCreate),
                    primary: true,
                  ),
                ],
              ),
              DesignStats(
                children: [
                  DesignStat(
                    'إجمالي العملاء',
                    '${all.length}',
                    Icons.people_outline,
                  ),
                  DesignStat(
                    'إجمالي المستحق',
                    designMoney(
                      data.balances.values.fold<int>(
                        0,
                        (sum, b) =>
                            sum +
                            (b.outstandingMinor > 0 ? b.outstandingMinor : 0),
                      ),
                    ),
                    Icons.payment_outlined,
                  ),
                  DesignStat(
                    'عملاء عليهم متأخرات',
                    '${data.dues.where((d) => d.overdueAt(DateTime.now())).map((d) => d.customerId).toSet().length}',
                    Icons.access_time,
                    color: Colors.red,
                    highlight: true,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              DesignPanel(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: LayoutBuilder(
                        builder: (context, box) => Wrap(
                          spacing: 20,
                          runSpacing: 14,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            SizedBox(
                              width: box.maxWidth < 500 ? box.maxWidth : 360,
                              child: TextField(
                                onChanged: (v) => setState(() {
                                  query = v;
                                  page = 0;
                                }),
                                decoration: const InputDecoration(
                                  hintText: 'ابحث باسم العميل أو رقم الهاتف',
                                  prefixIcon: Icon(Icons.search),
                                ),
                              ),
                            ),
                            SegmentedButton<int>(
                              segments: const [
                                ButtonSegment(value: 0, label: Text('الكل')),
                                ButtonSegment(
                                  value: 1,
                                  label: Text('عليهم مستحقات'),
                                ),
                                ButtonSegment(value: 2, label: Text('مسددون')),
                              ],
                              selected: {filter},
                              onSelectionChanged: (v) => setState(() {
                                filter = v.first;
                                page = 0;
                              }),
                              showSelectedIcon: false,
                            ),
                            DropdownButton<bool>(
                              value: newest,
                              underline: const SizedBox(),
                              items: const [
                                DropdownMenuItem(
                                  value: true,
                                  child: Text('الأحدث'),
                                ),
                                DropdownMenuItem(
                                  value: false,
                                  child: Text('الاسم'),
                                ),
                              ],
                              onChanged: (v) => setState(() {
                                newest = v!;
                                page = 0;
                              }),
                            ),
                          ],
                        ),
                      ),
                    ),
                    DesignTable(
                      minWidth: 1050,
                      rowHeight: 68,
                      headers: const [
                        'العميل',
                        'إجمالي الفواتير',
                        'المدفوع',
                        'المتبقي',
                        'آخر تعامل',
                        'الحالة',
                        '',
                      ],
                      rows: visible.map((c) {
                        final b = data.balances[c.id];
                        final dates = [
                          c.createdAt,
                          ...data.invoices
                              .where((i) => i.customerId == c.id)
                              .map((i) => i.invoiceDate),
                          ...data.payments
                              .where((p) => p.customerId == c.id)
                              .map((p) => p.paymentDate),
                        ]..sort();
                        return <Widget>[
                          InkWell(
                            onTap: () => openCustomer(c.id),
                            child: Row(
                              children: [
                                DesignAvatar(c.name),
                                const SizedBox(width: 14),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      c.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      c.phone ?? '—',
                                      textDirection: TextDirection.ltr,
                                      style: const TextStyle(
                                        color: designMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Text(b == null ? '—' : b.formattedInvoiced),
                          Text(b == null ? '—' : b.formattedPayments),
                          Text(
                            b == null ? '—' : designMoney(b.outstandingMinor),
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                              color: b != null && b.outstandingMinor > 0
                                  ? Colors.red
                                  : designGreen,
                            ),
                          ),
                          Text(
                            designDate(dates.last),
                            style: const TextStyle(color: designMuted),
                          ),
                          DesignPill(
                            b == null
                                ? 'جارٍ التحميل'
                                : b.hasCredit
                                ? 'رصيد دائن'
                                : b.isZero
                                ? 'مسدد'
                                : 'مستحق',
                            color: b != null && b.outstandingMinor > 0
                                ? Colors.orange
                                : designGreen,
                          ),
                          _CustomerMenu(customer: c),
                        ];
                      }).toList(),
                    ),
                    if (visible.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(48),
                        child: Text('لا يوجد عملاء مطابقون'),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                runSpacing: 12,
                children: [
                  Text(
                    'عرض ${filtered.isEmpty ? 0 : current * 7 + 1} – ${current * 7 + visible.length} من ${filtered.length} عميل',
                    style: const TextStyle(color: designMuted),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: current > 0
                            ? () => setState(() => page = current - 1)
                            : null,
                        icon: const Icon(Icons.chevron_right),
                      ),
                      for (var i = 0; i < pages; i++)
                        if ((i - current).abs() < 3)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(40, 40),
                                padding: EdgeInsets.zero,
                                backgroundColor: i == current
                                    ? designGreen
                                    : null,
                                foregroundColor: i == current
                                    ? Colors.white
                                    : null,
                              ),
                              onPressed: () => setState(() => page = i),
                              child: Text('${i + 1}'),
                            ),
                          ),
                      IconButton(
                        onPressed: current + 1 < pages
                            ? () => setState(() => page = current + 1)
                            : null,
                        icon: const Icon(Icons.chevron_left),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    ),
  );
}

class _CustomerMenu extends StatelessWidget {
  const _CustomerMenu({required this.customer});
  final CustomerModel customer;
  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
    tooltip: 'إجراءات العميل',
    icon: const Icon(Icons.more_vert),
    onSelected: (value) async {
      switch (value) {
        case 'view':
          openCustomer(customer.id);
        case 'payment':
          customerAction(AppRoutes.paymentCreate, customer.id);
        case 'invoice':
          customerAction(AppRoutes.invoiceCreate, customer.id);
        case 'edit':
          Get.toNamed(
            AppRoutes.customerCreate,
            arguments: {'id': customer.id, 'edit': true},
          );
        case 'delete':
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('حذف العميل'),
              content: Text('هل تريد حذف ${customer.name}؟'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('إلغاء'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('حذف', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );
          if (confirmed == true) {
            await CustomerRepository().delete(customer.id);
          }
      }
    },
    itemBuilder: (context) => [
      for (final item in [
        ('view', 'عرض الحساب', Icons.visibility_outlined),
        ('payment', 'تسجيل دفعة', Icons.payment),
        ('invoice', 'فاتورة جديدة', Icons.description_outlined),
        ('edit', 'تعديل البيانات', Icons.edit_outlined),
        ('delete', 'حذف العميل', Icons.delete_outline),
      ])
        PopupMenuItem(
          value: item.$1,
          child: Row(
            children: [
              Icon(
                item.$3,
                size: 20,
                color: item.$1 == 'delete' ? Colors.red : designMuted,
              ),
              const SizedBox(width: 12),
              Text(
                item.$2,
                style: TextStyle(
                  color: item.$1 == 'delete' ? Colors.red : null,
                ),
              ),
            ],
          ),
        ),
    ],
  );
}
