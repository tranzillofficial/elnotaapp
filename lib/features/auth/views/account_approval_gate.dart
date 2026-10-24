import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/account_access_service.dart';
import '../../../core/utils/app_runtime.dart';
import 'activation_view.dart';

class AccountApprovalGate extends StatelessWidget {
  const AccountApprovalGate({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    if (AppRuntime.demo) return child;
    final access = AccountAccessService.to;
    return Obx(() {
      if (!access.resolved.value) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      return access.access.value.active ? child : const ActivationView();
    });
  }
}
