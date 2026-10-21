import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/utils/app_routes.dart';
import '../../../core/widgets/app_widgets.dart';
import '../services/auth_service.dart';

class AuthController extends GetxController {
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final storeNameCtrl = TextEditingController();

  final RxBool isSignUp = false.obs;
  final RxBool isObscured = true.obs;

  AuthService get auth => AuthService.to;

  Future<void> submit() async {
    final email = emailCtrl.text.trim();
    final password = passwordCtrl.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      showErrorSnack('يرجى إدخال بريد إلكتروني صالح');
      return;
    }
    if (password.length < 6) {
      showErrorSnack('كلمة المرور يجب أن لا تقل عن 6 أحرف');
      return;
    }

    bool success;
    if (isSignUp.value) {
      final storeName = storeNameCtrl.text.trim().isEmpty ? 'متجري' : storeNameCtrl.text.trim();
      success = await auth.signUp(email: email, password: password, storeName: storeName);
    } else {
      success = await auth.signIn(email: email, password: password);
    }

    if (success) {
      Get.offAllNamed(AppRoutes.home);
    } else {
      showErrorSnack('status_error'.tr);
    }
  }

  void continueOffline() {
    Get.offAllNamed(AppRoutes.home);
  }

  @override
  void onClose() {
    emailCtrl.dispose();
    passwordCtrl.dispose();
    storeNameCtrl.dispose();
    super.onClose();
  }
}
