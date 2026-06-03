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

class _LoginPageState extends ConsumerState<LoginPage>
    with SingleTickerProviderStateMixin {
  bool _showNurseLogin = false;
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _switchToNurse() {
    _animController.reverse().then((_) {
      setState(() => _showNurseLogin = true);
      _animController.forward();
    });
  }

  void _switchToPatient() {
    _animController.reverse().then((_) {
      setState(() => _showNurseLogin = false);
      _animController.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authNotifierProvider, (_, next) {
      if (next.status == AuthStatus.error && next.errorMessage != null) {
        context.showSnackBar(next.errorMessage!, isError: true);
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Atmospheric blobs ──────────────────────────────────────
          const _AtmosphericBackground(),

          // ── Main content ───────────────────────────────────────────
          SafeArea(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: Column(
                        children: [
                          const SizedBox(height: 8),

                          // ── Branding ─────────────────────────────
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: _showNurseLogin
                                ? const _NurseBranding(key: ValueKey('nurse'))
                                : const _PatientBranding(
                                    key: ValueKey('patient'),
                                  ),
                          ),

                          const SizedBox(height: 32),

                          // ── Login card ────────────────────────────
                          _LoginCard(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              transitionBuilder: (child, anim) =>
                                  FadeTransition(
                                    opacity: anim,
                                    child: SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(0, 0.05),
                                        end: Offset.zero,
                                      ).animate(anim),
                                      child: child,
                                    ),
                                  ),
                              child: _showNurseLogin
                                  ? NurseLoginForm(
                                      key: const ValueKey('nurse_form'),
                                      onSwitchToPatient: _switchToPatient,
                                    )
                                  : PatientLoginForm(
                                      key: const ValueKey('patient_form'),
                                      onSwitchToNurse: _switchToNurse,
                                    ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // ── Footer ────────────────────────────────
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: _showNurseLogin
                                ? const _NurseFooter(key: ValueKey('nf'))
                                : const _PatientFooter(key: ValueKey('pf')),
                          ),

                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
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
// Atmospheric background blobs
// ─────────────────────────────────────────────────────────────────────────────

class _AtmosphericBackground extends StatefulWidget {
  const _AtmosphericBackground();

  @override
  State<_AtmosphericBackground> createState() => _AtmosphericBackgroundState();
}

class _AtmosphericBackgroundState extends State<_AtmosphericBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, _) {
        final t = _pulse.value;
        return Stack(
          fit: StackFit.expand,
          children: [
            // Top-right teal blob
            Positioned(
              top: -80 + (t * 12),
              right: -80 + (t * 8),
              child: _Blob(
                width: 320,
                height: 320,
                color: const Color(0xFF86F2E4).withValues(alpha: 0.18),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(999),
                  topRight: Radius.circular(160),
                  bottomLeft: Radius.circular(200),
                  bottomRight: Radius.circular(120),
                ),
              ),
            ),
            // Bottom-left blue blob
            Positioned(
              bottom: -60 + (t * 10),
              left: -80 + (t * 6),
              child: _Blob(
                width: 280,
                height: 280,
                color: const Color(0xFFDAE1FF).withValues(alpha: 0.28),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(120),
                  topRight: Radius.circular(200),
                  bottomLeft: Radius.circular(160),
                  bottomRight: Radius.circular(999),
                ),
              ),
            ),
            // Subtle center glow
            Positioned(
              top: MediaQuery.sizeOf(context).height * 0.3,
              left: -120,
              child: _Blob(
                width: 260,
                height: 200,
                color: const Color(
                  0xFF0054D6,
                ).withValues(alpha: 0.04 + t * 0.02),
                borderRadius: const BorderRadius.all(Radius.circular(999)),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({
    required this.width,
    required this.height,
    required this.color,
    required this.borderRadius,
  });

  final double width;
  final double height;
  final Color color;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(color: color, borderRadius: borderRadius),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Branding sections
// ─────────────────────────────────────────────────────────────────────────────

class _PatientBranding extends StatelessWidget {
  const _PatientBranding({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Logo container
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 6),
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
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        const Text(
          'Theo dõi hồi phục hậu phẫu an toàn và hiệu quả',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Color(0xFF424656),
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _NurseBranding extends StatelessWidget {
  const _NurseBranding({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.medical_services_rounded,
            size: 42,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Đăng nhập điều dưỡng',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF191B24),
            letterSpacing: -0.3,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        const Text(
          'Hệ thống hỗ trợ theo dõi hậu phẫu',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Color(0xFF424656),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Login card — glass effect
// ─────────────────────────────────────────────────────────────────────────────

class _LoginCard extends StatelessWidget {
  const _LoginCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.80),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFC2C6D8).withValues(alpha: 0.6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 32,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.6),
            blurRadius: 0,
            spreadRadius: 1,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Footer sections
// ─────────────────────────────────────────────────────────────────────────────

class _PatientFooter extends StatelessWidget {
  const _PatientFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Security badge
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
              Icon(
                Icons.verified_user_rounded,
                size: 16,
                color: Color(0xFF006A61),
              ),
              SizedBox(width: 6),
              Text(
                'Hệ thống bảo mật chuẩn HIPAA',
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
        const SizedBox(height: 12),
        Opacity(
          opacity: 0.55,
          child: Column(
            children: [
              const Text(
                'HOSPITAL ID: POMS-VN-001',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: Color(0xFF191B24),
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'App Version 2.4.0 (Stable)',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
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
  const _NurseFooter({super.key});

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
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.verified_user_rounded,
                size: 16,
                color: Color(0xFF006A61),
              ),
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
        Opacity(
          opacity: 0.55,
          child: Column(
            children: [
              const Text(
                'HỆ THỐNG POMS © 2024. ĐÃ ĐƯỢC MÃ HÓA ĐẦU CUỐI.',
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
              const Text(
                'CHỈ DÀNH CHO NHÂN VIÊN Y TẾ ĐƯỢC ỦY QUYỀN.',
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
            ],
          ),
        ),
      ],
    );
  }
}
