import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/custom_checkbox.dart';
import '../providers/auth_provider.dart';
import 'login_shared_widgets.dart';

class PatientLoginForm extends ConsumerStatefulWidget {
  const PatientLoginForm({super.key, required this.onSwitchToNurse});

  final VoidCallback onSwitchToNurse;

  @override
  ConsumerState<PatientLoginForm> createState() => _PatientLoginFormState();
}

class _PatientLoginFormState extends ConsumerState<PatientLoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  bool _rememberMe = false;

  @override
  void dispose() {
    _idController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    context.hideKeyboard();
    if (!_formKey.currentState!.validate()) return;

    // TODO: patient login dùng Custom Token từ BE (patientId → BE → Firebase token)
    // Tạm thời bỏ qua, chưa implement
    await ref
        .read(authNotifierProvider.notifier)
        .signIn(
          email: _idController.text.trim(),
          password: '',
          rememberMe: _rememberMe,
        );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(
      authNotifierProvider.select((s) => s.isLoading),
    );

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Patient ID field ────────────────────────────────────────
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 8, bottom: 6),
                child: Text(
                  'MÃ BỆNH NHÂN HOẶC SỐ ĐIỆN THOẠI',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: Color(0xFF424656),
                  ),
                ),
              ),
              TextFormField(
                controller: _idController,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  color: Color(0xFF191B24),
                ),
                decoration: InputDecoration(
                  hintText: 'VD: POMS123456',
                  hintStyle: const TextStyle(
                    color: Color(0xFF727687),
                    fontSize: 16,
                  ),
                  prefixIcon: const Icon(
                    Icons.person_outline,
                    color: Color(0xFF727687),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF2F3FF),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFC2C6D8)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFC2C6D8)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF0050CB),
                      width: 2,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFBA1A1A)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập mã bệnh nhân hoặc số điện thoại';
                  }
                  return null;
                },
              ),
            ],
          ),

          const SizedBox(height: 4),

          // ── Remember me + Forgot ────────────────────────────────────
          Row(
            children: [
              CustomCheckbox(
                value: _rememberMe,
                onChanged: (v) => setState(() => _rememberMe = v),
                label: 'Ghi nhớ đăng nhập',
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  // TODO: forgot patient ID flow
                },
                child: const Text(
                  'QUÊN MÃ SỐ?',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: Color(0xFF0050CB),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Primary login button ────────────────────────────────────
          LoginPrimaryButton(
            label: 'Đăng nhập',
            isLoading: isLoading,
            onPressed: isLoading ? null : _submit,
          ),

          const SizedBox(height: 16),

          // ── Divider ─────────────────────────────────────────────────
          const LoginOrDivider(),

          const SizedBox(height: 16),

          // ── Switch to nurse ─────────────────────────────────────────
          OutlinedButton(
            onPressed: widget.onSwitchToNurse,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF0050CB),
              side: const BorderSide(color: Color(0xFF0050CB)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: const Text('Đăng nhập dành cho điều dưỡng'),
          ),
        ],
      ),
    );
  }
}
