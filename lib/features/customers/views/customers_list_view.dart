import 'package:flutter/material.dart';
import '../../accounting/views/accounting_pages.dart';
class CustomersListView extends StatelessWidget {
  const CustomersListView({super.key});
  @override
  Widget build(BuildContext context)=>const AccountingPage(section:AccountingSection.customers);
}
