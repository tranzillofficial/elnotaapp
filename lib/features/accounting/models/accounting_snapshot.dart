import '../../../core/database/database_impl.dart';

class CustomerAccount {
  const CustomerAccount(this.customer,this.balance);
  final CustomerRow customer;
  final CustomerBalance balance;
}
class BusinessInfo {
  const BusinessInfo({this.name='',this.phone='',this.address='',this.currency='ج.م'});
  final String name,phone,address,currency;
}
class AccountingSnapshot {
  const AccountingSnapshot({required this.customers,required this.invoices,required this.payments,
    required this.items,required this.business});
  final List<CustomerAccount> customers;
  final List<InvoiceRow> invoices;
  final List<PaymentRow> payments;
  final Map<String,List<InvoiceItemRow>> items;
  final BusinessInfo business;
  String customerName(String id) => customer(id)?.customer.name ?? 'عميل غير متاح';
  CustomerAccount? customer(String id) {
    for(final c in customers) { if(c.customer.id==id) return c; }
    return null;
  }
  int get outstandingMinor => customers.fold(0,(s,c)=>s+(c.balance.outstandingMinor>0?c.balance.outstandingMinor:0));
  int get creditMinor => customers.fold(0,(s,c)=>s+(c.balance.outstandingMinor<0?-c.balance.outstandingMinor:0));
  int get receivedMinor => customers.fold(0,(s,c)=>s+c.balance.totalPaymentsMinor);
  int get invoicedMinor => customers.fold(0,(s,c)=>s+c.balance.totalInvoicedMinor-c.balance.totalDiscountsMinor);

  factory AccountingSnapshot.fromTables(Map<String,List<Map<String,dynamic>>> data) {
    DateTime time(dynamic v)=>DateTime.fromMillisecondsSinceEpoch(v as int);
    final ledger=data['ledger_entries']??[];
    final customers=(data['customers']??[]).where((r)=>r['deleted_at']==null).map((r) {
      final id=r['id'] as String;
      var invoiced=0,discounts=0,received=0,adjustments=0;
      for(final e in ledger.where((e)=>e['customer_id']==id)) {
        final amount=e['amount_minor'] as int;
        switch(e['event_type']) {
          case 'invoice_charge': invoiced+=amount; break;
          case 'discount': discounts-=amount; break;
          case 'payment_receipt': received-=amount; break;
          case 'refund': case 'adjustment': case 'reversal': adjustments+=amount; break;
        }
      }
      return CustomerAccount(CustomerRow(id:id,workspaceId:r['workspace_id'] as String,name:r['name'] as String,
        phone:r['phone'] as String?,address:r['address'] as String? ?? '',notes:r['notes'] as String?,version:r['version'] as int,
        createdAt:time(r['created_at']),updatedAt:time(r['updated_at'])),
        CustomerBalance(customerId:id,totalInvoicedMinor:invoiced,totalDiscountsMinor:discounts,
          totalPaymentsMinor:received,totalAdjustmentsMinor:adjustments));
    }).toList()..sort((a,b)=>a.customer.name.compareTo(b.customer.name));
    final invoices=(data['invoices']??[]).where((r)=>r['deleted_at']==null).map((r)=>InvoiceRow(
      id:r['id'] as String,workspaceId:r['workspace_id'] as String,customerId:r['customer_id'] as String,
      invoiceNumber:r['invoice_number'] as String?,method:r['method'] as String? ?? 'credit',entryMode:r['entry_mode'] as String?,
      status:r['status'] as String,totalMinor:r['total_minor'] as int,discountMinor:r['discount_minor'] as int,
      notes:r['notes'] as String?,isManualAmount:r['is_manual_amount']==1 || r['is_manual_amount']==true,
      invoiceDate:time(r['invoice_date']),dueDate:r['due_date']==null?null:time(r['due_date']),version:r['version'] as int,
      createdAt:time(r['created_at']),updatedAt:time(r['updated_at']))).toList()
      ..sort((a,b)=>b.invoiceDate.compareTo(a.invoiceDate));
    final payments=(data['payments']??[]).where((r)=>r['deleted_at']==null).map((r)=>PaymentRow(
      id:r['id'] as String,workspaceId:r['workspace_id'] as String,customerId:r['customer_id'] as String,
      amountMinor:r['amount_minor'] as int,notes:r['notes'] as String?,legacyInvoiceId:r['legacy_invoice_id'] as String?,
      paymentDate:time(r['payment_date']),idempotencyKey:r['idempotency_key'] as String,version:r['version'] as int,
      createdAt:time(r['created_at']),updatedAt:time(r['updated_at']))).toList()
      ..sort((a,b)=>b.paymentDate.compareTo(a.paymentDate));
    final items=<String,List<InvoiceItemRow>>{};
    for(final r in data['invoice_items']??<Map<String,dynamic>>[]) {
      final invoice=r['invoice_id'] as String;
      items.putIfAbsent(invoice,()=>[]).add(InvoiceItemRow(id:r['id'] as String,invoiceId:invoice,
        description:r['description'] as String,productId:r['product_id'] as String?,quantity:r['quantity'] as int,
        unitPriceMinor:r['unit_price_minor'] as int,discountMinor:r['discount_minor'] as int,createdAt:time(r['created_at'])));
    }
    final settings=data['business_settings']??[];
    final business=settings.isEmpty?const BusinessInfo():BusinessInfo(name:settings.first['business_name'] as String,
      phone:settings.first['phone'] as String,address:settings.first['address'] as String);
    return AccountingSnapshot(customers:customers,invoices:invoices,payments:payments,items:items,business:business);
  }
}
