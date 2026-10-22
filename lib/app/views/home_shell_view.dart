import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/database/app_database.dart';
import '../../core/database/database_impl.dart';
import '../../core/utils/app_routes.dart';
import '../../core/widgets/app_widgets.dart';
import '../../features/customers/views/customers_list_view.dart';
import '../../features/invoices/views/all_invoices_view.dart';
import '../../features/payments/views/all_payments_view.dart';
import '../../features/settings/views/settings_view.dart';
import 'home_overview_view.dart';

/// Navigation destination data model.
class _NavDestination {
  const _NavDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.route,
  });
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String route;
}

const _destinations = [
  _NavDestination(
    label: 'nav_home',
    icon: Icons.home_outlined,
    selectedIcon: Icons.home_rounded,
    route: AppRoutes.home,
  ),
  _NavDestination(
    label: 'nav_customers',
    icon: Icons.people_outline_rounded,
    selectedIcon: Icons.people_rounded,
    route: AppRoutes.customers,
  ),
  _NavDestination(
    label: 'nav_invoices',
    icon: Icons.receipt_outlined,
    selectedIcon: Icons.receipt_rounded,
    route: AppRoutes.invoices,
  ),
  _NavDestination(
    label: 'nav_payments',
    icon: Icons.payments_outlined,
    selectedIcon: Icons.payments_rounded,
    route: AppRoutes.payments,
  ),
  _NavDestination(
    label: 'nav_settings',
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings_rounded,
    route: AppRoutes.settings,
  ),
];

/// Adaptive shell that hosts primary navigation:
/// - Mobile   → BottomNavigationBar with Badges
/// - Tablet   → NavigationRail (collapsed) with Badges
/// - Desktop  → NavigationRail (extended) with Badges
class HomeShellView extends StatefulWidget {
  const HomeShellView({super.key});

  @override
  State<HomeShellView> createState() => _HomeShellViewState();
}

class _HomeShellViewState extends State<HomeShellView> {
  int _selectedIndex = 0;

  void _onDestinationSelected(int index) {
    setState(() => _selectedIndex = index);
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return const HomeOverviewView();
      case 1:
        return const CustomersListView();
      case 2:
        return const AllInvoicesView();
      case 3:
        return const AllPaymentsView();
      case 4:
        return const SettingsView();
      default:
        return const HomeOverviewView();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dao = DatabaseService.to.dao;

    return StreamBuilder<WorkspaceStats>(
      stream: dao.watchWorkspaceStats(),
      builder: (context, snapshot) {
        final stats = snapshot.data;

        return ResponsiveLayout(
          mobile: _MobileShell(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onDestinationSelected,
            body: _buildBody(),
            stats: stats,
          ),
          tablet: _RailShell(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onDestinationSelected,
            body: _buildBody(),
            extended: false,
            stats: stats,
          ),
          desktop: _RailShell(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onDestinationSelected,
            body: _buildBody(),
            extended: true,
            stats: stats,
          ),
        );
      },
    );
  }
}

// ─── Helper for Badged Navigation Icons ────────────────────────────────────────

Widget _buildNavBadge({
  required _NavDestination destination,
  required WorkspaceStats? stats,
  required bool isSelected,
}) {
  final icon = Icon(isSelected ? destination.selectedIcon : destination.icon);
  if (stats == null) return icon;

  int count = 0;
  if (destination.route == AppRoutes.customers) {
    count = stats.customersCount;
  } else if (destination.route == AppRoutes.invoices) {
    count = stats.invoicesCount;
  } else if (destination.route == AppRoutes.payments) {
    count = stats.paymentsCount;
  }

  if (count <= 0) return icon;

  return Badge(
    label: Text(
      '$count',
      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
    ),
    child: icon,
  );
}

// ─── Mobile shell ────────────────────────────────────────────────────────────

class _MobileShell extends StatelessWidget {
  const _MobileShell({
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.body,
    required this.stats,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget body;
  final WorkspaceStats? stats;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: _destinations
            .map(
              (d) => NavigationDestination(
                icon: _buildNavBadge(
                  destination: d,
                  stats: stats,
                  isSelected: false,
                ),
                selectedIcon: _buildNavBadge(
                  destination: d,
                  stats: stats,
                  isSelected: true,
                ),
                label: d.label.tr,
              ),
            )
            .toList(),
      ),
    );
  }
}

// ─── Tablet / Desktop rail shell ─────────────────────────────────────────────

class _RailShell extends StatelessWidget {
  const _RailShell({
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.body,
    required this.extended,
    required this.stats,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget body;
  final bool extended;
  final WorkspaceStats? stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Row(
        children: [
          // ── Navigation rail ───────────────────────────────────────────────
          NavigationRail(
            extended: extended,
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
            destinations: _destinations
                .map(
                  (d) => NavigationRailDestination(
                    icon: _buildNavBadge(
                      destination: d,
                      stats: stats,
                      isSelected: false,
                    ),
                    selectedIcon: _buildNavBadge(
                      destination: d,
                      stats: stats,
                      isSelected: true,
                    ),
                    label: Text(d.label.tr),
                  ),
                )
                .toList(),
          ),
          const VerticalDivider(width: 1, thickness: 1),
          // ── Content area ──────────────────────────────────────────────────
          Expanded(child: body),
        ],
      ),
    );
  }
}
