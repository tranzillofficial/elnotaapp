import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/pdf_service.dart';
import '../../../core/utils/app_routes.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../invoices/views/invoice_list_view.dart';
import '../../payments/views/payments_list_view.dart';
import '../controllers/customer_detail_controller.dart';
import '../models/customer_model.dart';
import '../repositories/customer_repository.dart';

/// Customer detail: balance header + invoices tab + payments tab.
class CustomerDetailView extends StatelessWidget {
  const CustomerDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>?;
    final customerId = args?['id'] as String? ?? '';
    final ctrl = Get.put(
      CustomerDetailController(CustomerRepository(), customerId),
      tag: customerId,
    );

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Obx(() => Text(
                ctrl.customer.value?.name ?? 'nav_customers'.tr,
              )),
          actions: [
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_outlined),
              tooltip: 'كشف حساب PDF',
              onPressed: () async {
                final cust = ctrl.customer.value;
                final bal = ctrl.balance.value;
                if (cust != null && bal != null) {
                  final bytes = await PdfService.generateCustomerStatementPdf(
                    customer: cust,
                    balance: bal,
                    invoices: const [],
                    payments: const [],
                  );
                  await PdfService.shareDocument(
                    bytes,
                    filename: 'Statement_${cust.name}.pdf',
                  );
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'action_edit'.tr,
              onPressed: () => Get.toNamed(
                AppRoutes.customerCreate,
                arguments: {'id': customerId, 'edit': true},
              ),
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(text: 'nav_invoices'.tr),
              Tab(text: 'nav_payments'.tr),
            ],
          ),
        ),
        body: Obx(() {
          if (ctrl.isLoading.value) return const AppLoadingWidget();
          if (ctrl.customer.value == null) {
            return AppErrorWidget(message: 'error_not_found'.tr);
          }
          return Column(
            children: [
              _BalanceHeader(balance: ctrl.balance.value),
              const Expanded(
                child: TabBarView(
                  children: [
                    _InvoicesTab(),
                    _PaymentsTab(),
                  ],
                ),
              ),
            ],
          );
        }),
        floatingActionButton: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            FloatingActionButton.small(
              heroTag: 'fab_payment',
              onPressed: () => Get.toNamed(
                AppRoutes.paymentCreate,
                arguments: {'customer_id': customerId},
              ),
              child: const Icon(Icons.payments_outlined),
            ),
            const SizedBox(height: 8),
            FloatingActionButton.extended(
              heroTag: 'fab_invoice',
              onPressed: () => Get.toNamed(
                AppRoutes.invoiceCreate,
                arguments: {'customer_id': customerId},
              ),
              icon: const Icon(Icons.receipt_long_outlined),
              label: Text('invoice_create'.tr),
            ),
          ],
        ),
      ),
    );
  }
}

class _BalanceHeader extends StatelessWidget {
  const _BalanceHeader({required this.balance});
  final CustomerBalanceSummary? balance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final b = balance;
    return Container(
      width: double.infinity,
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: b == null
          ? const SizedBox.shrink()
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _Stat(
                  label: 'balance_invoiced'.tr,
                  value: b.formattedInvoiced,
                ),
                _Stat(
                  label: 'balance_paid'.tr,
                  value: b.formattedPayments,
                ),
                _Stat(
                  label: b.hasCredit ? 'balance_credit'.tr : 'balance_outstanding'.tr,
                  value: b.formattedOutstanding,
                  valueColor: b.hasCredit
                      ? Colors.green
                      : (b.outstandingMinor > 0 ? theme.colorScheme.error : null),
                ),
              ],
            ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.valueColor});
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: valueColor,
            )),
        const SizedBox(height: 2),
        Text(label,
            style: theme.textTheme.labelSmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

// ── Stub tabs — replaced by invoice/payment views wired in Phase 2 ───────────

class _InvoicesTab extends StatelessWidget {
  const _InvoicesTab();
  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>?;
    final customerId = args?['id'] as String? ?? '';
    return InvoiceListView(customerId: customerId);
  }
}

class _PaymentsTab extends StatelessWidget {
  const _PaymentsTab();
  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>?;
    final customerId = args?['id'] as String? ?? '';
    return PaymentsListView(customerId: customerId);
  }
}
