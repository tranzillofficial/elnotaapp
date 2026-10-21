/// Names from elnotaapp/db_structure's production schema reference (2026-10-20).
/// These are contracts, not instructions to create/replace server tables.
abstract final class ElnotaWebContract {
  static const accounts = 'elnota_accounts';
  static const requests = 'elnota_requests';
  static const cloud = 'elnota_cloud';
  static const backups = 'elnota_backups';
  static const dailyBackups = 'elnota_daily_backups';
  static const deviceBackupFiles = 'elnota_device_backup_files';
  static const catalogImports = 'elnota_catalog_imports';
  static const latestDeviceBackups = 'elnota_latest_device_backups';

  static const register = 'elnota_register';
  static const isAdmin = 'elnota_is_admin';
  static const review = 'elnota_review';
  static const sync = 'elnota_sync';
  static const dailySnapshot = 'elnota_daily_snapshot';
  static const restoreDaily = 'elnota_restore_daily';
  static const uploadDeviceBackup = 'elnota_upload_device_backup';
  static const manageAccount = 'elnota_manage_account';
  static const manageCloud = 'elnota_manage_cloud';
  static const setPrinting = 'elnota_set_printing';

  static const plans = {'basic', 'cloud_month', 'cloud_year'};
  static const cloudPlans = {'month', 'year'};
  static const requestStatuses = {'pending', 'approved', 'rejected'};
  static const paymentMethods = {'cash', 'credit', 'installment'};
  static const entryModes = {'products', 'amount'};
  static const maxCloudBytes = 10485760;

  /// Business entities live inside elnota_cloud.data on today's website.
  /// They are NOT independent public tables yet.
  static const ledgerKeys = {
    'schemaVersion', 'syncImages', 'customerPayments', 'customers', 'products',
    'invoices', 'settings', 'updatedAt', 'categories', 'fourFieldCatalog',
    'catalogImports',
  };

  /// Explicit aliases preserve existing Flutter installs and minor-unit money.
  static const customerFields = {
    'id': 'id', 'name': 'name', 'phone': 'phone',
    'address': 'address', 'notes': 'notes',
  };
  static const productFields = {
    'id': 'id', 'name': 'name', 'price': 'unit_price_minor',
    'barcode': 'barcode', 'image': 'image', 'archived': 'archived',
    'category': 'category', 'boxQuantity': 'box_quantity',
    'itemNumber': 'item_number', 'priceMissing': 'price_missing',
  };
  static const invoiceFields = {
    'id': 'id', 'number': 'invoice_number', 'customerId': 'customer_id',
    'date': 'invoice_date', 'dueDate': 'due_date', 'notes': 'notes',
    'method': 'method', 'entryMode': 'entry_mode', 'lines': 'invoice_items',
    'payments': 'payments', 'voided': 'status',
    'installmentPlan': 'installment_plans',
  };
  static const lineFields = {
    'productId': 'product_id', 'name': 'description', 'price': 'unit_price_minor',
    'quantity': 'quantity',
  };
  static const paymentFields = {
    'id': 'id', 'customerId': 'customer_id', 'amount': 'amount_minor',
    'date': 'payment_date', 'note': 'notes',
  };
  static const settingsFields = {
    'businessName': 'business_name', 'phone': 'phone',
    'address': 'address', 'currency': 'currency',
  };
  static const installmentFields = {
    'months': 'installment_count', 'financedAmount': 'total_minor',
    'firstDueDate': 'start_date',
  };
}
