import '../../features/admin/views/admin_dashboard_view.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../../core/services/supabase_service.dart';
import '../../features/auth/views/device_login_view.dart';
import '../../features/customers/views/customer_statement_view.dart';
import 'package:get/get.dart';
import '../../core/utils/app_routes.dart';
import '../../features/auth/bindings/auth_binding.dart';
import '../../features/auth/views/login_view.dart';
import '../../features/customers/bindings/customers_binding.dart';
import '../../features/customers/views/customer_detail_view.dart';
import '../../features/customers/views/customer_form_view.dart';
import '../../features/invoices/bindings/invoices_binding.dart';
import '../../features/invoices/views/invoice_detail_view.dart';
import '../../features/invoices/views/invoice_form_view.dart';
import '../../features/payments/bindings/payments_binding.dart';
import '../../features/payments/views/add_payment_view.dart';
import '../../features/payments/views/all_payments_view.dart';
import '../../features/settings/bindings/settings_binding.dart';
import '../views/home_shell_view.dart';
import '../views/splash_view.dart';

/// Central route table for [GetMaterialApp].
/// Every named route in [AppRoutes] must appear here.
class AppPages {
  AppPages._();

  static const initial = AppRoutes.splash;

  static final routes = <GetPage>[
    // ── Splash ──────────────────────────────────────────────────────────────
    GetPage(name: AppRoutes.splash, page: () => const SplashView()),

    GetPage(name: AppRoutes.deviceLogin, page: () => const DeviceLoginView()),
    GetPage(
      name: AppRoutes.admin,
      middlewares: [WebSessionGuard()],
      page: () => const AdminDashboardView(),
    ),
    // ── Main shell ──────────────────────────────────────────────────────────
    GetPage(name: AppRoutes.home, page: () => const HomeShellView()),

    // ── Settings ────────────────────────────────────────────────────────────
    GetPage(
      name: AppRoutes.settings,
      middlewares: [WebSessionGuard()],
      page: () => const HomeShellView(initialIndex: 4),
      binding: SettingsBinding(),
    ),

    // ── Customers ───────────────────────────────────────────────────────────
    GetPage(
      name: AppRoutes.customers,
      middlewares: [WebSessionGuard()],
      page: () => const HomeShellView(initialIndex: 1),
      binding: CustomersBinding(),
    ),
    GetPage(
      name: AppRoutes.customerDetail,
      middlewares: [WebSessionGuard()],
      page: () => const CustomerDetailView(),
    ),
    GetPage(
      name: AppRoutes.customerCreate,
      middlewares: [WebSessionGuard()],
      page: () => const CustomerFormView(),
    ),

    GetPage(
      name: AppRoutes.customerStatement,
      middlewares: [WebSessionGuard()],
      page: () => const CustomerStatementView(),
    ),

    // ── Invoices ────────────────────────────────────────────────────────────
    GetPage(
      name: AppRoutes.invoices,
      middlewares: [WebSessionGuard()],
      page: () => const HomeShellView(initialIndex: 2),
      binding: InvoicesBinding(),
    ),
    GetPage(
      name: AppRoutes.invoiceCreate,
      middlewares: [WebSessionGuard()],
      opaque: false,
      transition: Transition.fadeIn,
      page: () => const InvoiceFormView(),
      binding: InvoicesBinding(),
    ),
    GetPage(
      name: AppRoutes.invoiceDetail,
      middlewares: [WebSessionGuard()],
      page: () => const InvoiceDetailView(),
      binding: InvoicesBinding(),
    ),

    // ── Auth ────────────────────────────────────────────────────────────
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginView(),
      binding: AuthBinding(),
    ),

    // ── Payments ────────────────────────────────────────────────────────────
    GetPage(
      name: AppRoutes.payments,
      middlewares: [WebSessionGuard()],
      page: () => const AllPaymentsView(),
      binding: PaymentsBinding(),
    ),
    GetPage(
      name: AppRoutes.paymentCreate,
      middlewares: [WebSessionGuard()],
      opaque: false,
      transition: Transition.fadeIn,
      page: () => const AddPaymentView(),
      binding: PaymentsBinding(),
    ),
  ];
}

class WebSessionGuard extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    if (kIsWeb &&
        (!Get.isRegistered<SupabaseService>() ||
            SupabaseService.to.client?.auth.currentSession == null)) {
      return const RouteSettings(name: AppRoutes.deviceLogin);
    }
    return null;
  }
}
