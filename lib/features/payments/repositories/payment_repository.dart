import '../../../core/database/app_database.dart';
import '../../../core/database/database_impl.dart';
import '../models/payment_model.dart';

class PaymentRepository {
  PaymentRepository() : _dao = DatabaseService.to.dao;
  final AppDao _dao;

  Stream<List<PaymentModel>> watchByCustomer(String customerId) =>
      _dao.watchPayments(customerId).map(
            (rows) => rows.map(PaymentModel.fromRow).toList(),
          );

  Future<void> addPayment({
    required String customerId,
    required int amountMinor,
    required String idempotencyKey,
    String? notes,
    DateTime? paymentDate,
  }) =>
      _dao.addPayment(
        customerId: customerId,
        amountMinor: amountMinor,
        idempotencyKey: idempotencyKey,
        notes: notes,
        paymentDate: paymentDate,
      );
}
