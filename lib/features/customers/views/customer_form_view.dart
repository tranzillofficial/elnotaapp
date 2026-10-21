import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/widgets/app_widgets.dart';
import '../repositories/customer_repository.dart';

/// Create or edit a customer.
class CustomerFormView extends StatefulWidget {
  const CustomerFormView({super.key});

  @override
  State<CustomerFormView> createState() => _CustomerFormViewState();
}

class _CustomerFormViewState extends State<CustomerFormView> {
  late final CustomerRepository _repo;
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _saving = false;
  String? _editId;
  bool get _isEdit => _editId != null;

  @override
  void initState() {
    super.initState();
    _repo = CustomerRepository();
    final args = Get.arguments as Map<String, dynamic>?;
    _editId = args?['id'] as String?;
    if (_isEdit) {
      // Pre-fill from passed args or stream (simplest: re-read from repo).
      _loadForEdit();
    }
  }

  Future<void> _loadForEdit() async {
    _repo.watchOne(_editId!).first.then((c) {
      if (c != null && mounted) {
        _nameCtrl.text = c.name;
        _phoneCtrl.text = c.phone ?? '';
        _notesCtrl.text = c.notes ?? '';
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      if (_isEdit) {
        await _repo.update(
          id: _editId!,
          name: _nameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        );
        showSuccessSnack('customer_updated'.tr);
      } else {
        await _repo.create(
          name: _nameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        );
        showSuccessSnack('customer_created'.tr);
      }
      Get.back();
    } catch (e) {
      showErrorSnack('${'error_generic'.tr}: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'customer_edit'.tr : 'customer_create'.tr),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: 'customer_name'.tr,
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                ),
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'validation_required'.tr : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneCtrl,
                decoration: InputDecoration(
                  labelText: 'customer_phone'.tr,
                  prefixIcon: const Icon(Icons.phone_outlined),
                ),
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesCtrl,
                decoration: InputDecoration(
                  labelText: 'customer_notes'.tr,
                  prefixIcon: const Icon(Icons.notes_rounded),
                ),
                maxLines: 3,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_rounded),
                label: Text('action_save'.tr),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
