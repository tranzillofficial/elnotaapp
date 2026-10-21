import 'package:drift/drift.dart';

/// Additive local migration only. Never submitted to PostgreSQL/Supabase.
/// The SQL cache uses the existing web table/column names; local domain tables
/// keep Flutter's richer financial model and integer minor units.
abstract final class CompatibilitySchema {
  static const addedColumns = {
    'customers': {'address': "TEXT NOT NULL DEFAULT ''"},
    'invoices': {
      'method': "TEXT NOT NULL DEFAULT 'credit' CHECK(method IN ('cash','credit','installment'))",
      'entry_mode': "TEXT CHECK(entry_mode IN ('products','amount'))",
      'source_json': 'TEXT',
    },
    'payments': {
      'legacy_invoice_id': 'TEXT',
      'source_json': 'TEXT',
    },
  };

  static const createStatements = <String>[
    '''CREATE TABLE IF NOT EXISTS products (
      id TEXT PRIMARY KEY, workspace_id TEXT NOT NULL, name TEXT NOT NULL,
      unit_price_minor INTEGER NOT NULL DEFAULT 0 CHECK(unit_price_minor >= 0),
      barcode TEXT NOT NULL DEFAULT '', image TEXT, archived INTEGER NOT NULL DEFAULT 0,
      category TEXT, box_quantity INTEGER CHECK(box_quantity > 0), item_number TEXT,
      price_missing INTEGER NOT NULL DEFAULT 0, notes TEXT, source_json TEXT,
      version INTEGER NOT NULL DEFAULT 0, created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL, deleted_at INTEGER
    )''',
    'CREATE INDEX IF NOT EXISTS products_ws_barcode ON products(workspace_id,barcode)',
    '''CREATE TABLE IF NOT EXISTS business_settings (
      workspace_id TEXT PRIMARY KEY, business_name TEXT NOT NULL DEFAULT '',
      phone TEXT NOT NULL DEFAULT '', address TEXT NOT NULL DEFAULT '',
      currency TEXT NOT NULL DEFAULT 'جنيه', source_json TEXT,
      updated_at INTEGER NOT NULL
    )''',
    '''CREATE TABLE IF NOT EXISTS installment_plans (
      id TEXT PRIMARY KEY, workspace_id TEXT NOT NULL, customer_id TEXT NOT NULL,
      invoice_id TEXT, total_minor INTEGER NOT NULL CHECK(total_minor > 0),
      installment_count INTEGER NOT NULL CHECK(installment_count BETWEEN 1 AND 120),
      start_date INTEGER NOT NULL, version INTEGER NOT NULL DEFAULT 0,
      created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL, deleted_at INTEGER
    )''',
    '''CREATE TABLE IF NOT EXISTS installment_schedule (
      id TEXT PRIMARY KEY, plan_id TEXT NOT NULL, installment_number INTEGER NOT NULL,
      amount_minor INTEGER NOT NULL, due_date INTEGER NOT NULL,
      status TEXT NOT NULL DEFAULT 'pending', paid_minor INTEGER NOT NULL DEFAULT 0,
      paid_at INTEGER, created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL
    )''',
    'CREATE INDEX IF NOT EXISTS installment_plan_ws ON installment_plans(workspace_id,invoice_id)',
    'CREATE UNIQUE INDEX IF NOT EXISTS installment_schedule_order ON installment_schedule(plan_id,installment_number)',
    '''CREATE TABLE IF NOT EXISTS elnota_accounts (
      user_id TEXT PRIMARY KEY, email TEXT NOT NULL, business_name TEXT NOT NULL DEFAULT '',
      activated_at TEXT, cloud_until TEXT, created_at TEXT NOT NULL,
      printing_enabled INTEGER NOT NULL DEFAULT 0, cloud_plan TEXT,
      suspended_at TEXT, deleted_at TEXT, suspended_activation_at TEXT,
      suspended_cloud_until TEXT, suspended_printing INTEGER
    )''',
    '''CREATE TABLE IF NOT EXISTS elnota_requests (
      id TEXT PRIMARY KEY, user_id TEXT NOT NULL, plan TEXT NOT NULL,
      amount INTEGER, phone TEXT NOT NULL, reference TEXT NOT NULL,
      status TEXT NOT NULL DEFAULT 'pending', created_at TEXT NOT NULL,
      reviewed_at TEXT, reviewed_by TEXT, submitted_email TEXT, submitted_business_name TEXT
    )''',
    '''CREATE TABLE IF NOT EXISTS elnota_cloud (
      user_id TEXT PRIMARY KEY, data TEXT NOT NULL, revision INTEGER NOT NULL,
      updated_at TEXT NOT NULL
    )''',
    '''CREATE TABLE IF NOT EXISTS elnota_backups (
      id TEXT PRIMARY KEY, user_id TEXT NOT NULL, data TEXT NOT NULL,
      revision INTEGER NOT NULL, created_at TEXT NOT NULL
    )''',
    '''CREATE TABLE IF NOT EXISTS elnota_daily_backups (
      user_id TEXT PRIMARY KEY, data TEXT NOT NULL, revision INTEGER NOT NULL,
      updated_at TEXT NOT NULL
    )''',
    '''CREATE TABLE IF NOT EXISTS elnota_device_backup_files (
      id TEXT PRIMARY KEY, user_id TEXT NOT NULL, device_id TEXT NOT NULL,
      backup_day TEXT NOT NULL, captured_at TEXT NOT NULL, uploaded_at TEXT NOT NULL,
      data TEXT NOT NULL, size_bytes INTEGER
    )''',
    '''CREATE TABLE IF NOT EXISTS elnota_catalog_imports (
      id TEXT PRIMARY KEY, user_id TEXT NOT NULL, payload TEXT NOT NULL, created_at TEXT NOT NULL
    )''',
    '''CREATE TABLE IF NOT EXISTS web_document_staging (
      id TEXT PRIMARY KEY, source_user_id TEXT NOT NULL, workspace_id TEXT NOT NULL,
      document_json TEXT NOT NULL, validation_json TEXT NOT NULL,
      source_revision INTEGER, created_at INTEGER NOT NULL
    )''',
    'CREATE INDEX IF NOT EXISTS web_document_staging_owner ON web_document_staging(workspace_id,source_user_id)',
  ];

  static Future<void> apply(GeneratedDatabase db) async {
    await db.transaction(() async {
      for (final table in addedColumns.entries) {
        final columns = await db.customSelect('PRAGMA table_info(${table.key})').get();
        final names = columns.map((r) => r.read<String>('name')).toSet();
        for (final column in table.value.entries) {
          if (!names.contains(column.key)) {
            await db.customStatement('ALTER TABLE ${table.key} ADD COLUMN ${column.key} ${column.value}');
          }
        }
      }
      for (final sql in createStatements) { await db.customStatement(sql); }
      // Backfill only the newly introduced alias. Never reinterpret money/status.
      await db.customStatement("UPDATE invoices SET entry_mode = CASE WHEN is_manual_amount = 1 THEN 'amount' ELSE 'products' END WHERE entry_mode IS NULL");
    });
  }
}
