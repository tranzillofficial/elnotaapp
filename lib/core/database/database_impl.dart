import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

// ─── Domain Models ───────────────────────────────────────────────────────────

class CustomerRow {
  const CustomerRow({
    required this.id,
    required this.workspaceId,
    required this.name,
    this.phone,
    this.address = '',
    this.notes,
    required this.version,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  final String id;
  final String workspaceId;
  final String name;
  final String? phone;
  final String address;
  final String? notes;
  final int version;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
}

class InvoiceRow {
  const InvoiceRow({
    required this.id,
    required this.workspaceId,
    required this.customerId,
    this.invoiceNumber,
    this.method = 'credit',
    this.entryMode,
    required this.status,
    required this.totalMinor,
    required this.discountMinor,
    this.notes,
    required this.isManualAmount,
    required this.invoiceDate,
    this.dueDate,
    required this.version,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  final String id;
  final String workspaceId;
  final String customerId;
  final String? invoiceNumber;
  final String method;
  final String? entryMode;
  final String status;
  final int totalMinor;
  final int discountMinor;
  final String? notes;
  final bool isManualAmount;
  final DateTime invoiceDate;
  final DateTime? dueDate;
  final int version;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  /// Net amount after discount
  int get netMinor => totalMinor - discountMinor;
}

class InvoiceItemRow {
  const InvoiceItemRow({
    required this.id,
    required this.invoiceId,
    this.productId,
    required this.description,
    required this.quantity,
    required this.unitPriceMinor,
    required this.discountMinor,
    required this.createdAt,
  });
  final String id;
  final String invoiceId;
  final String? productId;
  final String description;
  final int quantity;
  final int unitPriceMinor;
  final int discountMinor;
  final DateTime createdAt;

  int get lineTotal => quantity * unitPriceMinor - discountMinor;
}

class PaymentRow {
  const PaymentRow({
    required this.id,
    required this.workspaceId,
    required this.customerId,
    required this.amountMinor,
    this.notes,
    this.legacyInvoiceId,
    required this.paymentDate,
    required this.idempotencyKey,
    required this.version,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  final String id;
  final String workspaceId;
  final String customerId;
  final int amountMinor;
  final String? notes;
  final String? legacyInvoiceId;
  final DateTime paymentDate;
  final String idempotencyKey;
  final int version;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
}

class LedgerEntryRow {
  const LedgerEntryRow({
    required this.id,
    required this.workspaceId,
    required this.customerId,
    required this.sourceId,
    required this.eventType,
    required this.amountMinor,
    this.notes,
    required this.occurredAt,
    required this.createdAt,
  });
  final String id;
  final String workspaceId;
  final String customerId;
  final String sourceId;
  final String eventType;
  final int amountMinor;
  final String? notes;
  final DateTime occurredAt;
  final DateTime createdAt;
}

class CustomerBalance {
  const CustomerBalance({
    required this.customerId,
    required this.totalInvoicedMinor,
    required this.totalDiscountsMinor,
    required this.totalPaymentsMinor,
    required this.totalAdjustmentsMinor,
  });
  final String customerId;
  final int totalInvoicedMinor;
  final int totalDiscountsMinor;
  final int totalPaymentsMinor;
  final int totalAdjustmentsMinor;

  /// Positive = customer owes; negative = customer has credit.
  int get outstandingMinor =>
      totalInvoicedMinor -
      totalDiscountsMinor -
      totalPaymentsMinor +
      totalAdjustmentsMinor;
}

// ─── Database DAO ────────────────────────────────────────────────────────────

/// All DB access goes through this class.
/// Uses [customSelect] / [customInsert] / [customUpdate] to bypass
/// the missing drift_dev code-gen step.
class AppDao {
  AppDao(this._db, {this.workspaceId = 'default'});
  final String workspaceId;
  final _changes = StreamController<void>.broadcast();
  final GeneratedDatabase _db;
  final _uuid = const Uuid();

  String get _wsId => workspaceId;

  // ──────────────────────────────────────────────────────────────────────────
  // Customers
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> createTables() async {
    await _db.customStatement('''
      CREATE TABLE IF NOT EXISTS workspaces (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        currency_code TEXT NOT NULL DEFAULT 'EGP',
        owner_id TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        version INTEGER NOT NULL DEFAULT 0,
        deleted_at INTEGER
      )
    ''');
    await _db.customStatement('''
      CREATE TABLE IF NOT EXISTS customers (
        id TEXT PRIMARY KEY,
        workspace_id TEXT NOT NULL,
        name TEXT NOT NULL,
        phone TEXT,
        notes TEXT,
        version INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        deleted_at INTEGER
      )
    ''');
    await _db.customStatement('''
      CREATE INDEX IF NOT EXISTS customers_ws_idx ON customers(workspace_id)
    ''');
    await _db.customStatement('''
      CREATE TABLE IF NOT EXISTS invoices (
        id TEXT PRIMARY KEY,
        workspace_id TEXT NOT NULL,
        customer_id TEXT NOT NULL,
        invoice_number TEXT,
        status TEXT NOT NULL DEFAULT 'draft',
        total_minor INTEGER NOT NULL DEFAULT 0,
        discount_minor INTEGER NOT NULL DEFAULT 0,
        notes TEXT,
        is_manual_amount INTEGER NOT NULL DEFAULT 0,
        invoice_date INTEGER NOT NULL,
        due_date INTEGER,
        version INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        deleted_at INTEGER
      )
    ''');
    await _db.customStatement('''
      CREATE INDEX IF NOT EXISTS invoices_customer_idx ON invoices(customer_id)
    ''');
    await _db.customStatement('''
      CREATE TABLE IF NOT EXISTS invoice_items (
        id TEXT PRIMARY KEY,
        invoice_id TEXT NOT NULL,
        product_id TEXT,
        description TEXT NOT NULL,
        quantity INTEGER NOT NULL DEFAULT 1,
        unit_price_minor INTEGER NOT NULL DEFAULT 0,
        discount_minor INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL
      )
    ''');
    await _db.customStatement('''
      CREATE INDEX IF NOT EXISTS items_invoice_idx ON invoice_items(invoice_id)
    ''');
    await _db.customStatement('''
      CREATE TABLE IF NOT EXISTS payments (
        id TEXT PRIMARY KEY,
        workspace_id TEXT NOT NULL,
        customer_id TEXT NOT NULL,
        amount_minor INTEGER NOT NULL,
        notes TEXT,
        payment_date INTEGER NOT NULL,
        idempotency_key TEXT NOT NULL UNIQUE,
        version INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        deleted_at INTEGER
      )
    ''');
    await _db.customStatement('''
      CREATE INDEX IF NOT EXISTS payments_customer_idx ON payments(customer_id)
    ''');
    await _db.customStatement('''
      CREATE TABLE IF NOT EXISTS ledger_entries (
        id TEXT PRIMARY KEY,
        workspace_id TEXT NOT NULL,
        customer_id TEXT NOT NULL,
        source_id TEXT NOT NULL,
        event_type TEXT NOT NULL,
        amount_minor INTEGER NOT NULL,
        notes TEXT,
        occurred_at INTEGER NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');
    await _db.customStatement('''
      CREATE UNIQUE INDEX IF NOT EXISTS ledger_source_idx
        ON ledger_entries(workspace_id, source_id, event_type)
    ''');
    await _db.customStatement('''
      CREATE INDEX IF NOT EXISTS ledger_customer_idx ON ledger_entries(customer_id)
    ''');
    await _db.customStatement('''
      CREATE TABLE IF NOT EXISTS sync_outbox (
        operation_id TEXT PRIMARY KEY,
        workspace_id TEXT NOT NULL,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        operation_type TEXT NOT NULL,
        payload_json TEXT NOT NULL,
        base_version INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        attempts INTEGER NOT NULL DEFAULT 0,
        next_retry_at INTEGER,
        status TEXT NOT NULL DEFAULT 'pending',
        last_error TEXT
      )
    ''');
    await _db.customStatement('''
      CREATE TABLE IF NOT EXISTS sync_state (
        workspace_id TEXT PRIMARY KEY,
        last_cursor TEXT,
        last_success_at INTEGER,
        pending_count INTEGER NOT NULL DEFAULT 0,
        last_error TEXT,
        updated_at INTEGER NOT NULL
      )
    ''');
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Customer CRUD
  // ──────────────────────────────────────────────────────────────────────────

  Stream<List<CustomerRow>> watchCustomers({String? search}) => _observe(() async {
    final term = search?.trim() ?? '';
    final rows = await _db.customSelect(
      'SELECT * FROM customers WHERE workspace_id=? AND deleted_at IS NULL AND (name LIKE ? OR phone LIKE ?) ORDER BY name,id',
      variables: [Variable.withString(_wsId),Variable.withString('%$term%'),Variable.withString('%$term%')],
    ).get();
    return rows.map(_mapCustomer).toList();
  });

  Stream<CustomerRow?> watchCustomer(String id) => _observe(() async {
    final rows = await _db.customSelect('SELECT * FROM customers WHERE workspace_id=? AND id=? AND deleted_at IS NULL',
      variables: [Variable.withString(_wsId),Variable.withString(id)]).get();
    return rows.isEmpty ? null : _mapCustomer(rows.first);
  });

  Future<String> createCustomer({
    required String name,
    String? phone,
    String address = '',
    String? notes,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.transaction(() async {
      await _db.customInsert(
        '''INSERT INTO customers
             (id, workspace_id, name, phone, address, notes, version, created_at, updated_at)
           VALUES (?, ?, ?, ?, ?, ?, 0, ?, ?)''',
        variables: [
          Variable.withString(id),
          Variable.withString(_wsId),
          Variable.withString(name),
          phone != null ? Variable.withString(phone) : const Variable(null),
          Variable.withString(address),
          notes != null ? Variable.withString(notes) : const Variable(null),
          Variable.withInt(now),
          Variable.withInt(now),
        ],
      );
      await _enqueueOutbox(
        entityType: 'customer',
        entityId: id,
        operationType: 'create',
        payload: {'id': id, 'workspace_id': _wsId, 'name': name, 'phone': phone, 'address': address, 'notes': notes},
      );
    });
    refresh();
    return id;
  }

  Future<void> updateCustomer({
    required String id,
    required String name,
    String? phone,
    String address = '',
    String? notes,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.transaction(() async {
      await _requireCustomer(id);
      await _db.customUpdate(
        '''UPDATE customers
           SET name=?, phone=?, address=?, notes=?, updated_at=?, version=version+1
           WHERE id=? AND workspace_id=?''',
        variables: [
          Variable.withString(name),
          phone != null ? Variable.withString(phone) : const Variable(null),
          Variable.withString(address),
          notes != null ? Variable.withString(notes) : const Variable(null),
          Variable.withInt(now),
          Variable.withString(id),
          Variable.withString(_wsId),
        ],
        updateKind: UpdateKind.update,
      );
      await _enqueueOutbox(
        entityType: 'customer',
        entityId: id,
        operationType: 'update',
        payload: {'id': id, 'name': name, 'phone': phone, 'address': address, 'notes': notes},
      );
    });
    refresh();
  }

  Future<void> softDeleteCustomer(String id) async {
    await _requireCustomer(id);
    final history=await _db.customSelect('SELECT id FROM ledger_entries WHERE workspace_id=? AND customer_id=? LIMIT 1',
      variables:[Variable.withString(_wsId),Variable.withString(id)]).get();
    if(history.isNotEmpty) throw StateError('لا يمكن حذف عميل له معاملات مالية');
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.customUpdate(
      'UPDATE customers SET deleted_at=?, updated_at=? WHERE id=? AND workspace_id=?',
      variables: [
        Variable.withInt(now),
        Variable.withInt(now),
        Variable.withString(id),
        Variable.withString(_wsId),
      ],
      updateKind: UpdateKind.update,
    );
    await _enqueueOutbox(
      entityType: 'customer',
      entityId: id,
      operationType: 'delete',
      payload: {'id': id},
    );
    refresh();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Invoices
  // ──────────────────────────────────────────────────────────────────────────

  Stream<List<InvoiceRow>> watchInvoices(String customerId) => _observe(() async {
    final rows = await _db.customSelect('SELECT * FROM invoices WHERE workspace_id=? AND customer_id=? AND deleted_at IS NULL ORDER BY invoice_date DESC,id',
      variables: [Variable.withString(_wsId),Variable.withString(customerId)]).get();
    return rows.map(_mapInvoice).toList();
  });

  Stream<InvoiceRow?> watchInvoice(String id) => _observe(() async {
    final rows = await _db.customSelect('SELECT * FROM invoices WHERE workspace_id=? AND id=? AND deleted_at IS NULL',
      variables: [Variable.withString(_wsId),Variable.withString(id)]).get();
    return rows.isEmpty ? null : _mapInvoice(rows.first);
  });

  Future<List<InvoiceItemRow>> getInvoiceItems(String invoiceId) async {
    final rows = await _db.customSelect(
      'SELECT i.* FROM invoice_items i JOIN invoices v ON v.id=i.invoice_id WHERE i.invoice_id=? AND v.workspace_id=? ORDER BY i.created_at,i.id',
      variables: [Variable.withString(invoiceId),Variable.withString(_wsId)],
    ).get();
    return rows.map(_mapInvoiceItem).toList();
  }

  /// Creates a draft invoice (no ledger entry yet).
  /// Call [postInvoice] to post and create the ledger charge.
  Future<String> createInvoice({
    required String customerId,
    required int totalMinor,
    required bool isManualAmount,
    List<Map<String, dynamic>> items = const [],
    int discountMinor = 0,
    String? notes,
    DateTime? invoiceDate,
    DateTime? dueDate,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now().millisecondsSinceEpoch;
    final date = (invoiceDate ?? DateTime.now()).millisecondsSinceEpoch;
    await _db.customInsert(
      '''INSERT INTO invoices
           (id, workspace_id, customer_id, status, total_minor, discount_minor,
            notes, is_manual_amount, entry_mode, invoice_date, due_date,
            version, created_at, updated_at)
         VALUES (?, ?, ?, 'draft', ?, ?, ?, ?, ?, ?, ?, 0, ?, ?)''',
      variables: [
        Variable.withString(id),
        Variable.withString(_wsId),
        Variable.withString(customerId),
        Variable.withInt(totalMinor),
        Variable.withInt(discountMinor),
        notes != null ? Variable.withString(notes) : const Variable(null),
        Variable.withBool(isManualAmount),
        Variable.withString(isManualAmount ? 'amount' : 'products'),
        Variable.withInt(date),
        dueDate != null ? Variable.withInt(dueDate.millisecondsSinceEpoch) : const Variable(null),
        Variable.withInt(now),
        Variable.withInt(now),
      ],
    );
    // Insert line items
    for (final item in items) {
      final itemId = _uuid.v4();
      await _db.customInsert(
        '''INSERT INTO invoice_items
             (id, invoice_id, product_id, description, quantity,
              unit_price_minor, discount_minor, created_at)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?)''',
        variables: [
          Variable.withString(itemId),
          Variable.withString(id),
          item['product_id'] != null ? Variable.withString(item['product_id'] as String) : const Variable(null),
          Variable.withString(item['description'] as String),
          Variable.withInt((item['quantity'] as int?) ?? 1),
          Variable.withInt(item['unit_price_minor'] as int),
          Variable.withInt((item['discount_minor'] as int?) ?? 0),
          Variable.withInt(now),
        ],
      );
    }
    return id;
  }

  /// Posts a draft invoice: sets status='posted', writes ledger debit, enqueues outbox.
  Future<void> postInvoice(String invoiceId) async {
    final rows = await _db.customSelect(
      'SELECT * FROM invoices WHERE id = ? AND workspace_id=? AND deleted_at IS NULL LIMIT 1',
      variables: [Variable.withString(invoiceId),Variable.withString(_wsId)],
    ).get();
    if (rows.isEmpty) throw StateError('Invoice $invoiceId not found');
    final inv = _mapInvoice(rows.first);
    if (inv.status != 'draft') throw StateError('Invoice already posted or voided');

    final now = DateTime.now().millisecondsSinceEpoch;
    final netMinor = inv.netMinor;
    final ledgerId = _uuid.v4();

    // Atomic: update invoice + insert ledger + insert outbox
    await _db.transaction(() async {
      await _db.customUpdate(
        '''UPDATE invoices SET status='posted', updated_at=?, version=version+1
           WHERE id=? AND workspace_id=?''',
        variables: [Variable.withInt(now), Variable.withString(invoiceId),Variable.withString(_wsId)],
        updateKind: UpdateKind.update,
      );
      await _db.customInsert(
        '''INSERT INTO ledger_entries
             (id, workspace_id, customer_id, source_id, event_type,
              amount_minor, notes, occurred_at, created_at)
           VALUES (?, ?, ?, ?, 'invoice_charge', ?, ?, ?, ?)''',
        variables: [
          Variable.withString(ledgerId),
          Variable.withString(inv.workspaceId),
          Variable.withString(inv.customerId),
          Variable.withString(invoiceId),
          Variable.withInt(netMinor),
          inv.notes != null ? Variable.withString(inv.notes!) : const Variable(null),
          Variable.withInt(now),
          Variable.withInt(now),
        ],
      );
      await _enqueueOutbox(
        entityType: 'invoice',
        entityId: invoiceId,
        operationType: 'update',
        payload: {'id': invoiceId, 'status': 'posted'},
      );
    });
    refresh();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Payments (customer-level)
  // ──────────────────────────────────────────────────────────────────────────

  Stream<List<PaymentRow>> watchPayments(String customerId) => _observe(() async {
    final rows = await _db.customSelect('SELECT * FROM payments WHERE workspace_id=? AND customer_id=? AND deleted_at IS NULL ORDER BY payment_date DESC,id',
      variables: [Variable.withString(_wsId),Variable.withString(customerId)]).get();
    return rows.map(_mapPayment).toList();
  });

  /// Idempotent: if idempotency_key already exists, silently skips.
  Future<void> addPayment({
    required String customerId,
    required int amountMinor,
    required String idempotencyKey,
    String? notes,
    DateTime? paymentDate,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now().millisecondsSinceEpoch;
    final date = (paymentDate ?? DateTime.now()).millisecondsSinceEpoch;
    final ledgerId = _uuid.v4();

    if(amountMinor<=0) throw ArgumentError('المبلغ يجب أن يكون أكبر من صفر');
    await _db.transaction(() async {
      await _requireCustomer(customerId);
      final existing=await _db.customSelect('SELECT id FROM payments WHERE workspace_id=? AND idempotency_key=?',
        variables:[Variable.withString(_wsId),Variable.withString(idempotencyKey)]).get();
      if(existing.isNotEmpty) return;

      await _db.customInsert(
        '''INSERT INTO payments
             (id, workspace_id, customer_id, amount_minor, notes,
              payment_date, idempotency_key, version, created_at, updated_at)
           VALUES (?, ?, ?, ?, ?, ?, ?, 0, ?, ?)''',
        variables: [
          Variable.withString(id),
          Variable.withString(_wsId),
          Variable.withString(customerId),
          Variable.withInt(amountMinor),
          notes != null ? Variable.withString(notes) : const Variable(null),
          Variable.withInt(date),
          Variable.withString(idempotencyKey),
          Variable.withInt(now),
          Variable.withInt(now),
        ],
      );
      await _db.customInsert(
        '''INSERT INTO ledger_entries
             (id, workspace_id, customer_id, source_id, event_type,
              amount_minor, notes, occurred_at, created_at)
           VALUES (?, ?, ?, ?, 'payment_receipt', ?, ?, ?, ?)''',
        variables: [
          Variable.withString(ledgerId),
          Variable.withString(_wsId),
          Variable.withString(customerId),
          Variable.withString(id),
          Variable.withInt(-amountMinor), // negative = credit
          notes != null ? Variable.withString(notes) : const Variable(null),
          Variable.withInt(date),
          Variable.withInt(now),
        ],
      );
      await _enqueueOutbox(
        entityType: 'payment',
        entityId: id,
        operationType: 'create',
        payload: {
          'id': id,
          'workspace_id': _wsId,
          'customer_id': customerId,
          'amount_minor': amountMinor,
          'idempotency_key': idempotencyKey,
          'notes': notes,
        },
      );
    });
    refresh();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Balance (derived from ledger — never from mutable aggregates)
  // ──────────────────────────────────────────────────────────────────────────

  Stream<CustomerBalance> watchBalance(String customerId) => _observe(() => balance(customerId));

  Future<CustomerBalance> balance(String customerId) async {
    final rows = await _db.customSelect('''SELECT
      COALESCE(SUM(CASE WHEN event_type='invoice_charge' THEN amount_minor ELSE 0 END),0) AS invoiced,
      COALESCE(SUM(CASE WHEN event_type='discount' THEN -amount_minor ELSE 0 END),0) AS discounts,
      COALESCE(SUM(CASE WHEN event_type='payment_receipt' THEN -amount_minor ELSE 0 END),0) AS payments,
      COALESCE(SUM(CASE WHEN event_type IN ('refund','adjustment','reversal') THEN amount_minor ELSE 0 END),0) AS adjustments
      FROM ledger_entries WHERE workspace_id=? AND customer_id=?''',
      variables:[Variable.withString(_wsId),Variable.withString(customerId)]).get();
    final r=rows.single;
    return CustomerBalance(customerId:customerId,totalInvoicedMinor:r.read<int>('invoiced'),
      totalDiscountsMinor:r.read<int>('discounts'),totalPaymentsMinor:r.read<int>('payments'),
      totalAdjustmentsMinor:r.read<int>('adjustments'));
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Outbox
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> _enqueueOutbox({
    required String entityType,
    required String entityId,
    required String operationType,
    required Map<String, dynamic> payload,
  }) async {
    final opId = _uuid.v4();
    final now = DateTime.now().millisecondsSinceEpoch;
    final payloadJson = _encodePayload(payload);
    await _db.customInsert(
      '''INSERT OR IGNORE INTO sync_outbox
           (operation_id, workspace_id, entity_type, entity_id,
            operation_type, payload_json, base_version, created_at, status)
         VALUES (?, ?, ?, ?, ?, ?, 0, ?, 'pending')''',
      variables: [
        Variable.withString(opId),
        Variable.withString(_wsId),
        Variable.withString(entityType),
        Variable.withString(entityId),
        Variable.withString(operationType),
        Variable.withString(payloadJson),
        Variable.withInt(now),
      ],
    );
  }

  Future<List<Map<String, dynamic>>> getPendingOutbox({int limit = 50}) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final rows = await _db.customSelect(
      '''SELECT * FROM sync_outbox
         WHERE workspace_id = ? AND status = 'pending'
           AND (next_retry_at IS NULL OR next_retry_at <= ?)
         ORDER BY created_at ASC
         LIMIT ?''',
      variables: [
        Variable.withString(_wsId),
        Variable.withInt(now),
        Variable.withInt(limit),
      ],
    ).get();

    return rows.map((r) => r.data).toList();
  }

  Future<void> markOutboxSending(List<String> opIds) async {
    if (opIds.isEmpty) return;
    final placeholders = List.filled(opIds.length, '?').join(',');
    await _db.customUpdate(
      'UPDATE sync_outbox SET status = \'sending\' WHERE operation_id IN ($placeholders)',
      variables: opIds.map(Variable.withString).toList(),
      updateKind: UpdateKind.update,
    );
  }

  Future<void> markOutboxAcknowledged(List<String> opIds) async {
    if (opIds.isEmpty) return;
    final placeholders = List.filled(opIds.length, '?').join(',');
    await _db.customUpdate(
      'UPDATE sync_outbox SET status = \'acknowledged\' WHERE operation_id IN ($placeholders)',
      variables: opIds.map(Variable.withString).toList(),
      updateKind: UpdateKind.update,
    );
  }

  Future<void> markOutboxFailed(
    String opId,
    String error, {
    bool isPermanent = false,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (isPermanent) {
      await _db.customUpdate(
        '''UPDATE sync_outbox
           SET status = 'needs_attention', last_error = ?, attempts = attempts + 1
           WHERE operation_id = ?''',
        variables: [Variable.withString(error), Variable.withString(opId)],
        updateKind: UpdateKind.update,
      );
    } else {
      // Exponential backoff with capped delay: min(2^attempts * 5s, 300s)
      final rows = await _db.customSelect(
        'SELECT attempts FROM sync_outbox WHERE operation_id = ? LIMIT 1',
        variables: [Variable.withString(opId)],
      ).get();
      final currentAttempts = rows.isNotEmpty ? (rows.first.read<int>('attempts')) : 0;
      final delaySeconds = (1 << currentAttempts).clamp(5, 300);
      final nextRetry = now + (delaySeconds * 1000);

      await _db.customUpdate(
        '''UPDATE sync_outbox
           SET status = 'pending', last_error = ?, attempts = attempts + 1, next_retry_at = ?
           WHERE operation_id = ?''',
        variables: [
          Variable.withString(error),
          Variable.withInt(nextRetry),
          Variable.withString(opId),
        ],
        updateKind: UpdateKind.update,
      );
    }
  }

  Stream<int> watchPendingOutboxCount() => _observe(() async {
    final rows=await _db.customSelect("SELECT COUNT(*) AS cnt FROM sync_outbox WHERE workspace_id=? AND status IN ('pending','sending')",
      variables:[Variable.withString(_wsId)]).get();
    return rows.single.read<int>('cnt');
  });

  Future<Map<String, dynamic>?> getSyncState() async {
    final rows = await _db.customSelect(
      'SELECT * FROM sync_state WHERE workspace_id = ? LIMIT 1',
      variables: [Variable.withString(_wsId)],
    ).get();
    return rows.isEmpty ? null : rows.first.data;
  }

  Future<void> updateSyncState({
    String? lastCursor,
    int? lastSuccessAt,
    String? lastError,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.customStatement(
      '''INSERT INTO sync_state (workspace_id, last_cursor, last_success_at, last_error, updated_at)
         VALUES (?, ?, ?, ?, ?)
         ON CONFLICT(workspace_id) DO UPDATE SET
           last_cursor = COALESCE(excluded.last_cursor, sync_state.last_cursor),
           last_success_at = COALESCE(excluded.last_success_at, sync_state.last_success_at),
           last_error = excluded.last_error,
           updated_at = excluded.updated_at''',
      [
        _wsId,
        lastCursor,
        lastSuccessAt,
        lastError,
        now,
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Mappers
  // ──────────────────────────────────────────────────────────────────────────

  CustomerRow _mapCustomer(QueryRow r) => CustomerRow(
        id: r.read<String>('id'),
        workspaceId: r.read<String>('workspace_id'),
        name: r.read<String>('name'),
        phone: r.readNullable<String>('phone'),
        address: r.readNullable<String>('address') ?? '',
        notes: r.readNullable<String>('notes'),
        version: r.read<int>('version'),
        createdAt: DateTime.fromMillisecondsSinceEpoch(r.read<int>('created_at')),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(r.read<int>('updated_at')),
        deletedAt: r.readNullable<int>('deleted_at') != null
            ? DateTime.fromMillisecondsSinceEpoch(r.read<int>('deleted_at'))
            : null,
      );

  InvoiceRow _mapInvoice(QueryRow r) => InvoiceRow(
        id: r.read<String>('id'),
        workspaceId: r.read<String>('workspace_id'),
        customerId: r.read<String>('customer_id'),
        invoiceNumber: r.readNullable<String>('invoice_number'),
        method: r.readNullable<String>('method') ?? 'credit',
        entryMode: r.readNullable<String>('entry_mode'),
        status: r.read<String>('status'),
        totalMinor: r.read<int>('total_minor'),
        discountMinor: r.read<int>('discount_minor'),
        notes: r.readNullable<String>('notes'),
        isManualAmount: r.read<bool>('is_manual_amount'),
        invoiceDate: DateTime.fromMillisecondsSinceEpoch(r.read<int>('invoice_date')),
        dueDate: r.readNullable<int>('due_date') != null
            ? DateTime.fromMillisecondsSinceEpoch(r.read<int>('due_date'))
            : null,
        version: r.read<int>('version'),
        createdAt: DateTime.fromMillisecondsSinceEpoch(r.read<int>('created_at')),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(r.read<int>('updated_at')),
        deletedAt: r.readNullable<int>('deleted_at') != null
            ? DateTime.fromMillisecondsSinceEpoch(r.read<int>('deleted_at'))
            : null,
      );

  InvoiceItemRow _mapInvoiceItem(QueryRow r) => InvoiceItemRow(
        id: r.read<String>('id'),
        invoiceId: r.read<String>('invoice_id'),
        productId: r.readNullable<String>('product_id'),
        description: r.read<String>('description'),
        quantity: r.read<int>('quantity'),
        unitPriceMinor: r.read<int>('unit_price_minor'),
        discountMinor: r.read<int>('discount_minor'),
        createdAt: DateTime.fromMillisecondsSinceEpoch(r.read<int>('created_at')),
      );

  PaymentRow _mapPayment(QueryRow r) => PaymentRow(
        id: r.read<String>('id'),
        workspaceId: r.read<String>('workspace_id'),
        customerId: r.read<String>('customer_id'),
        amountMinor: r.read<int>('amount_minor'),
        notes: r.readNullable<String>('notes'),
        legacyInvoiceId: r.readNullable<String>('legacy_invoice_id'),
        paymentDate: DateTime.fromMillisecondsSinceEpoch(r.read<int>('payment_date')),
        idempotencyKey: r.read<String>('idempotency_key'),
        version: r.read<int>('version'),
        createdAt: DateTime.fromMillisecondsSinceEpoch(r.read<int>('created_at')),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(r.read<int>('updated_at')),
        deletedAt: r.readNullable<int>('deleted_at') != null
            ? DateTime.fromMillisecondsSinceEpoch(r.read<int>('deleted_at'))
            : null,
      );

  Future<void> close()=>_changes.close();

  void refresh() { if (!_changes.isClosed) _changes.add(null); }

  Stream<T> _observe<T>(Future<T> Function() read) => Stream<T>.multi((sink) {
    var cancelled=false, running=false, again=false;
    Future<void> load() async {
      if (running) { again=true; return; }
      running=true;
      do {
        again=false;
        try { final value=await read(); if (!cancelled) sink.add(value); }
        catch(e,st) { if (!cancelled) sink.addError(e,st); }
      } while(again && !cancelled);
      running=false;
    }
    final sub=_changes.stream.listen((_)=>load());
    sink.onCancel=() { cancelled=true; sub.cancel(); };
    load();
  });

  Stream<Map<String,List<Map<String,dynamic>>>> watchWorkspaceData() => _observe(readWorkspaceData);

  Future<Map<String,List<Map<String,dynamic>>>> readWorkspaceData() => _db.transaction(() async {
    final result=<String,List<Map<String,dynamic>>>{};
    for(final table in ['customers','invoices','payments','ledger_entries','business_settings']) {
      final rows=await _db.customSelect('SELECT * FROM $table WHERE workspace_id=?',
        variables:[Variable.withString(_wsId)]).get();
      result[table]=rows.map((r)=>r.data).toList();
    }
    final items=await _db.customSelect('SELECT i.* FROM invoice_items i JOIN invoices v ON v.id=i.invoice_id WHERE v.workspace_id=?',
      variables:[Variable.withString(_wsId)]).get();
    result['invoice_items']=items.map((r)=>r.data).toList();
    return result;
  });

  Future<void> saveBusinessSettings({required String businessName,required String phone,required String address}) async {
    await _db.transaction(() async {
      await _db.customStatement('''INSERT INTO business_settings(workspace_id,business_name,phone,address,currency,updated_at)
        VALUES (?,?,?,?,'جنيه',?) ON CONFLICT(workspace_id) DO UPDATE SET
        business_name=excluded.business_name,phone=excluded.phone,address=excluded.address,updated_at=excluded.updated_at''',
        [_wsId,businessName.trim(),phone.trim(),address.trim(),DateTime.now().millisecondsSinceEpoch]);
      await _enqueueOutbox(entityType:'settings',entityId:_wsId,operationType:'update',payload:{'businessName':businessName.trim(),'phone':phone.trim(),'address':address.trim()});
    });
    refresh();
  }

  Future<String> createAndPostInvoice({required String customerId,required int totalMinor,required bool isManualAmount,
    List<Map<String,dynamic>> items=const [],int discountMinor=0,String? notes,DateTime? invoiceDate,DateTime? dueDate}) async {
    final id=await _db.transaction(() async {
      await _requireCustomer(customerId);
      if (totalMinor<=0 || totalMinor>9007199254740991 || discountMinor<0 || discountMinor>totalMinor) throw ArgumentError('المبلغ أو الخصم غير صحيح');
      if (!isManualAmount) {
        var sum=0;
        if(items.isEmpty) throw ArgumentError('أضف أصناف الفاتورة');
        for(final i in items) {
          final q=i['quantity'] as int, price=i['unit_price_minor'] as int, discount=(i['discount_minor'] as int?)??0;
          if(q<=0 || price<0 || discount<0 || discount>q*price || (i['description'] as String).trim().isEmpty) throw ArgumentError('بيانات الصنف غير صحيحة');
          sum+=q*price-discount;
        }
        if(sum!=totalMinor) throw ArgumentError('إجمالي الأصناف غير متطابق');
      }
      final created=await createInvoice(customerId:customerId,totalMinor:totalMinor,isManualAmount:isManualAmount,items:items,
        discountMinor:discountMinor,notes:notes,invoiceDate:invoiceDate,dueDate:dueDate);
      await _db.customStatement('UPDATE invoices SET invoice_number=? WHERE id=? AND workspace_id=?',
        ['INV-${created.substring(0,8).toUpperCase()}',created,_wsId]);
      await postInvoice(created);
      return created;
    });
    refresh();
    return id;
  }

  Future<void> _requireCustomer(String id) async {
    final rows=await _db.customSelect('SELECT id FROM customers WHERE id=? AND workspace_id=? AND deleted_at IS NULL',
      variables:[Variable.withString(id),Variable.withString(_wsId)]).get();
    if(rows.isEmpty) throw StateError('العميل غير موجود');
  }

  String _encodePayload(Map<String, dynamic> m) => jsonEncode(m);
}

// ─── DatabaseService ─────────────────────────────────────────────────────────

