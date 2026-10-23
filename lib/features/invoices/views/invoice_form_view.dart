import '../../../core/widgets/customer_search_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/widgets/accounting_form_frame.dart';
import '../../../core/widgets/design_widgets.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/utils/money_utils.dart';
import '../../../core/services/pdf_service.dart';
import '../controllers/invoice_form_controller.dart';
import '../repositories/invoice_repository.dart';
import '../models/invoice_terms.dart';

class InvoiceFormView extends StatefulWidget {
  const InvoiceFormView({super.key});
  @override
  State<InvoiceFormView> createState() => _InvoiceFormViewState();
}

class _InvoiceFormViewState extends State<InvoiceFormView> {
  late final InvoiceFormController ctrl;
  String? customerId;
  @override
  void initState() {
    super.initState();
    customerId =
        (Get.arguments as Map<String, dynamic>?)?['customer_id'] as String?;
    if (!Get.isRegistered<InvoiceFormController>()) {
      Get.put(InvoiceFormController(InvoiceRepository()));
    }
    ctrl = Get.find<InvoiceFormController>();
    for (final c in [ctrl.amountCtrl, ctrl.discountCtrl, ctrl.upfrontCtrl]) {
      c.addListener(_changed);
    }
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    for (final c in [ctrl.amountCtrl, ctrl.discountCtrl, ctrl.upfrontCtrl]) {
      c.removeListener(_changed);
    }
    super.dispose();
  }

