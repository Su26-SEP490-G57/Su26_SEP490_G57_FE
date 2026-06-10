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
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    context.hideKeyboard();
    if (!_formKey.currentState!.validate()) return;

    await ref
        .read(authNotifierProvider.notifier)
        .signIn(
          username: _idController.text.trim(),
          password: _passwordController.text,
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
          const _FieldLabel(label: 'MÃ BỆNH NHÂN'),
          const SizedBox(height: 6),
          _GlassInputField(
            controller: _idController,
            hint: 'VD: POMS123456',
            prefixIcon: Icons.badge_outlined,
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Vui lòng nhập mã bệnh nhân';
              }
              final trimmed = value.trim();
              // Mã bệnh nhân: chữ + số, tối thiểu 4 ký tự
              if (!RegExp(r'^[A-Za-z0-9]{4,}$').hasMatch(trimmed)) {
                return 'Mã bệnh nhân không hợp lệ. VD: POMS123456';
              }
              return null;
            },
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                // TODO: forgot patient ID flow
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
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
          ),

          const SizedBox(height: 12),

          // ── Password field ──────────────────────────────────────────
          const _FieldLabel(label: 'MẬT KHẨU'),
          const SizedBox(height: 6),
          _GlassInputField(
            controller: _passwordController,
            hint: 'Mật khẩu',
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
            suffixIcon: GestureDetector(
              onTap: () => setState(() => _obscurePassword = !_obscurePassword),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: const Color(0xFF727687),
                  size: 20,
                ),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Vui lòng nhập mật khẩu';
              }
              if (value.length < 6) {
                return 'Mật khẩu phải có ít nhất 6 ký tự';
              }
              return null;
            },
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                // TODO: forgot password flow
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'QUÊN MẬT KHẨU?',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: Color(0xFF0050CB),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // ── Remember me ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: CustomCheckbox(
              value: _rememberMe,
              onChanged: (v) => setState(() => _rememberMe = v),
              label: 'Ghi nhớ đăng nhập',
            ),
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
                fontSize: 16,
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

// ─────────────────────────────────────────────────────────────────────────────
// Field label
// ─────────────────────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: Color(0xFF424656),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Glass input field
// ─────────────────────────────────────────────────────────────────────────────

class _GlassInputField extends StatefulWidget {
  const _GlassInputField({
    required this.controller,
    required this.hint,
    required this.prefixIcon,
    this.obscureText = false,
    this.textInputAction,
    this.suffixIcon,
    this.validator,
    this.onFieldSubmitted,
  });

  final TextEditingController controller;
  final String hint;
  final IconData prefixIcon;
  final bool obscureText;
  final TextInputAction? textInputAction;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  State<_GlassInputField> createState() => _GlassInputFieldState();
}

class _GlassInputFieldState extends State<_GlassInputField> {
  final _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(
      () => setState(() => _isFocused = _focusNode.hasFocus),
    );
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: _isFocused ? Colors.white : const Color(0xFFF2F3FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isFocused ? const Color(0xFF0050CB) : const Color(0xFFC2C6D8),
          width: _isFocused ? 2 : 1,
        ),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: const Color(0xFF0050CB).withValues(alpha: 0.08),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : [],
      ),
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focusNode,
        obscureText: widget.obscureText,
        textInputAction: widget.textInputAction,
        onFieldSubmitted: widget.onFieldSubmitted,
        validator: widget.validator,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          color: Color(0xFF191B24),
        ),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            color: Color(0xFF727687),
          ),
          prefixIcon: Icon(
            widget.prefixIcon,
            color: const Color(0xFF727687),
            size: 22,
          ),
          suffixIcon: widget.suffixIcon,
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          errorStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            color: Color(0xFFBA1A1A),
          ),
        ),
      ),
    );
  }
}
