import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/utils/app_routes.dart';
import '../../core/widgets/app_widgets.dart';
import '../../features/customers/views/customers_list_view.dart';
import '../../features/settings/views/settings_view.dart';
import '../../features/accounting/views/accounting_pages.dart';

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

/// Adaptive shell that hosts the primary navigation:
/// - Mobile   → BottomNavigationBar
/// - Tablet   → NavigationRail (collapsed)
/// - Desktop  → Persistent NavigationDrawer / NavigationRail (extended)
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
        return const AccountingPage(section:AccountingSection.overview);
      case 2:
        return const AccountingPage(section:AccountingSection.invoices);
      case 3:
        return const AccountingPage(section:AccountingSection.payments);
      case 1:
        return const CustomersListView();
      case 4:
        return const SettingsView();
      default:
        return const AccountingPage(section:AccountingSection.overview);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _MobileShell(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onDestinationSelected,
        body: _buildBody(),
      ),
      tablet: _RailShell(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onDestinationSelected,
        body: _buildBody(),
        extended: false,
      ),
      desktop: _RailShell(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onDestinationSelected,
        body: _buildBody(),
        extended: true,
      ),
    );
  }
}

// ─── Mobile shell ────────────────────────────────────────────────────────────

class _MobileShell extends StatelessWidget {
  const _MobileShell({
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.body,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        destinations: _destinations
            .map(
              (d) => NavigationDestination(
                icon: Icon(d.icon),
                selectedIcon: Icon(d.selectedIcon),
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
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget body;
  final bool extended;

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
              child: Column(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.receipt_long_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  if (extended) ...[
                    const SizedBox(width: 12),
                  ],
                ],
              ),
            ),
            destinations: _destinations
                .map(
                  (d) => NavigationRailDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selectedIcon),
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