  Future<void> _save(bool print) async {
    if (customerId == null) {
      showErrorSnack('اختر العميل أولاً');
      return;
    }
    if (!await ctrl.save(customerId!)) return;
    final id = ctrl.savedInvoiceId!;
    Get.back(result: true);
    if (print) {
      try {
        final repo = InvoiceRepository();
        final invoice = await repo.watchOne(id).first;
        if (invoice != null) {
          final items = await repo.getItems(id);
          await PdfService.printDocument(
            await PdfService.generateInvoicePdf(invoice: invoice, items: items),
          );
        }
      } catch (_) {
        showErrorSnack(
          'تم الحفظ محليًا، وتعذرت الطباعة. يمكنك إعادة الطباعة من الفاتورة.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => AccountDataBuilder(
    builder: (context, data) => Obx(() {
      final installment = ctrl.method.value == 'installments';
      final amounts = ctrl.principal >= 0
          ? installmentAmounts(ctrl.principal, ctrl.months.value)
          : <int>[];
      return AccountingFormFrame(
        title: 'فاتورة جديدة',
        busy: ctrl.isSaving.value,
        footer: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            FilledButton(
              onPressed: ctrl.isSaving.value ? null : () => _save(false),
              child: Text(ctrl.isSaving.value ? 'جارٍ الحفظ…' : 'حفظ الفاتورة'),
            ),
            OutlinedButton(
              onPressed: ctrl.isSaving.value ? null : () => _save(true),
              child: const Text('حفظ وطباعة'),
            ),
            OutlinedButton(
              onPressed: ctrl.isSaving.value ? null : () => Get.back(),
              child: const Text('إلغاء'),
            ),
          ],
        ),
        child: IgnorePointer(
          ignoring: ctrl.isSaving.value,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FormColumns(
                children: [
                  LabeledField(
                    'العميل',
                    child: CustomerSearchField(
                      value: customerId,
                      customers: data.customers
                          .map(
                            (c) =>
                                (id: c.id, name: c.name, phone: c.phone ?? ''),
                          )
                          .toList(),
                      enabled: !ctrl.isSaving.value,
                      onChanged: (id) => setState(() => customerId = id),
                    ),
                  ),
                  LabeledField(
                    'تاريخ الفاتورة',
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: ctrl.invoiceDate.value,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (date != null) ctrl.invoiceDate.value = date;
                      },
                      icon: const Icon(Icons.calendar_month_outlined),
                      label: Text(designDate(ctrl.invoiceDate.value)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Divider(),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  const Text(
                    'بنود الفاتورة',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () => ctrl.isManualAmount.toggle(),
                    child: Text(
                      ctrl.isManualAmount.value ? 'إدخال بنود' : 'مبلغ يدوي',
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      ctrl.isManualAmount.value = false;
                      ctrl.addItem(
                        LineItemDraft(
                          description: '',
                          quantity: 1,
                          unitPriceMinor: 0,
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('إضافة بند'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (ctrl.isManualAmount.value)
                LabeledField(
                  'قيمة الفاتورة',
                  child: TextField(
                    controller: ctrl.amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(suffixText: 'ج.م'),
                  ),
                )
              else
                Column(
                  children: [
                    for (var i = 0; i < ctrl.items.length; i++)
                      _LineEditor(
                        key: ObjectKey(ctrl.items[i].editorKey),
                        item: ctrl.items[i],
                        onChanged: (item) => ctrl.items[i] = item,
                        onDelete: () => ctrl.removeItem(i),
                      ),
                    if (ctrl.items.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'أضف بندًا أو استخدم المبلغ اليدوي',
                          style: TextStyle(color: designMuted),
                        ),
                      ),
                  ],
                ),
              const SizedBox(height: 10),
              FormColumns(
                children: [
                  LabeledField(
                    'خصم (اختياري)',
                    child: TextField(
                      controller: ctrl.discountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(suffixText: 'ج.م'),
                    ),
                  ),
                  _Total('إجمالي الفاتورة', ctrl.netMinor),
                ],
              ),
              const SizedBox(height: 18),
              const Divider(),
              const SizedBox(height: 12),
              const Text(
                'طريقة السداد',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'cash', label: Text('نقدي')),
                  ButtonSegment(value: 'credit', label: Text('آجل')),
                  ButtonSegment(value: 'installments', label: Text('أقساط')),
                ],
                selected: {ctrl.method.value},
                showSelectedIcon: false,
                onSelectionChanged: (v) => ctrl.method.value = v.first,
              ),
              if (ctrl.method.value != 'cash') ...[
                const SizedBox(height: 16),
                FormColumns(
                  children: [
                    LabeledField(
                      'الدفعة المقدمة',
                      child: TextField(
                        controller: ctrl.upfrontCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          suffixText: 'ج.م',
                          helperText: 'اختياري، يمكن إدخال صفر',
                        ),
                      ),
                    ),
                    if (installment)
                      LabeledField(
                        'عدد شهور القسط',
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: ctrl.months.value > 1
                                  ? () => ctrl.months.value--
                                  : null,
                              icon: const Icon(Icons.remove),
                            ),
                            Expanded(
                              child: Text(
                                '${ctrl.months.value} شهور',
                                textAlign: TextAlign.center,
                              ),
                            ),
                            IconButton(
                              onPressed: ctrl.months.value < 120
                                  ? () => ctrl.months.value++
                                  : null,
                              icon: const Icon(Icons.add),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                if (installment) ...[
                  const SizedBox(height: 10),
                  FormColumns(
                    children: [
                      _Total('المتبقي للتقسيط', ctrl.principal),
                      _Total(
                        'قيمة القسط الشهري',
                        amounts.isEmpty ? 0 : amounts.first,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                LabeledField(
                  installment ? 'أول قسط' : 'تاريخ الاستحقاق',
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: ctrl.firstDueDate.value,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (d != null) ctrl.firstDueDate.value = d;
                    },
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: Text(designDate(ctrl.firstDueDate.value)),
                  ),
                ),
                if (installment) ...[
                  Text(
                    'آخر قسط: ${designDate(installmentDate(ctrl.firstDueDate.value, ctrl.months.value - 1))}',
                    style: const TextStyle(color: designMuted, fontSize: 12),
                  ),
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: Text(
                      'عرض جدول الأقساط (${ctrl.months.value} أقساط)',
                    ),
                    children: [
                      for (var i = 0; i < amounts.length; i++)
                        ListTile(
                          dense: true,
                          title: Text(
                            designDate(
                              installmentDate(ctrl.firstDueDate.value, i),
                            ),
                          ),
                          trailing: Text(designMoney(amounts[i])),
                        ),
                    ],
                  ),
                  const Text(
                    'الدفعات تسدد أقدم استحقاق أولاً؛ فروق القروش تُضاف لآخر قسط.',
                    style: TextStyle(color: designMuted, fontSize: 12),
                  ),
                ],
              ],
              if (ctrl.method.value == 'cash')
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'سيُسجّل كامل المبلغ كدفعة على حساب العميل مع الفاتورة.',
                    style: TextStyle(color: designGreen),
                  ),
                ),
              const SizedBox(height: 16),
              LabeledField(
                'ملاحظة (اختياري)',
                child: TextField(
                  controller: ctrl.notesCtrl,
                  decoration: const InputDecoration(
                    hintText: 'أضف ملاحظة للفاتورة',
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }),
  );
}

class _Total extends StatelessWidget {
  const _Total(this.label, this.amount);
  final String label;
  final int amount;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: designGreen.withValues(alpha: .06),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        Text(
          designMoney(amount),
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: designGreen,
          ),
        ),
      ],
    ),
  );
}

class _LineEditor extends StatefulWidget {
  const _LineEditor({
    super.key,
    required this.item,
    required this.onChanged,
    required this.onDelete,
  });
  final LineItemDraft item;
  final ValueChanged<LineItemDraft> onChanged;
  final VoidCallback onDelete;
  @override
  State<_LineEditor> createState() => _LineEditorState();
}

class _LineEditorState extends State<_LineEditor> {
  late final desc = TextEditingController(text: widget.item.description);
  late final qty = TextEditingController(text: '${widget.item.quantity}');
  late final price = TextEditingController(
    text: MoneyUtils.formatMinorNoSymbol(widget.item.unitPriceMinor),
  );
  @override
  void dispose() {
    desc.dispose();
    qty.dispose();
    price.dispose();
    super.dispose();
  }

  void changed(String _) => widget.onChanged(
    LineItemDraft(
      editorKey: widget.item.editorKey,
      description: desc.text,
      quantity: int.tryParse(qty.text) ?? 0,
      unitPriceMinor: MoneyUtils.parseToMinor(price.text) ?? 0,
    ),
  );
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: FormColumns(
      children: [
        TextField(
          controller: desc,
          onChanged: changed,
          decoration: const InputDecoration(labelText: 'الصنف / الوصف'),
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: qty,
                onChanged: changed,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'الكمية'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: TextField(
                controller: price,
                onChanged: changed,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'سعر الوحدة'),
              ),
            ),
            IconButton(
              onPressed: widget.onDelete,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ],
    ),
  );
}
