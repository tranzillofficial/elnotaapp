import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/database_impl.dart';
import '../../../core/widgets/app_widgets.dart';
import '../controllers/add_payment_controller.dart';
import '../repositories/payment_repository.dart';

class AddPaymentView extends StatefulWidget {
  const AddPaymentView({super.key});

  @override
  State<AddPaymentView> createState() => _AddPaymentViewState();
}

class _AddPaymentViewState extends State<AddPaymentView> {
  late final AddPaymentController ctrl;
  late final String customerId;
  String? _selectedCustomerId;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>?;
    customerId = args?['customer_id'] as String? ?? '';
    _selectedCustomerId = customerId.isNotEmpty ? customerId : null;
    if (!Get.isRegistered<AddPaymentController>()) {
      if (!Get.isRegistered<PaymentRepository>()) {
        Get.lazyPut<PaymentRepository>(() => PaymentRepository());
      }
      Get.lazyPut<AddPaymentController>(
        () => AddPaymentController(repo: Get.find<PaymentRepository>()),
      );
    }
    ctrl = Get.find<AddPaymentController>();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: ctrl.paymentDate.value,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      ctrl.paymentDate.value = picked;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text('payment_add'.tr)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (customerId.isEmpty) ...[
              StreamBuilder<List<CustomerRow>>(
                stream: DatabaseService.to.dao.watchCustomers(),
                builder: (context, snapshot) {
                  final customers = snapshot.data ?? [];
                  return DropdownButtonFormField<String>(
                    value: _selectedCustomerId,
                    decoration: InputDecoration(
                      labelText: 'customer_name'.tr,
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    hint: const Text('اختر العميل...'),
                    items: customers.map((c) {
                      return DropdownMenuItem<String>(
                        value: c.id,
                        child: Text(c.name),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() => _selectedCustomerId = val);
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: ctrl.amountCtrl,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                labelText: 'payment_amount'.tr,
                hintText: '0.00',
                suffixText: 'EGP',
                prefixIcon: const Icon(Icons.attach_money),
              ),
            ),
            const SizedBox(height: 20),
            Obx(() {
              final d = ctrl.paymentDate.value;
              final formatted =
                  '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
              return InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'payment_date'.tr,
                    prefixIcon: const Icon(Icons.calendar_today_outlined),
                  ),
                  child: Text(formatted, style: theme.textTheme.bodyLarge),
                ),
              );
            }),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl.notesCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'payment_notes'.tr,
                prefixIcon: const Icon(Icons.notes),
              ),
            ),
            const SizedBox(height: 28),
            Obx(
              () => ElevatedButton(
                onPressed: ctrl.isSaving.value
                    ? null
                    : () async {
                        final effectiveId = customerId.isNotEmpty
                            ? customerId
                            : _selectedCustomerId;
                        if (effectiveId == null || effectiveId.isEmpty) {
                          showErrorSnack('الرجاء اختيار العميل أولاً');
                          return;
                        }
                        final ok = await ctrl.submit(effectiveId);
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
                    : Text('action_confirm'.tr),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
