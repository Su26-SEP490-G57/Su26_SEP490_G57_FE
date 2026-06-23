import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/utils/extensions.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/survey_models.dart';
import '../providers/survey_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────────────────────────────────────

class PatientAssessmentPage extends ConsumerStatefulWidget {
  const PatientAssessmentPage({super.key});

  @override
  ConsumerState<PatientAssessmentPage> createState() =>
      _PatientAssessmentPageState();
}

class _PatientAssessmentPageState extends ConsumerState<PatientAssessmentPage> {
  int _currentIndex = 0;
  // questionId → selectedOptionId
  final Map<int, int> _answers = {};

  @override
  Widget build(BuildContext context) {
    final questionsAsync = ref.watch(surveyQuestionsProvider);
    final assessmentState = ref.watch(assessmentNotifierProvider);

    return questionsAsync.when(
      loading: () => _LoadingScreen(onBack: () => context.pop()),
      error: (e, _) => _ErrorScreen(
        error: e.toString(),
        onBack: () => context.pop(),
        onRetry: () => ref.invalidate(surveyQuestionsProvider),
      ),
      data: (questions) {
        if (questions.isEmpty) {
          return _ErrorScreen(
            error: 'Không có câu hỏi nào.',
            onBack: () => context.pop(),
            onRetry: () => ref.invalidate(surveyQuestionsProvider),
          );
        }

        final current = questions[_currentIndex];
        final isLastQuestion = _currentIndex == questions.length - 1;
        final hasAnswer = _answers.containsKey(current.questionId);
        final progress = (_currentIndex + 1) / questions.length;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Column(
            children: [
              _Header(
                onBack: () {
                  if (_currentIndex == 0) {
                    context.pop();
                  } else {
                    setState(() => _currentIndex--);
                  }
                },
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ProgressBar(
                        progress: progress,
                        current: _currentIndex + 1,
                        total: questions.length,
                      ),
                      const SizedBox(height: 32),
                      _QuestionHeader(question: current),
                      const SizedBox(height: 32),
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
                          options: current.options,
                          selectedOptionId: _answers[current.questionId],
                          onSelect: (optionId) {
                            setState(() {
                              _answers[current.questionId] = optionId;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 32),
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
          bottomNavigationBar: _BottomActions(
            isLastQuestion: isLastQuestion,
            hasAnswer: hasAnswer,
            isSubmitting: assessmentState.isLoading,
            onBack: () {
              if (_currentIndex == 0) {
                context.pop();
              } else {
                setState(() => _currentIndex--);
              }
            },
            onNext: () async {
              if (!hasAnswer) return;
              if (isLastQuestion) {
                await _submit(questions);
              } else {
                setState(() => _currentIndex++);
              }
            },
          ),
        );
      },
    );
  }

  Future<void> _submit(List<SurveyQuestion> questions) async {
    final user = ref.read(authNotifierProvider).user;
    final caseId = user?.caseId;

    if (caseId == null || caseId.isEmpty) {
      context.showTopToast(
        'Không tìm thấy mã bệnh nhân. Vui lòng liên hệ điều dưỡng.',
        isError: true,
      );
      return;
    }

    final answers = questions
        .where((q) => _answers.containsKey(q.questionId))
        .map(
          (q) => SurveyAnswer(
            questionId: q.questionId,
            selectedOptionId: _answers[q.questionId]!,
          ),
        )
        .toList();

    await ref
        .read(assessmentNotifierProvider.notifier)
        .submit(caseId: caseId, answers: answers);

    final state = ref.read(assessmentNotifierProvider);

    if (!mounted) return;

    if (state.status == AssessmentStatus.success && state.result != null) {
      unawaited(
        context.push(AppRoutes.patientAssessmentResult, extra: state.result),
      );
    } else if (state.status == AssessmentStatus.error) {
      context.showTopToast(
        state.errorMessage ?? 'Có lỗi xảy ra. Vui lòng thử lại.',
        isError: true,
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Loading screen
// ─────────────────────────────────────────────────────────────────────────────

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _Header(onBack: onBack),
          const Expanded(
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error screen
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorScreen extends StatelessWidget {
  const _ErrorScreen({
    required this.error,
    required this.onBack,
    required this.onRetry,
  });

  final String error;
  final VoidCallback onBack;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _Header(onBack: onBack),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.wifi_off_rounded,
                      size: 56,
                      color: AppColors.onSurfaceVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      error,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        color: AppColors.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: onRetry,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Thử lại'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
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
                  'Trả lời câu hỏi',
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
                  Container(color: const Color(0xFFE1E2ED)),
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
  final SurveyQuestion question;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question.questionText,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Hãy chọn mức độ cảm nhận của bạn hiện tại.',
          style: TextStyle(
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
    required this.selectedOptionId,
    required this.onSelect,
  });

  final List<SurveyOption> options;
  final int? selectedOptionId;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: options.map((opt) {
        final isSelected = selectedOptionId == opt.optionId;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _OptionCard(
            option: opt,
            isSelected: isSelected,
            onTap: () => onSelect(opt.optionId),
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

  final SurveyOption option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_OptionCard> createState() => _OptionCardState();
}

class _OptionCardState extends State<_OptionCard> {
  bool _pressed = false;

  // Màu icon theo score_value
  Color get _iconBg => switch (widget.option.scoreValue) {
    0 => const Color(0xFF6BFF8F),
    1 => const Color(0xFFFFE083),
    _ => const Color(0xFFFFDAD6),
  };

  Color get _iconColor => switch (widget.option.scoreValue) {
    0 => const Color(0xFF005321),
    1 => const Color(0xFF574500),
    _ => AppColors.error,
  };

  IconData get _icon => switch (widget.option.scoreValue) {
    0 => Icons.sentiment_very_satisfied_rounded,
    1 => Icons.sentiment_neutral_rounded,
    2 => Icons.sentiment_dissatisfied_rounded,
    _ => Icons.sentiment_very_dissatisfied_rounded,
  };

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
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(_icon, color: _iconColor, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.option.optionText,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                    Text(
                      '(${widget.option.scoreValue} điểm)',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
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
    required this.isSubmitting,
    required this.onBack,
    required this.onNext,
  });

  final bool isLastQuestion;
  final bool hasAnswer;
  final bool isSubmitting;
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
          Expanded(
            child: SizedBox(
              height: 56,
              child: OutlinedButton(
                onPressed: isSubmitting ? null : onBack,
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
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: (hasAnswer && !isSubmitting) ? onNext : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.primary.withValues(
                    alpha: 0.4,
                  ),
                  disabledForegroundColor: Colors.white.withValues(alpha: 0.6),
                  elevation: (hasAnswer && !isSubmitting) ? 4 : 0,
                  shape: const StadiumBorder(),
                  textStyle: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(isLastQuestion ? 'Đánh giá' : 'Tiếp tục'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
