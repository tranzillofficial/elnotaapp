import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/utils/money_utils.dart';
import '../../../core/widgets/app_widgets.dart';
import '../controllers/invoice_form_controller.dart';
import '../repositories/invoice_repository.dart';

class InvoiceFormView extends StatefulWidget {
  const InvoiceFormView({super.key});

  @override
  State<InvoiceFormView> createState() => _InvoiceFormViewState();
}

class _InvoiceFormViewState extends State<InvoiceFormView> {
  late final InvoiceFormController ctrl;
  late final String customerId;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>?;
    customerId = args?['customer_id'] as String? ?? '';
    if (!Get.isRegistered<InvoiceFormController>()) {
      if (!Get.isRegistered<InvoiceRepository>()) {
        Get.lazyPut<InvoiceRepository>(() => InvoiceRepository());
      }
      Get.lazyPut<InvoiceFormController>(
        () => InvoiceFormController(Get.find<InvoiceRepository>()),
      );
    }
    ctrl = Get.find<InvoiceFormController>();
  }

  void _showAddItemDialog() {
    final descCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1');
    final priceCtrl = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: Text('invoice_items'.tr),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: descCtrl,
                decoration: InputDecoration(
                  labelText: 'product_name'.tr,
                  hintText: 'product_name'.tr,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: qtyCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'product_quantity'.tr,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'product_price'.tr,
                  suffixText: 'EGP',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('action_cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () {
              final desc = descCtrl.text.trim();
              final qty = int.tryParse(qtyCtrl.text) ?? 1;
              final priceMinor = MoneyUtils.parseToMinor(priceCtrl.text) ?? 0;
              if (desc.isEmpty || qty <= 0 || priceMinor <= 0) {
                showErrorSnack('validation_amount_required'.tr);
                return;
              }
              ctrl.addItem(
                LineItemDraft(
                  description: desc,
                  quantity: qty,
                  unitPriceMinor: priceMinor,
                ),
              );
              Get.back();
            },
            child: Text('action_add'.tr),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('invoice_add'.tr),
      ),
      body: Obx(() {
        final totalMinor = ctrl.totalMinor;
        final discountMinor = ctrl.discountMinor;
        final netMinor = ctrl.netMinor;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Segmented switch: Manual vs Line Items
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment<bool>(
                    value: true,
                    label: Text('invoice_manual_amount'.tr),
                    icon: const Icon(Icons.edit_note),
                  ),
                  ButtonSegment<bool>(
                    value: false,
                    label: Text('invoice_items'.tr),
                    icon: const Icon(Icons.list_alt),
                  ),
                ],
                selected: {ctrl.isManualAmount.value},
                onSelectionChanged: (set) {
                  ctrl.isManualAmount.value = set.first;
                },
              ),
              const SizedBox(height: 20),

              if (ctrl.isManualAmount.value) ...[
                TextField(
                  controller: ctrl.amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'invoice_amount'.tr,
                    hintText: '0.00',
                    suffixText: 'EGP',
                    prefixIcon: const Icon(Icons.attach_money),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ] else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('invoice_items'.tr, style: theme.textTheme.titleMedium),
                    TextButton.icon(
                      onPressed: _showAddItemDialog,
                      icon: const Icon(Icons.add),
                      label: Text('action_add'.tr),
                    ),
                  ],
                ),
                if (ctrl.items.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.colorScheme.outlineVariant),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'status_empty'.tr,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: ctrl.items.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, idx) {
                      final item = ctrl.items[idx];
                      return ListTile(
                        dense: true,
                        title: Text(item.description),
                        subtitle: Text(
                          '${item.quantity} × ${MoneyUtils.formatMinor(item.unitPriceMinor)}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              MoneyUtils.formatMinor(item.lineTotal),
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => ctrl.removeItem(idx),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],

              const SizedBox(height: 16),
              TextField(
                controller: ctrl.discountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'invoice_discount'.tr,
                  hintText: '0.00',
                  suffixText: 'EGP',
                  prefixIcon: const Icon(Icons.discount_outlined),
                ),
                onChanged: (_) => setState(() {}),
              ),

              const SizedBox(height: 16),
              TextField(
                controller: ctrl.notesCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'invoice_notes'.tr,
                  prefixIcon: const Icon(Icons.notes),
                ),
              ),

              const SizedBox(height: 24),

              // Summary card
              Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('invoice_amount'.tr),
                          Text(MoneyUtils.formatMinor(totalMinor)),
                        ],
                      ),
                      if (discountMinor > 0) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('invoice_discount'.tr, style: const TextStyle(color: Colors.green)),
                            Text('- ${MoneyUtils.formatMinor(discountMinor)}',
                                style: const TextStyle(color: Colors.green)),
                          ],
                        ),
                      ],
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'customer_outstanding'.tr,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            MoneyUtils.formatMinor(netMinor),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: ctrl.isSaving.value
                    ? null
                    : () async {
                        final ok = await ctrl.save(customerId);
                        if (ok) {
                          Get.back(result: true);
                        }
                      },
                child: ctrl.isSaving.value
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text('action_save'.tr),
              ),
            ],
          ),
        );
      }),
    );
  }
}
