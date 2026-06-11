import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_routes.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data model
// ─────────────────────────────────────────────────────────────────────────────

class _AssessmentOption {
  const _AssessmentOption({
    required this.label,
    required this.score,
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
  });

  final String label;
  final int score;
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
}

class _AssessmentQuestion {
  const _AssessmentQuestion({
    required this.question,
    required this.subtitle,
    required this.options,
  });

  final String question;
  final String subtitle;
  final List<_AssessmentOption> options;
}

// ─────────────────────────────────────────────────────────────────────────────
// Mock data — thay bằng API call khi BE sẵn sàng
// ─────────────────────────────────────────────────────────────────────────────

const _kQuestions = [
  _AssessmentQuestion(
    question: 'Bạn có buồn nôn không?',
    subtitle: 'Hãy chọn mức độ cảm nhận của bạn hiện tại.',
    options: [
      _AssessmentOption(
        label: 'Không',
        score: 0,
        icon: Icons.sentiment_satisfied_rounded,
        iconBgColor: Color(0xFF6BFF8F),
        iconColor: Color(0xFF005321),
      ),
      _AssessmentOption(
        label: 'Nhẹ',
        score: 1,
        icon: Icons.sentiment_neutral_rounded,
        iconBgColor: Color(0xFFFFE083),
        iconColor: Color(0xFF574500),
      ),
      _AssessmentOption(
        label: 'Nhiều',
        score: 2,
        icon: Icons.sentiment_very_dissatisfied_rounded,
        iconBgColor: Color(0xFFFFDAD6),
        iconColor: AppColors.error,
      ),
    ],
  ),
  _AssessmentQuestion(
    question: 'Mức độ đau của bạn?',
    subtitle: 'Đánh giá cơn đau tại vết mổ hoặc vùng phẫu thuật.',
    options: [
      _AssessmentOption(
        label: 'Không đau',
        score: 0,
        icon: Icons.sentiment_very_satisfied_rounded,
        iconBgColor: Color(0xFF6BFF8F),
        iconColor: Color(0xFF005321),
      ),
      _AssessmentOption(
        label: 'Đau nhẹ',
        score: 1,
        icon: Icons.sentiment_neutral_rounded,
        iconBgColor: Color(0xFFFFE083),
        iconColor: Color(0xFF574500),
      ),
      _AssessmentOption(
        label: 'Đau vừa',
        score: 2,
        icon: Icons.sentiment_dissatisfied_rounded,
        iconBgColor: Color(0xFFFFE0B2),
        iconColor: Color(0xFFE65100),
      ),
      _AssessmentOption(
        label: 'Đau nhiều',
        score: 3,
        icon: Icons.sentiment_very_dissatisfied_rounded,
        iconBgColor: Color(0xFFFFDAD6),
        iconColor: AppColors.error,
      ),
    ],
  ),
  _AssessmentQuestion(
    question: 'Bạn có sốt không?',
    subtitle: 'Cảm giác ớn lạnh hoặc nhiệt độ cơ thể tăng cao.',
    options: [
      _AssessmentOption(
        label: 'Không',
        score: 0,
        icon: Icons.sentiment_satisfied_rounded,
        iconBgColor: Color(0xFF6BFF8F),
        iconColor: Color(0xFF005321),
      ),
      _AssessmentOption(
        label: 'Có (< 38.5°C)',
        score: 1,
        icon: Icons.thermostat_rounded,
        iconBgColor: Color(0xFFFFE083),
        iconColor: Color(0xFF574500),
      ),
      _AssessmentOption(
        label: 'Có (≥ 38.5°C)',
        score: 2,
        icon: Icons.thermostat_rounded,
        iconBgColor: Color(0xFFFFDAD6),
        iconColor: AppColors.error,
      ),
    ],
  ),
  _AssessmentQuestion(
    question: 'Bạn đã đi lại được chưa?',
    subtitle: 'Khả năng vận động sau phẫu thuật rất quan trọng.',
    options: [
      _AssessmentOption(
        label: 'Đi lại bình thường',
        score: 0,
        icon: Icons.directions_walk_rounded,
        iconBgColor: Color(0xFF6BFF8F),
        iconColor: Color(0xFF005321),
      ),
      _AssessmentOption(
        label: 'Đi được nhưng khó',
        score: 1,
        icon: Icons.accessibility_new_rounded,
        iconBgColor: Color(0xFFFFE083),
        iconColor: Color(0xFF574500),
      ),
      _AssessmentOption(
        label: 'Chưa đi được',
        score: 2,
        icon: Icons.airline_seat_flat_rounded,
        iconBgColor: Color(0xFFFFDAD6),
        iconColor: AppColors.error,
      ),
    ],
  ),
  _AssessmentQuestion(
    question: 'Bạn có ăn uống được không?',
    subtitle: 'Khả năng ăn uống giúp cơ thể phục hồi nhanh hơn.',
    options: [
      _AssessmentOption(
        label: 'Ăn uống bình thường',
        score: 0,
        icon: Icons.restaurant_rounded,
        iconBgColor: Color(0xFF6BFF8F),
        iconColor: Color(0xFF005321),
      ),
      _AssessmentOption(
        label: 'Ăn được ít',
        score: 1,
        icon: Icons.no_food_rounded,
        iconBgColor: Color(0xFFFFE083),
        iconColor: Color(0xFF574500),
      ),
      _AssessmentOption(
        label: 'Không ăn được',
        score: 2,
        icon: Icons.do_not_disturb_rounded,
        iconBgColor: Color(0xFFFFDAD6),
        iconColor: AppColors.error,
      ),
    ],
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────────────────────────────────────

class PatientAssessmentPage extends StatefulWidget {
  const PatientAssessmentPage({super.key});

  @override
  State<PatientAssessmentPage> createState() => _PatientAssessmentPageState();
}

class _PatientAssessmentPageState extends State<PatientAssessmentPage> {
  int _currentIndex = 0;
  // null = chưa chọn, int = index của option đã chọn
  final List<int?> _answers = List.filled(_kQuestions.length, null);

  bool get _isLastQuestion => _currentIndex == _kQuestions.length - 1;
  bool get _hasAnswer => _answers[_currentIndex] != null;
  _AssessmentQuestion get _current => _kQuestions[_currentIndex];

  void _selectOption(int optionIndex) {
    setState(() => _answers[_currentIndex] = optionIndex);
  }

  void _goNext() {
    if (!_hasAnswer) return;
    if (_isLastQuestion) {
      // Tính tổng điểm và navigate sang màn kết quả
      final totalScore = _answers.asMap().entries.fold<int>(0, (sum, e) {
        final qIdx = e.key;
        final aIdx = e.value;
        if (aIdx == null) return sum;
        return sum + _kQuestions[qIdx].options[aIdx].score;
      });
      context.push(AppRoutes.patientAssessmentResult, extra: totalScore);
    } else {
      setState(() => _currentIndex++);
    }
  }

  void _goBack() {
    if (_currentIndex == 0) {
      context.pop();
    } else {
      setState(() => _currentIndex--);
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_currentIndex + 1) / _kQuestions.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Header ────────────────────────────────────────────────
          _Header(onBack: _goBack),

          // ── Body ──────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Progress bar
                  _ProgressBar(
                    progress: progress,
                    current: _currentIndex + 1,
                    total: _kQuestions.length,
                  ),
                  const SizedBox(height: 32),

                  // Question
                  _QuestionHeader(question: _current),
                  const SizedBox(height: 32),

                  // Options
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.05, 0),
                          end: Offset.zero,
                        ).animate(anim),
                        child: child,
                      ),
                    ),
                    child: _OptionsList(
                      key: ValueKey(_currentIndex),
                      options: _current.options,
                      selectedIndex: _answers[_currentIndex],
                      onSelect: _selectOption,
                    ),
                  ),

                  const SizedBox(height: 32),
                  // Caption
                  Center(
                    child: Text(
                      'Chúng tôi luôn ở đây để giúp bạn phục hồi tốt nhất.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: AppColors.onSurfaceVariant.withValues(
                          alpha: 0.8,
                        ),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      // ── Bottom action bar ──────────────────────────────────────────
      bottomNavigationBar: _BottomActions(
        isLastQuestion: _isLastQuestion,
        hasAnswer: _hasAnswer,
        onBack: _goBack,
        onNext: _goNext,
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
      color: AppColors.background,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      child: SizedBox(
        height: 56,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.primary,
                ),
                onPressed: onBack,
              ),
              const Expanded(
                child: Text(
                  'Trả lời 5 câu hỏi',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const Icon(
                Icons.auto_awesome_rounded,
                color: Color(0xFFC3C6D7),
                size: 22,
              ),
              const SizedBox(width: 12),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Progress bar
// ─────────────────────────────────────────────────────────────────────────────

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({
    required this.progress,
    required this.current,
    required this.total,
  });

  final double progress;
  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 12,
              child: Stack(
                children: [
                  // Track
                  Container(color: const Color(0xFFE1E2ED)),
                  // Fill
                  AnimatedFractionallySizedBox(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutCubic,
                    widthFactor: progress,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF4AE176),
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: const [
                          BoxShadow(color: Color(0x804AE176), blurRadius: 10),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '$current/$total',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Question header
// ─────────────────────────────────────────────────────────────────────────────

class _QuestionHeader extends StatelessWidget {
  const _QuestionHeader({required this.question});

  final _AssessmentQuestion question;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question.question,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          question.subtitle,
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
// Options list
// ─────────────────────────────────────────────────────────────────────────────

class _OptionsList extends StatelessWidget {
  const _OptionsList({
    super.key,
    required this.options,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<_AssessmentOption> options;
  final int? selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: options.asMap().entries.map((e) {
        final i = e.key;
        final opt = e.value;
        final isSelected = selectedIndex == i;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _OptionCard(
            option: opt,
            isSelected: isSelected,
            onTap: () => onSelect(i),
          ),
        );
      }).toList(),
    );
  }
}

class _OptionCard extends StatefulWidget {
  const _OptionCard({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final _AssessmentOption option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_OptionCard> createState() => _OptionCardState();
}

class _OptionCardState extends State<_OptionCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? const Color(0xFFEEEFFF)
                : const Color(0xFFF3F3FE),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isSelected ? AppColors.primary : Colors.transparent,
              width: 2,
            ),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Row(
            children: [
              // Icon circle
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: widget.option.iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.option.icon,
                  color: widget.option.iconColor,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),

              // Label + score
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.option.label,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                    Text(
                      '(${widget.option.score} điểm)',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              // Radio icon
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: widget.isSelected
                    ? const Icon(
                        Icons.check_circle_rounded,
                        key: ValueKey('checked'),
                        color: AppColors.primary,
                        size: 26,
                      )
                    : const Icon(
                        Icons.radio_button_unchecked_rounded,
                        key: ValueKey('unchecked'),
                        color: Color(0xFFC3C6D7),
                        size: 26,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom action bar
// ─────────────────────────────────────────────────────────────────────────────

class _BottomActions extends StatelessWidget {
  const _BottomActions({
    required this.isLastQuestion,
    required this.hasAnswer,
    required this.onBack,
    required this.onNext,
  });

  final bool isLastQuestion;
  final bool hasAnswer;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        16 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: Color(0xFFE1E2ED))),
        boxShadow: [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Quay lại
          Expanded(
            child: SizedBox(
              height: 56,
              child: OutlinedButton(
                onPressed: onBack,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.onSurface,
                  side: const BorderSide(color: Color(0xFFC3C6D7), width: 2),
                  shape: const StadiumBorder(),
                  textStyle: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('Quay lại'),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Tiếp tục / Đánh giá
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: hasAnswer ? onNext : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.primary.withValues(
                    alpha: 0.4,
                  ),
                  disabledForegroundColor: Colors.white.withValues(alpha: 0.6),
                  elevation: hasAnswer ? 4 : 0,
                  shape: const StadiumBorder(),
                  textStyle: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: Text(isLastQuestion ? 'Đánh giá' : 'Tiếp tục'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
