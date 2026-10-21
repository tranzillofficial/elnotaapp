import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/utils/money_utils.dart';
import '../../../core/widgets/app_widgets.dart';
import '../repositories/invoice_repository.dart';

/// Drives the create-invoice form.
/// Supports manual-amount mode or line-item mode.
class InvoiceFormController extends GetxController {
  InvoiceFormController(this._repo);
  final InvoiceRepository _repo;

  final RxBool isManualAmount = true.obs;
  final RxBool isSaving = false.obs;

  // Manual amount fields
  final amountCtrl = TextEditingController();
  final discountCtrl = TextEditingController();
  final notesCtrl = TextEditingController();

  // Line items
  final RxList<LineItemDraft> items = <LineItemDraft>[].obs;

  int get totalMinor {
    if (isManualAmount.value) {
      return MoneyUtils.parseToMinor(amountCtrl.text) ?? 0;
    }
    return items.fold(0, (sum, i) => sum + i.lineTotal);
  }

  int get discountMinor => MoneyUtils.parseToMinor(discountCtrl.text) ?? 0;
  int get netMinor => totalMinor - discountMinor;

  void addItem(LineItemDraft item) => items.add(item);
  void removeItem(int index) => items.removeAt(index);

  Future<bool> save(String customerId) async {
    if (isManualAmount.value &&
        (MoneyUtils.parseToMinor(amountCtrl.text) ?? 0) <= 0) {
      showErrorSnack('validation_amount_required'.tr);
      return false;
    }
    if (!isManualAmount.value && items.isEmpty) {
      showErrorSnack('validation_items_required'.tr);
      return false;
    }
    isSaving.value = true;
    try {
      await _repo.createAndPost(
        customerId: customerId,
        totalMinor: totalMinor,
        isManualAmount: isManualAmount.value,
        items: isManualAmount.value
            ? []
            : items
                .map((i) => {
                      'description': i.description,
                      'quantity': i.quantity,
                      'unit_price_minor': i.unitPriceMinor,
                      'discount_minor': i.discountMinor,
                    })
                .toList(),
        discountMinor: discountMinor,
        notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
      );
      showSuccessSnack('invoice_created'.tr);
      return true;
    } catch (e) {
      showErrorSnack('${'error_generic'.tr}: $e');
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  @override
  void onClose() {
    amountCtrl.dispose();
    discountCtrl.dispose();
    notesCtrl.dispose();
    super.onClose();
  }
}

class LineItemDraft {
  LineItemDraft({
    required this.description,
    required this.quantity,
    required this.unitPriceMinor,
    this.discountMinor = 0,
  });

  final String description;
  final int quantity;
  final int unitPriceMinor;
  final int discountMinor;

  int get lineTotal => quantity * unitPriceMinor - discountMinor;
}
