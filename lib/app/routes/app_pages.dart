import 'package:get/get.dart';
import '../../core/utils/app_routes.dart';
import '../../features/auth/bindings/auth_binding.dart';
import '../../features/auth/views/login_view.dart';
import '../../features/customers/bindings/customers_binding.dart';
import '../../features/customers/views/customer_detail_view.dart';
import '../../features/customers/views/customer_form_view.dart';
import '../../features/customers/views/customers_list_view.dart';
import '../../features/invoices/bindings/invoices_binding.dart';
import '../../features/invoices/views/all_invoices_view.dart';
import '../../features/invoices/views/invoice_detail_view.dart';
import '../../features/invoices/views/invoice_form_view.dart';
import '../../features/payments/bindings/payments_binding.dart';
import '../../features/payments/views/add_payment_view.dart';
import '../../features/payments/views/all_payments_view.dart';
import '../../features/settings/bindings/settings_binding.dart';
import '../../features/settings/views/settings_view.dart';
import '../views/home_shell_view.dart';
import '../views/splash_view.dart';

/// Central route table for [GetMaterialApp].
/// Every named route in [AppRoutes] must appear here.
class AppPages {
  AppPages._();

  static const initial = AppRoutes.splash;

  static final routes = <GetPage>[
    // ── Splash ──────────────────────────────────────────────────────────────
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashView(),
    ),

    // ── Main shell ──────────────────────────────────────────────────────────
    GetPage(
      name: AppRoutes.home,
      page: () => const HomeShellView(),
    ),

    // ── Settings ────────────────────────────────────────────────────────────
    GetPage(
      name: AppRoutes.settings,
      page: () => const SettingsView(),
      binding: SettingsBinding(),
    ),

    // ── Customers ───────────────────────────────────────────────────────────
    GetPage(
      name: AppRoutes.customers,
      page: () => const CustomersListView(),
      binding: CustomersBinding(),
    ),
    GetPage(
      name: AppRoutes.customerDetail,
      page: () => const CustomerDetailView(),
    ),
    GetPage(
      name: AppRoutes.customerCreate,
      page: () => const CustomerFormView(),
    ),

    // ── Invoices ────────────────────────────────────────────────────────────
    GetPage(
      name: AppRoutes.invoices,
      page: () => const AllInvoicesView(),
      binding: InvoicesBinding(),
    ),
    GetPage(
      name: AppRoutes.invoiceCreate,
      page: () => const InvoiceFormView(),
      binding: InvoicesBinding(),
    ),
    GetPage(
      name: AppRoutes.invoiceDetail,
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
      page: () => const AllPaymentsView(),
      binding: PaymentsBinding(),
    ),
    GetPage(
      name: AppRoutes.paymentCreate,
      page: () => const AddPaymentView(),
      binding: PaymentsBinding(),
    ),
  ];
}
