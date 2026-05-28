import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../providers/auth_provider.dart';
import '../widgets/nurse_login_form.dart';
import '../widgets/patient_login_form.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  bool _showNurseLogin = false;

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authNotifierProvider, (_, next) {
      if (next.status == AuthStatus.error && next.errorMessage != null) {
        context.showSnackBar(next.errorMessage!, isError: true);
      }
    });

    if (_showNurseLogin) {
      return _NurseLoginScaffold(
        onSwitchToPatient: () => setState(() => _showNurseLogin = false),
      );
    }

    return _PatientLoginScaffold(
      onSwitchToNurse: () => setState(() => _showNurseLogin = true),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Patient scaffold
// ─────────────────────────────────────────────────────────────────────────────

class _PatientLoginScaffold extends StatelessWidget {
  const _PatientLoginScaffold({required this.onSwitchToNurse});

  final VoidCallback onSwitchToNurse;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Blobs
          Positioned(
            top: -80,
            right: -80,
            child: _blob(
              320,
              320,
              const Color(0xFF86F2E4).withValues(alpha: 0.2),
              const BorderRadius.only(
                topLeft: Radius.circular(999),
                topRight: Radius.circular(160),
                bottomLeft: Radius.circular(200),
                bottomRight: Radius.circular(120),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -80,
            child: _blob(
              280,
              280,
              const Color(0xFFDAE1FF).withValues(alpha: 0.3),
              const BorderRadius.only(
                topLeft: Radius.circular(120),
                topRight: Radius.circular(200),
                bottomLeft: Radius.circular(160),
                bottomRight: Radius.circular(999),
              ),
            ),
          ),
          // Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      const _PatientBranding(),
                      const SizedBox(height: 32),
                      _LoginCard(
                        child: PatientLoginForm(
                          onSwitchToNurse: onSwitchToNurse,
                        ),
                      ),
                      const SizedBox(height: 32),
                      const _LoginFooter(
                        badgeText: 'Hệ thống bảo mật chuẩn HIPAA',
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Nurse scaffold
// ─────────────────────────────────────────────────────────────────────────────

class _NurseLoginScaffold extends StatelessWidget {
  const _NurseLoginScaffold({required this.onSwitchToPatient});

  final VoidCallback onSwitchToPatient;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Blobs
          Positioned(
            top: -80,
            left: -80,
            child: _blob(
              340,
              280,
              const Color(0xFF0054D6).withValues(alpha: 0.05),
              const BorderRadius.only(
                topLeft: Radius.circular(160),
                topRight: Radius.circular(999),
                bottomLeft: Radius.circular(120),
                bottomRight: Radius.circular(200),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            right: -80,
            child: _blob(
              300,
              240,
              const Color(0xFF86F2E4).withValues(alpha: 0.08),
              const BorderRadius.only(
                topLeft: Radius.circular(999),
                topRight: Radius.circular(120),
                bottomLeft: Radius.circular(200),
                bottomRight: Radius.circular(160),
              ),
            ),
          ),
          // Content
          SafeArea(
            child: Column(
              children: [
                // Header
                SizedBox(
                  height: 80,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: onSwitchToPatient,
                          child: const Icon(
                            Icons.arrow_back,
                            color: Color(0xFF424656),
                            size: 24,
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: AppColors.primaryContainer,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.local_hospital_rounded,
                                size: 32,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 40),
                      ],
                    ),
                  ),
                ),
                // Scrollable form
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: Column(
                          children: [
                            const SizedBox(height: 8),
                            _LoginCard(
                              child: NurseLoginForm(
                                onSwitchToPatient: onSwitchToPatient,
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // Footer
                const _NurseFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────────

Widget _blob(double w, double h, Color color, BorderRadius radius) {
  return Container(
    width: w,
    height: h,
    decoration: BoxDecoration(color: color, borderRadius: radius),
  );
}

class _LoginCard extends StatelessWidget {
  const _LoginCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 30,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: child,
    );
  }
}

class _PatientBranding extends StatelessWidget {
  const _PatientBranding();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.15),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.local_hospital_rounded,
            size: 52,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Chào mừng trở lại',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF191B24),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Theo dõi hồi phục hậu phẫu an toàn và hiệu quả',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            color: Color(0xFF424656),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _LoginFooter extends StatelessWidget {
  const _LoginFooter({required this.badgeText});
  final String badgeText;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFE6E7F4).withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFFC2C6D8)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.verified_user,
                size: 18,
                color: Color(0xFF006A61),
              ),
              const SizedBox(width: 6),
              Text(
                badgeText,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: Color(0xFF424656),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Opacity(
          opacity: 0.6,
          child: Column(
            children: [
              Text(
                'HOSPITAL ID: POMS-VN-001',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: Color(0xFF191B24),
                ),
              ),
              SizedBox(height: 2),
              Text(
                'App Version 2.4.0 (Stable)',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: Color(0xFF191B24),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NurseFooter extends StatelessWidget {
  const _NurseFooter();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFE6E7F4).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFFC2C6D8)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_user, size: 18, color: Color(0xFF006A61)),
                SizedBox(width: 6),
                Text(
                  'TRUY CẬP NỘI BỘ BẢO MẬT',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: Color(0xFF424656),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Opacity(
            opacity: 0.6,
            child: Text(
              'HỆ THỐNG POMS © 2024. ĐÃ ĐƯỢC MÃ HÓA ĐẦU CUỐI.\nCHỈ DÀNH CHO NHÂN VIÊN Y TẾ ĐƯỢC ỦY QUYỀN.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: Color(0xFF727687),
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
