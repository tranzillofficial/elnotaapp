import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/widgets/design_widgets.dart';
import '../../../core/services/excel_export_service.dart';
import '../../../core/services/pdf_service.dart';
import '../../../core/utils/app_routes.dart';
import '../models/invoice_model.dart';
import '../repositories/invoice_repository.dart';

class AllInvoicesView extends StatefulWidget {
  const AllInvoicesView({super.key});
  @override
  State<AllInvoicesView> createState() => _AllInvoicesViewState();
}

class _AllInvoicesViewState extends State<AllInvoicesView> {
  int tab =
      (Get.arguments is Map && (Get.arguments as Map)['installments'] == true)
      ? 1
      : 0;
  int page = 0;
  String query = '';
  String method = 'all';
  String status = 'all';
  String month = 'all';
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: AccountDataBuilder(
        builder: (context, data) {
          final terms = {for (final t in data.terms) t.invoiceId: t};
          final names = {for (final c in data.customers) c.id: c.name};
          final months =
              data.invoices
                  .map(
                    (i) =>
                        '${i.invoiceDate.year}/${i.invoiceDate.month.toString().padLeft(2, '0')}',
                  )
                  .toSet()
                  .toList()
                ..sort((a, b) => b.compareTo(a));
          final filtered =
              data.invoices
                  .where(
                    (i) =>
                        ('${names[i.customerId] ?? i.customerName ?? ''} ${i.id}'
                            .contains(query)) &&
                        (method == 'all' ||
                            (terms[i.id]?.method ?? 'credit') == method) &&
                        (status == 'all' || i.status == status) &&
                        (month == 'all' ||
                            '${i.invoiceDate.year}/${i.invoiceDate.month.toString().padLeft(2, '0')}' ==
                                month),
                  )
                  .toList()
                ..sort((a, b) => b.invoiceDate.compareTo(a.invoiceDate));
          final pages = (filtered.length / 8).ceil();
          final current = pages == 0 ? 0 : page.clamp(0, pages - 1);
          final visible = filtered.skip(current * 8).take(8).toList();
          final overdue = data.dues
              .where((d) => d.overdueAt(DateTime.now()))
              .toList();
          final schedule =
              data.dues
                  .where(
                    (d) => ('${names[d.customerId]} ${d.invoiceId}'.contains(
                      query,
                    )),
                  )
                  .toList()
                ..sort((a, b) => a.date.compareTo(b.date));
          return ListView(
            padding: EdgeInsets.all(
              MediaQuery.sizeOf(context).width < 600 ? 16 : 32,
            ),
            children: [
              DesignHeader(
                title: 'الفواتير',
                subtitle: 'إدارة فواتير البيع ومتابعة الأقساط',
                actions: [
                  DesignAction(
                    'تصدير',
                    Icons.upload_outlined,
                    () => ExcelExportService.exportAndShareWorkbook(
                      customers: data.customers,
                      invoices: filtered,
                    ),
                  ),
                  DesignAction(
                    'فاتورة جديدة',
                    Icons.add,
                    () => Get.toNamed(AppRoutes.invoiceCreate),
                    primary: true,
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < 2; i++)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 16),
                      child: TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: tab == i ? designGreen : designMuted,
                        ),
                        onPressed: () => setState(() => tab = i),
                        child: Text(
                          i == 0
                              ? 'الفواتير'
                              : 'جدول الأقساط (${overdue.length})',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 14),
              DesignStats(
                children: [
                  DesignStat(
                    'عدد الفواتير',
                    '${data.invoices.length}',
                    Icons.description_outlined,
                  ),
                  DesignStat(
                    'قيمة الفواتير',
                    designMoney(
                      data.invoices
                          .where((i) => i.isPosted)
                          .fold<int>(0, (sum, i) => sum + i.netMinor),
                    ),
                    Icons.storage_outlined,
                  ),
                  DesignStat(
                    'فواتير آجل وأقساط',
                    '${data.invoices.where((i) => terms[i.id]?.method != 'cash').length}',
                    Icons.pie_chart_outline,
                  ),
                  DesignStat(
                    'أقساط متأخرة',
                    designMoney(
                      overdue.fold<int>(0, (sum, d) => sum + d.remainingMinor),
                    ),
                    Icons.access_time,
                    color: Colors.red,
                    highlight: true,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DesignPanel(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Wrap(
                        spacing: 18,
                        runSpacing: 12,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          SizedBox(
                            width: MediaQuery.sizeOf(context).width < 500
                                ? 270
                                : 390,
                            child: TextField(
                              onChanged: (v) => setState(() {
                                query = v;
                                page = 0;
                              }),
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.search),
                                hintText: 'ابحث برقم الفاتورة أو اسم العميل',
                              ),
                            ),
                          ),
                          if (tab == 0)
                            SegmentedButton<String>(
                              segments: const [
                                ButtonSegment(
                                  value: 'all',
                                  label: Text('الكل'),
                                ),
                                ButtonSegment(
                                  value: 'cash',
                                  label: Text('نقدي'),
                                ),
                                ButtonSegment(
                                  value: 'credit',
                                  label: Text('آجل'),
                                ),
                                ButtonSegment(
                                  value: 'installments',
                                  label: Text('أقساط'),
                                ),
                              ],
                              selected: {method},
                              showSelectedIcon: false,
                              onSelectionChanged: (v) => setState(() {
                                method = v.first;
                                page = 0;
                              }),
                            ),
                          DropdownButton<String>(
                            value: months.contains(month) ? month : 'all',
                            underline: const SizedBox(),
                            items: [
                              const DropdownMenuItem(
                                value: 'all',
                                child: Text('كل الشهور'),
                              ),
                              for (final m in months)
                                DropdownMenuItem(value: m, child: Text(m)),
                            ],
                            onChanged: (v) => setState(() {
                              month = v!;
                              page = 0;
                            }),
                          ),
                          PopupMenuButton<String>(
                            tooltip: 'تصفية الحالة',
                            onSelected: (v) => setState(() {
                              status = v;
                              page = 0;
                            }),
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: 'all',
                                child: Text('كل الحالات'),
                              ),
                              PopupMenuItem(
                                value: 'posted',
                                child: Text('مرحّلة'),
                              ),
                              PopupMenuItem(
                                value: 'draft',
                                child: Text('مسودة'),
                              ),
                              PopupMenuItem(
                                value: 'voided',
                                child: Text('ملغاة'),
                              ),
                            ],
                            child: const Padding(
                              padding: EdgeInsets.all(10),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.tune, size: 20),
                                  SizedBox(width: 8),
                                  Text('تصفية'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (tab == 0)
                      DesignTable(
                        minWidth: 1100,
                        rowHeight: 64,
                        headers: const [
                          'الفاتورة',
                          'العميل',
                          'التاريخ',
                          'طريقة السداد',
                          'الإجمالي',
                          'المقدم',
                          'الحالة',
                          'إجراءات',
                        ],
                        rows: visible.map((i) {
                          final t = terms[i.id];
                          final m = t?.method ?? 'credit';
                          return <Widget>[
                            Text(
                              '#${i.id.substring(0, i.id.length < 8 ? i.id.length : 8)}',
                              style: const TextStyle(
                                color: designGreen,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            InkWell(
                              onTap: () => openCustomer(i.customerId),
                              child: Text(
                                names[i.customerId] ?? i.customerName ?? '—',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Text(designDate(i.invoiceDate)),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                DesignPill(
                                  m == 'cash'
                                      ? 'نقدي'
                                      : m == 'installments'
                                      ? 'أقساط'
                                      : 'آجل',
                                  color: m == 'installments'
                                      ? Colors.blue
                                      : m == 'credit'
                                      ? Colors.orange
                                      : designGreen,
                                ),
                                if (m == 'installments')
                                  Text(
                                    '${t!.months} شهور',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: designMuted,
                                    ),
                                  ),
                              ],
                            ),
                            Text(i.formattedNet),
                            Text(t == null ? '—' : designMoney(t.upfrontMinor)),
                            DesignPill(
                              i.isPosted
                                  ? 'مرحّلة'
                                  : i.isDraft
                                  ? 'مسودة'
                                  : 'ملغاة',
                              color: i.isPosted ? designGreen : designMuted,
                            ),
                            _InvoiceMenu(
                              invoice: i,
                              name: names[i.customerId],
                              onSchedule: () => setState(() {
                                tab = 1;
                                query = i.id;
                              }),
                            ),
                          ];
                        }).toList(),
                      )
                    else
                      DesignTable(
                        minWidth: 850,
                        headers: const [
                          'العميل',
                          'الفاتورة',
                          'القسط',
                          'تاريخ الاستحقاق',
                          'المبلغ',
                          'المتبقي',
                          'الحالة',
                        ],
                        rows: schedule
                            .map(
                              (d) => <Widget>[
                                InkWell(
                                  onTap: () => openCustomer(d.customerId),
                                  child: Text(names[d.customerId] ?? '—'),
                                ),
                                Text('#${d.invoiceId.substring(0, 8)}'),
                                Text('${d.index}'),
                                Text(designDate(d.date)),
                                Text(designMoney(d.amountMinor)),
                                Text(designMoney(d.remainingMinor)),
                                DesignPill(
                                  d.remainingMinor == 0
                                      ? 'مسدد'
                                      : d.overdueAt(DateTime.now())
                                      ? 'متأخر'
                                      : 'قادم',
                                  color: d.overdueAt(DateTime.now())
                                      ? Colors.red
                                      : designGreen,
                                ),
                              ],
                            )
                            .toList(),
                      ),
                    if (tab == 0 && visible.isEmpty ||
                        tab == 1 && schedule.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(40),
                        child: Text('لا توجد بيانات مطابقة'),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                spacing: 16,
                runSpacing: 12,
                children: [
                  Text(
                    tab == 0
                        ? 'عرض ${filtered.isEmpty ? 0 : current * 8 + 1} – ${current * 8 + visible.length} من ${filtered.length} فاتورة'
                        : 'تسدد الدفعات أقدم استحقاق أولاً، والمقدم هو المبلغ المسجل عند إنشاء الفاتورة.',
                    style: const TextStyle(color: designMuted, fontSize: 12),
                  ),
                  if (tab == 0)
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
                            TextButton(
                              onPressed: () => setState(() => page = i),
                              child: Text('${i + 1}'),
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

class _InvoiceMenu extends StatelessWidget {
  const _InvoiceMenu({
    required this.invoice,
    required this.name,
    required this.onSchedule,
  });
  final InvoiceModel invoice;
  final String? name;
  final VoidCallback onSchedule;
  Future<void> export(bool print) async {
    final items = await InvoiceRepository().getItems(invoice.id);
    final bytes = await PdfService.generateInvoicePdf(
      invoice: invoice,
      customerName: name,
      items: items,
    );
    if (print) {
      await PdfService.printDocument(bytes);
    } else {
      await PdfService.shareDocument(
        bytes,
        filename: 'Invoice_${invoice.id}.pdf',
      );
    }
  }

  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
    tooltip: 'إجراءات الفاتورة',
    onSelected: (v) async {
      if (v == 'view') {
        Get.toNamed(
          AppRoutes.invoiceDetail,
          arguments: {'invoice_id': invoice.id},
        );
      }
      if (v == 'schedule') onSchedule();
      if (v == 'print' || v == 'export') {
        try {
          await export(v == 'print');
        } catch (_) {
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('تعذر تجهيز المستند')));
          }
        }
      }
    },
    itemBuilder: (_) => const [
      PopupMenuItem(value: 'view', child: Text('عرض الفاتورة')),
      PopupMenuItem(value: 'schedule', child: Text('عرض جدول الأقساط')),
      PopupMenuItem(value: 'print', child: Text('طباعة')),
      PopupMenuItem(value: 'export', child: Text('مشاركة PDF')),
    ],
  );
}
