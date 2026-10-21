import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/utils/app_routes.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/sync_status_badge.dart';
import '../bindings/customers_binding.dart';
import '../controllers/customer_list_controller.dart';
import '../models/customer_model.dart';

/// Customers list with search bar and FAB to create.
class CustomersListView extends StatelessWidget {
  const CustomersListView({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<CustomerListController>()) {
      CustomersBinding().dependencies();
    }
    final controller = Get.find<CustomerListController>();
    return Scaffold(
      appBar: AppBar(
        title: Text('nav_customers'.tr),
        actions: const [
          SyncStatusBadge(),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: SearchBar(
              hintText: 'customer_search_hint'.tr,
              leading: const Icon(Icons.search_rounded, size: 20),
              elevation: const WidgetStatePropertyAll(0),
              onChanged: controller.onSearchChanged,
            ),
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.customers.isEmpty) {
          return const AppLoadingWidget();
        }
        if (controller.customers.isEmpty) {
          return AppEmptyWidget(
            icon: Icons.people_alt_outlined,
            message: 'customer_empty'.tr,
            actionLabel: 'customer_create'.tr,
            onAction: () => Get.toNamed(AppRoutes.customerCreate),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: controller.customers.length,
          separatorBuilder: (context, index) => const SizedBox(height: 4),
          itemBuilder: (ctx, i) =>
              _CustomerTile(customer: controller.customers[i]),
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed(AppRoutes.customerCreate),
        icon: const Icon(Icons.person_add_rounded),
        label: Text('customer_create'.tr),
      ),
    );
  }
}

class _CustomerTile extends StatelessWidget {
  const _CustomerTile({required this.customer});
  final CustomerModel customer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        onTap: () => Get.toNamed(
          AppRoutes.customerDetail,
          arguments: {'id': customer.id},
        ),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Text(
            customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
            style: TextStyle(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(customer.name, style: theme.textTheme.titleSmall),
        subtitle: customer.phone != null
            ? Text(customer.phone!, style: theme.textTheme.bodySmall)
            : null,
        trailing: const Icon(Icons.chevron_right_rounded, size: 18),
      ),
    );
  }
}
