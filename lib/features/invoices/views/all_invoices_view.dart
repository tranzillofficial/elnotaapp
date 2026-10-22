import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/utils/app_routes.dart';
import '../../../core/widgets/app_widgets.dart';
import '../models/invoice_model.dart';
import '../repositories/invoice_repository.dart';

/// Workspace-wide invoices list view.
/// Shows all invoices with search, status filters, and live updates.
class AllInvoicesView extends StatefulWidget {
  const AllInvoicesView({super.key});

  @override
  State<AllInvoicesView> createState() => _AllInvoicesViewState();
}

class _AllInvoicesViewState extends State<AllInvoicesView> {
  final _searchCtrl = TextEditingController();
  final _selectedStatus = ''.obs; // '' means all, 'posted', 'draft'
  final _searchQuery = ''.obs;

  late final InvoiceRepository _repo;

  @override
  void initState() {
    super.initState();
    _repo = Get.isRegistered<InvoiceRepository>()
        ? Get.find<InvoiceRepository>()
        : Get.put(InvoiceRepository());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('nav_invoices'.tr),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed(AppRoutes.invoiceCreate),
        icon: const Icon(Icons.add),
        label: Text('invoice_add'.tr),
      ),
      body: Column(
        children: [
          // ─── Search Bar ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'ابحث عن فاتورة أو عميل...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          _searchQuery.value = '';
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (v) => _searchQuery.value = v.trim(),
            ),
          ),

          // ─── Filter Chips ─────────────────────────────────────────────────
          Obx(() {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  _FilterChip(
                    label: 'الكل',
                    isSelected: _selectedStatus.value.isEmpty,
                    onSelected: () => _selectedStatus.value = '',
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'invoice_status_posted'.tr,
                    isSelected: _selectedStatus.value == 'posted',
                    onSelected: () => _selectedStatus.value = 'posted',
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'invoice_status_draft'.tr,
                    isSelected: _selectedStatus.value == 'draft',
                    onSelected: () => _selectedStatus.value = 'draft',
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 4),

          // ─── Invoices List Stream ─────────────────────────────────────────
          Expanded(
            child: Obx(() {
              final search = _searchQuery.value;
              final status = _selectedStatus.value;

              return StreamBuilder<List<InvoiceModel>>(
                stream: _repo.watchAll(search: search, status: status),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator.adaptive(),
                    );
                  }

                  final invoices = snapshot.data ?? [];
                  if (invoices.isEmpty) {
                    return AppEmptyWidget(
                      icon: Icons.receipt_long_outlined,
                      message: 'invoice_empty'.tr,
                      actionLabel: 'invoice_add'.tr,
                      onAction: () => Get.toNamed(AppRoutes.invoiceCreate),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                    itemCount: invoices.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final inv = invoices[index];
                      final isPosted = inv.isPosted;

                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            color: theme.colorScheme.outlineVariant,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: isPosted
                                ? theme.colorScheme.primaryContainer
                                : Colors.amber.withValues(alpha: 0.2),
                            child: Icon(
                              Icons.receipt_outlined,
                              color: isPosted
                                  ? theme.colorScheme.onPrimaryContainer
                                  : Colors.orange.shade800,
                              size: 20,
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  inv.customerName ?? 'عميل',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isPosted
                                      ? Colors.green.withValues(alpha: 0.12)
                                      : Colors.amber.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isPosted
                                      ? 'invoice_status_posted'.tr
                                      : 'invoice_status_draft'.tr,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isPosted
                                        ? Colors.green.shade800
                                        : Colors.orange.shade900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '${inv.invoiceDate.year}-${inv.invoiceDate.month.toString().padLeft(2, '0')}-${inv.invoiceDate.day.toString().padLeft(2, '0')}${inv.notes != null ? ' • ${inv.notes}' : ''}',
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                          trailing: Text(
                            inv.formattedNet,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          onTap: () => Get.toNamed(
                            AppRoutes.invoiceDetail,
                            arguments: {'id': inv.id},
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      selectedColor: theme.colorScheme.primaryContainer,
      labelStyle: TextStyle(
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected
            ? theme.colorScheme.onPrimaryContainer
            : theme.colorScheme.onSurface,
      ),
    );
  }
}
