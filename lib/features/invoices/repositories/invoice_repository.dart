import '../../../core/database/app_database.dart';
import '../../../core/database/database_impl.dart';
import '../models/invoice_model.dart';

class InvoiceRepository {
  InvoiceRepository() : _dao = DatabaseService.to.dao;
  final AppDao _dao;

  Stream<List<InvoiceModel>> watchByCustomer(String customerId) =>
      _dao.watchInvoices(customerId).map(
            (rows) => rows.map(InvoiceModel.fromRow).toList(),
          );

  Stream<List<InvoiceModel>> watchAll({String? search, String? status}) =>
      _dao.watchAllInvoices(search: search, status: status).map(
            (rows) => rows.map(InvoiceModel.fromRow).toList(),
          );

  Stream<InvoiceModel?> watchOne(String id) =>
      _dao.watchInvoice(id).map((r) => r == null ? null : InvoiceModel.fromRow(r));

  Future<List<InvoiceItemModel>> getItems(String invoiceId) async {
    final rows = await _dao.getInvoiceItems(invoiceId);
    return rows.map(InvoiceItemModel.fromRow).toList();
  }

  /// Create a draft invoice then immediately post it.
  Future<String> createAndPost({
    required String customerId,
    required int totalMinor,
    required bool isManualAmount,
    List<Map<String, dynamic>> items = const [],
    int discountMinor = 0,
    String? notes,
    DateTime? invoiceDate,
    DateTime? dueDate,
  }) async {
    final id = await _dao.createInvoice(
      customerId: customerId,
      totalMinor: totalMinor,
      isManualAmount: isManualAmount,
      items: items,
      discountMinor: discountMinor,
      notes: notes,
      invoiceDate: invoiceDate,
      dueDate: dueDate,
    );
    await _dao.postInvoice(id);
    return id;
  }
}
