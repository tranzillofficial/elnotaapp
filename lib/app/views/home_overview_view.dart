import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/database/app_database.dart';
import '../../core/database/database_impl.dart';
import '../../core/utils/app_routes.dart';
import '../../core/utils/money_utils.dart';
import '../../core/widgets/sync_status_badge.dart';

/// Dashboard / Overview tab for the main navigation shell.
/// Streams live financial stats and recent activities in real time.
class HomeOverviewView extends StatelessWidget {
  const HomeOverviewView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dao = DatabaseService.to.dao;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'nav_home'.tr,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: SyncStatusBadge(),
          ),
        ],
      ),
      body: StreamBuilder<WorkspaceStats>(
        stream: dao.watchWorkspaceStats(),
        builder: (context, statsSnap) {
          final stats =
              statsSnap.data ??
              const WorkspaceStats(
                customersCount: 0,
                invoicesCount: 0,
                paymentsCount: 0,
                totalInvoicedMinor: 0,
                totalCollectedMinor: 0,
              );

          return RefreshIndicator(
            onRefresh: () async {
              // Trigger any background sync if desired
              await Future.delayed(const Duration(milliseconds: 300));
            },
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                // ─── Quick Actions ───────────────────────────────────────────
                _buildQuickActions(context),
                const SizedBox(height: 16),

                // ─── Financial KPI Cards ─────────────────────────────────────
                _buildStatsGrid(context, stats),
                const SizedBox(height: 24),

                // ─── Recent Activity Section Header ──────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'آخر الحركات والعمليات',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'مباشر',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // ─── Recent Activity Stream ──────────────────────────────────
                StreamBuilder<List<RecentActivityItem>>(
                  stream: dao.watchRecentActivities(limit: 10),
                  builder: (context, activitySnap) {
                    if (activitySnap.connectionState ==
                            ConnectionState.waiting &&
                        !activitySnap.hasData) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator.adaptive(),
                        ),
                      );
                    }

                    final activities = activitySnap.data ?? [];
                    if (activities.isEmpty) {
                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            color: theme.colorScheme.outlineVariant,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 32,
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.receipt_long_outlined,
                                size: 48,
                                color: theme.colorScheme.outline,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'لا توجد حركات مسجلة حتى الآن',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'قم بإضافة عميل أو إنشاء أول فاتورة للبدء',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: activities.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final act = activities[index];
                        final isInv = act.isInvoice;
                        return Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            side: BorderSide(
                              color: theme.colorScheme.outlineVariant,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isInv
                                  ? theme.colorScheme.primaryContainer
                                  : Colors.green.withValues(alpha: 0.15),
                              child: Icon(
                                isInv
                                    ? Icons.receipt_outlined
                                    : Icons.arrow_downward_rounded,
                                color: isInv
                                    ? theme.colorScheme.onPrimaryContainer
                                    : Colors.green,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              act.customerName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              '${isInv ? 'فاتورة' : 'دفعة نقدية'} • ${act.date.year}-${act.date.month.toString().padLeft(2, '0')}-${act.date.day.toString().padLeft(2, '0')}${act.notes != null ? ' • ${act.notes}' : ''}',
                              style: theme.textTheme.bodySmall,
                            ),
                            trailing: Text(
                              '${isInv ? '' : '+ '}${MoneyUtils.formatMinor(act.amountMinor)}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isInv
                                    ? theme.colorScheme.onSurface
                                    : Colors.green,
                              ),
                            ),
                            onTap: () {
                              if (isInv) {
                                Get.toNamed(
                                  AppRoutes.invoiceDetail,
                                  arguments: {'id': act.id},
                                );
                              } else {
                                Get.toNamed(
                                  AppRoutes.customerDetail,
                                  arguments: {'id': act.customerId},
                                );
                              }
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _QuickActionButton(
              icon: Icons.person_add_outlined,
              label: 'عميل جديد',
              color: theme.colorScheme.primary,
              onTap: () => Get.toNamed(AppRoutes.customerCreate),
            ),
            _QuickActionButton(
              icon: Icons.receipt_outlined,
              label: 'فاتورة جديدة',
              color: const Color(0xFF2E7D32),
              onTap: () => Get.toNamed(AppRoutes.invoiceCreate),
            ),
            _QuickActionButton(
              icon: Icons.payments_outlined,
              label: 'تسجيل دفعة',
              color: const Color(0xFFE65100),
              onTap: () => Get.toNamed(AppRoutes.paymentCreate),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, WorkspaceStats stats) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        // Primary big banner: Total Receivables (المديونية / المستحقات)
        Card(
          elevation: 0,
          color: isDark
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
              : const Color(0xFFE8F5E9),
          shape: RoundedRectangleBorder(
            side: BorderSide(
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'إجمالي المستحقات (الديون)',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      MoneyUtils.formatMinor(stats.totalReceivablesMinor),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.account_balance_wallet_rounded,
                    color: theme.colorScheme.primary,
                    size: 28,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // 3 Secondary Cards Row: Collected, Invoices Count, Customers Count
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'إجمالي المحصل',
                value: MoneyUtils.formatMinor(stats.totalCollectedMinor),
                icon: Icons.check_circle_outline_rounded,
                iconColor: Colors.green,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MetricCard(
                title: 'عدد العملاء',
                value: '${stats.customersCount}',
                icon: Icons.people_outline_rounded,
                iconColor: Colors.blue,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MetricCard(
                title: 'عدد الفواتير',
                value: '${stats.invoicesCount}',
                icon: Icons.receipt_long_outlined,
                iconColor: Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
