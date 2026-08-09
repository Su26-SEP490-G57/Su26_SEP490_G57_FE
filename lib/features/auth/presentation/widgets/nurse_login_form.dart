import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:poms/core/utils/extensions.dart';
import 'package:poms/shared/widgets/custom_checkbox.dart';
import 'package:poms/features/auth/presentation/providers/auth_provider.dart';
import 'package:poms/features/auth/presentation/widgets/login_shared_widgets.dart';

class NurseLoginForm extends ConsumerStatefulWidget {
  const NurseLoginForm({required this.onSwitchToPatient, super.key});

  final VoidCallback onSwitchToPatient;

  @override
  ConsumerState<NurseLoginForm> createState() => _NurseLoginFormState();
}

class _NurseLoginFormState extends ConsumerState<NurseLoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    context.hideKeyboard();
    if (!_formKey.currentState!.validate()) return;

    String? fcmToken;
    if (!kIsWeb) {
      try {
        fcmToken = await FirebaseMessaging.instance.getToken();
      } catch (e) {
        debugPrint('Failed to get FCM token: $e');
      }
    }

    await ref
        .read(authNotifierProvider.notifier)
        .signIn(
          username: _usernameController.text.trim(),
          password: _passwordController.text,
          rememberMe: _rememberMe,
          deviceFcmToken: fcmToken,
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
          // ── Username ────────────────────────────────────────────────
          const _FieldLabel(label: 'TÊN ĐĂNG NHẬP'),
          const SizedBox(height: 6),
          _GlassInputField(
            controller: _usernameController,
            hint: 'Nhập tên đăng nhập',
            prefixIcon: Icons.badge_outlined,
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Vui lòng nhập tên đăng nhập';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // ── Password ────────────────────────────────────────────────
          const _FieldLabel(label: 'MẬT KHẨU'),
          const SizedBox(height: 6),
          _GlassInputField(
            controller: _passwordController,
            hint: 'Nhập mật khẩu',
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

          // ── Remember me + Forgot ────────────────────────────────────
          Row(
            children: [
              CustomCheckbox(
                value: _rememberMe,
                onChanged: (v) => setState(() => _rememberMe = v),
                label: 'Ghi nhớ đăng nhập',
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  // todo: forgot password flow
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
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
            ],
          ),

          const SizedBox(height: 24),

          // ── Login button ────────────────────────────────────────────
          LoginPrimaryButton(
            label: 'Đăng nhập',
            isLoading: isLoading,
            onPressed: isLoading ? null : _submit,
          ),

          const SizedBox(height: 24),

          // ── Switch to patient ───────────────────────────────────────
          Center(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: Color(0xFF424656),
                ),
                children: [
                  const TextSpan(text: 'Bạn là bệnh nhân? '),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.baseline,
                    baseline: TextBaseline.alphabetic,
                    child: GestureDetector(
                      onTap: widget.onSwitchToPatient,
                      child: const Text(
                        'Đăng nhập tại đây',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF0050CB),
                          decoration: TextDecoration.underline,
                          decorationColor: Color(0xFF0050CB),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
// Glass input field — no IconButton (avoids MouseRegion desktop bug)
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
