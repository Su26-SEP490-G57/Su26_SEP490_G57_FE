import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_routes.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Score thresholds
// Tổng điểm max = 11 (5 câu: 2+3+2+2+2)
// GREEN  : 0–2  — dung nạp tốt
// YELLOW : 3–5  — cần theo dõi thêm
// RED    : 6+   — cần can thiệp sớm
// ─────────────────────────────────────────────────────────────────────────────

enum _ResultLevel { green, yellow, red }

_ResultLevel _levelFromScore(int score) {
  if (score <= 2) return _ResultLevel.green;
  if (score <= 5) return _ResultLevel.yellow;
  return _ResultLevel.red;
}

class _LevelConfig {
  const _LevelConfig({
    required this.label,
    required this.scoreRange,
    required this.primaryColor,
    required this.bgColor,
    required this.cardBgColor,
    required this.cardBorderColor,
    required this.textColor,
    required this.headline,
    required this.subtext,
    required this.tip,
  });

  final String label;
  final String scoreRange;
  final Color primaryColor;
  final Color bgColor;
  final Color cardBgColor;
  final Color cardBorderColor;
  final Color textColor;
  final String headline;
  final String subtext;
  final String tip;

  static _LevelConfig from(_ResultLevel level) {
    return switch (level) {
      _ResultLevel.green => const _LevelConfig(
        label: 'GREEN',
        scoreRange: '(0–2 điểm)',
        primaryColor: Color(0xFF006E2F),
        bgColor: Color(0xFFF0FFF4),
        cardBgColor: Color(0xFFD1FAE5),
        cardBorderColor: Color(0xFFBBF7D0),
        textColor: Color(0xFF005321),
        headline: 'Bạn đang hồi phục tốt!',
        subtext: 'Hãy tiếp tục chế độ ăn hiện tại nhé!',
        tip:
            'Mẹo nhỏ: Hãy nhai thật kỹ và ăn từng miếng nhỏ để hỗ trợ hệ tiêu hóa của bạn tốt nhất nhé.',
      ),
      _ResultLevel.yellow => const _LevelConfig(
        label: 'YELLOW',
        scoreRange: '(3–5 điểm)',
        primaryColor: Color(0xFF735C00),
        bgColor: Color(0xFFFFFBEB),
        cardBgColor: Color(0xFFFEF9C3),
        cardBorderColor: Color(0xFFFDE68A),
        textColor: Color(0xFF574500),
        headline: 'Cần theo dõi thêm.',
        subtext:
            'Triệu chứng ở mức trung bình, hãy báo điều dưỡng nếu có gì bất thường.',
        tip:
            'Lưu ý: Nếu triệu chứng không cải thiện sau vài giờ, hãy báo ngay cho điều dưỡng phụ trách.',
      ),
      _ResultLevel.red => const _LevelConfig(
        label: 'RED',
        scoreRange: '(6+ điểm)',
        primaryColor: Color(0xFFBA1A1A),
        bgColor: Color(0xFFFFF5F5),
        cardBgColor: Color(0xFFFFDAD6),
        cardBorderColor: Color(0xFFFCA5A5),
        textColor: Color(0xFF93000A),
        headline: 'Cần can thiệp sớm!',
        subtext:
            'Triệu chứng ở mức đáng lo ngại. Hãy báo điều dưỡng ngay lập tức.',
        tip:
            'Quan trọng: Đừng chờ đợi — bấm nút "Báo điều dưỡng" bên dưới để được hỗ trợ ngay.',
      ),
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────────────────────────────────────

class PatientAssessmentResultPage extends StatefulWidget {
  const PatientAssessmentResultPage({super.key, required this.totalScore});

  final int totalScore;

  @override
  State<PatientAssessmentResultPage> createState() =>
      _PatientAssessmentResultPageState();
}

class _PatientAssessmentResultPageState
    extends State<PatientAssessmentResultPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _confettiCtrl;
  late final _ResultLevel _level;
  late final _LevelConfig _config;

  @override
  void initState() {
    super.initState();
    _level = _levelFromScore(widget.totalScore);
    _config = _LevelConfig.from(_level);

    _confettiCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    // Chỉ chạy confetti cho GREEN
    if (_level == _ResultLevel.green) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _confettiCtrl.forward();
      });
    }
  }

  @override
  void dispose() {
    _confettiCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _config.bgColor,
      body: Stack(
        children: [
          // ── Confetti (GREEN only) ──────────────────────────────────
          if (_level == _ResultLevel.green)
            AnimatedBuilder(
              animation: _confettiCtrl,
              builder: (_, _) => CustomPaint(
                painter: _ConfettiPainter(_confettiCtrl.value),
                size: Size.infinite,
              ),
            ),

          // ── Main content ───────────────────────────────────────────
          Column(
            children: [
              _Header(onBack: () => context.pop()),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                  child: Column(
                    children: [
                      const SizedBox(height: 32),

                      // Hero
                      _HeroSection(level: _level, config: _config),
                      const SizedBox(height: 32),

                      // Assessment card
                      _AssessmentCard(
                        config: _config,
                        totalScore: widget.totalScore,
                      ),
                      const SizedBox(height: 32),

                      // Action buttons
                      _ActionButtons(level: _level),
                      const SizedBox(height: 24),

                      // Tip
                      _TipCard(config: _config),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ── Bottom fixed button ────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _BottomBar(level: _level),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      child: SizedBox(
        height: 56,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                color: AppColors.onSurface,
                onPressed: onBack,
              ),
              const Expanded(
                child: Text(
                  'Kết quả đánh giá',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 48), // balance back button
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero section
// ─────────────────────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  const _HeroSection({required this.level, required this.config});
  final _ResultLevel level;
  final _LevelConfig config;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Circle icon
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: config.primaryColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: config.primaryColor.withValues(alpha: 0.3),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            switch (level) {
              _ResultLevel.green => Icons.check_circle_rounded,
              _ResultLevel.yellow => Icons.warning_rounded,
              _ResultLevel.red => Icons.notifications_active_rounded,
            },
            color: Colors.white,
            size: 48,
          ),
        ),
        const SizedBox(height: 16),

        // Level label
        Text(
          config.label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: config.primaryColor,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          config.scoreRange,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Assessment card
// ─────────────────────────────────────────────────────────────────────────────

class _AssessmentCard extends StatelessWidget {
  const _AssessmentCard({required this.config, required this.totalScore});
  final _LevelConfig config;
  final int totalScore;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: config.cardBgColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: config.cardBorderColor),
      ),
      child: Column(
        children: [
          Text(
            config.headline,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: config.textColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            config.subtext,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              color: config.textColor.withValues(alpha: 0.8),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          // Score display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'Tổng điểm: $totalScore',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: config.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Action buttons
// ─────────────────────────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({required this.level});
  final _ResultLevel level;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Xem hướng dẫn ăn
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.restaurant_rounded),
            label: const Text('Xem hướng dẫn ăn'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Về trang chủ
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton.icon(
            onPressed: () => context.go(AppRoutes.patientDashboard),
            icon: const Icon(Icons.home_rounded),
            label: const Text('Về trang chủ'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.onSurface,
              side: const BorderSide(color: Color(0xFFC3C6D7), width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tip card
// ─────────────────────────────────────────────────────────────────────────────

class _TipCard extends StatelessWidget {
  const _TipCard({required this.config});
  final _LevelConfig config;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEDEDF9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_rounded, color: AppColors.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              config.tip,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom bar — "Báo điều dưỡng" fixed
// ─────────────────────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.level});
  final _ResultLevel level;

  @override
  Widget build(BuildContext context) {
    final isUrgent = level == _ResultLevel.red;

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.9),
        border: Border(
          top: BorderSide(color: AppColors.outline.withValues(alpha: 0.5)),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton.icon(
          onPressed: () {},
          icon: Icon(
            Icons.notifications_active_rounded,
            size: 22,
            color: Colors.white,
          ),
          label: const Text('Báo điều dưỡng'),
          style: ElevatedButton.styleFrom(
            backgroundColor: isUrgent
                ? AppColors.error
                : const Color(0xFFEF4444),
            foregroundColor: Colors.white,
            elevation: isUrgent ? 4 : 2,
            shape: const StadiumBorder(),
            textStyle: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Confetti painter (GREEN only)
// ─────────────────────────────────────────────────────────────────────────────

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.progress);

  final double progress;

  static final _rng = math.Random(42);
  static final _particles = List.generate(40, (i) {
    return _Particle(
      x: _rng.nextDouble(),
      delay: _rng.nextDouble() * 0.4,
      size: _rng.nextDouble() * 6 + 4,
      color: [
        const Color(0xFF4AE176),
        const Color(0xFF004AC6),
        const Color(0xFFFFE083),
        Colors.white,
      ][_rng.nextInt(4)],
      rotation: _rng.nextDouble() * math.pi * 2,
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _particles) {
      final t = ((progress - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
      if (t <= 0) continue;

      final x = p.x * size.width;
      final y = t * size.height * 1.2 - 10;
      final opacity = (1 - t * 0.8).clamp(0.0, 1.0);

      final paint = Paint()
        ..color = p.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.rotation + t * math.pi * 4);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: p.size,
          height: p.size * 0.6,
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}

class _Particle {
  const _Particle({
    required this.x,
    required this.delay,
    required this.size,
    required this.color,
    required this.rotation,
  });

  final double x;
  final double delay;
  final double size;
  final Color color;
  final double rotation;
}
