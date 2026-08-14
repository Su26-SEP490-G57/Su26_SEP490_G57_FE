import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:poms/core/constants/app_colors.dart';
import 'package:poms/core/constants/app_routes.dart';
import 'package:poms/features/auth/presentation/providers/auth_provider.dart';
import 'package:poms/features/patient/domain/models/pod_protocol_model.dart';
import 'package:poms/features/patient/presentation/providers/diet_guidance_provider.dart';
import 'package:poms/features/patient/presentation/providers/current_pod_provider.dart';
import 'package:poms/features/patient/presentation/providers/engagement_provider.dart';
import 'package:poms/features/patient/presentation/widgets/locked_pod_banner.dart';

class PatientDietGuidancePage extends ConsumerStatefulWidget {
  const PatientDietGuidancePage({super.key});

  @override
  ConsumerState<PatientDietGuidancePage> createState() =>
      _PatientDietGuidancePageState();
}

class _PatientDietGuidancePageState
    extends ConsumerState<PatientDietGuidancePage> {
  @override
  void initState() {
    super.initState();
    final caseId = ref.read(authNotifierProvider).user?.caseId;
    if (caseId != null) {
      ref
          .read(engagementRepositoryProvider)
          .logEngagement(caseId: caseId, viewedGuidance: true)
          .then(
            (_) => debugPrint('[engagement] viewedGuidance logged for $caseId'),
          )
          .catchError(
            (e) => debugPrint(
              '[engagement] viewedGuidance FAILED for $caseId: $e',
            ),
          );
    } else {
      debugPrint('[engagement] skipped viewedGuidance: caseId is null');
    }
  }

  @override
  Widget build(BuildContext context) {
    final dietGuidanceAsync = ref.watch(currentDietGuidanceProvider);
    final currentPodAsync = ref.watch(currentPodProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: dietGuidanceAsync.when(
              data: (protocol) {
                if (protocol == null) {
                  return _buildEmptyState(context);
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 24),
                      currentPodAsync.when(
                        data: (pod) => pod != null && pod.isLocked
                            ? LockedPodBanner(currentPod: pod)
                            : const SizedBox.shrink(),
                        loading: () => const SizedBox.shrink(),
                        error: (_, _) => const SizedBox.shrink(),
                      ),
                      _DietGuidanceContent(protocol: protocol),
                    ],
                  ),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.only(top: 100.0),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stack) => Padding(
                padding: const EdgeInsets.only(top: 100.0),
                child: Center(
                  child: Text(
                    'Đã xảy ra lỗi:\n$error',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 220.0,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.primary,
      iconTheme: const IconThemeData(color: Colors.white),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(AppRoutes.patientDashboard);
          }
        },
        tooltip: 'Quay lại',
      ),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: const Text(
          'Hướng dẫn chế độ ăn',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontFamily: 'Inter',
            fontSize: 18,
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            // A gradient background
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF006E2F), Color(0xFF00A344)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            // Decorative circles
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ),
            Positioned(
              bottom: -80,
              left: -40,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.15),
                ),
              ),
            ),
            // Center icon
            const Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 20.0),
                child: Icon(
                  Icons.restaurant_rounded,
                  size: 64,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          Icon(
            Icons.info_outline_rounded,
            size: 80,
            color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 24),
          const Text(
            'Chưa có hướng dẫn cho ngày hôm nay',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Hiện tại không có chỉ định chế độ ăn đặc biệt nào cho POD hiện tại của bạn. Vui lòng tham khảo ý kiến điều dưỡng.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.onSurface.withValues(alpha: 0.7),
              height: 1.5,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () => context.pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Quay lại',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _DietGuidanceContent extends StatelessWidget {
  const _DietGuidanceContent({required this.protocol});

  final PodProtocolModel protocol;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStageHeader(),
          const SizedBox(height: 24),
          _buildMealsInfoCard(),
          const SizedBox(height: 24),
          _buildVolumeInfoCard(),
          const SizedBox(height: 24),
          _buildFoodsListCard(
            title: 'Thực phẩm khuyên dùng',
            items: protocol.recommendedFoods,
            icon: Icons.check_circle_rounded,
            iconColor: Colors.green,
          ),
          if (protocol.recommendedFoods.isNotEmpty) const SizedBox(height: 24),
          _buildFoodsListCard(
            title: 'Đồ uống khuyên dùng',
            items: protocol.recommendedDrinks,
            icon: Icons.local_drink_rounded,
            iconColor: Colors.blue,
          ),
          if (protocol.recommendedDrinks.isNotEmpty) const SizedBox(height: 24),
          _buildForbiddenCard(
            title: 'Chưa nên sử dụng / Hạn chế',
            foods: protocol.forbiddenFoods,
            drinks: protocol.forbiddenDrinks,
          ),
          if (protocol.forbiddenFoods.isNotEmpty ||
              protocol.forbiddenDrinks.isNotEmpty)
            const SizedBox(height: 24),
          _buildUpgradeCriteriaCard(
            title: 'Điều kiện xem xét nâng mức ăn',
            criteria: protocol.upgradeCriteria,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () => context.go(AppRoutes.patientDashboard),
              icon: const Icon(Icons.home_rounded),
              label: const Text('Về trang chủ'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildStageHeader() {
    final displayLabel = protocol.label.startsWith('Mức')
        ? protocol.label
        : 'Mức ${protocol.dietLevel} – ${protocol.label}';

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            displayLabel,
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              fontSize: 16,
              fontFamily: 'Inter',
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Chế độ dinh dưỡng hồi phục ERAS',
            style: TextStyle(
              color: AppColors.onSurface.withValues(alpha: 0.6),
              fontSize: 14,
              fontFamily: 'Inter',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMealsInfoCard() {
    final String mealTitle = protocol.dietLevel == 1
        ? 'Khuyến nghị uống'
        : 'Tần suất bữa ăn';
    final String mealText;
    if (protocol.mealsPerDayMin == null && protocol.mealsPerDayMax == null) {
      mealText = 'Uống nhiều lần (theo nhu cầu)';
    } else if (protocol.mealsPerDayMin != null &&
        protocol.mealsPerDayMax != null) {
      mealText = protocol.mealsPerDayMin == protocol.mealsPerDayMax
          ? '${protocol.mealsPerDayMin} bữa/ngày'
          : '${protocol.mealsPerDayMin} – ${protocol.mealsPerDayMax} bữa/ngày';
    } else if (protocol.mealsPerDayMin != null) {
      mealText = 'Từ ${protocol.mealsPerDayMin} bữa/ngày';
    } else {
      mealText = 'Tối đa ${protocol.mealsPerDayMax} bữa/ngày';
    }

    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7E6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.wb_sunny_rounded,
                  color: Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mealTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: AppColors.onSurface,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mealText,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: Color(0xFFF59E0B),
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (protocol.mealInstruction != null &&
              protocol.mealInstruction!.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(color: Color(0xFFEDEDF9)),
            const SizedBox(height: 12),
            Text(
              protocol.mealInstruction!,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.onSurfaceVariant,
                height: 1.4,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVolumeInfoCard() {
    final String volumeText;
    if (protocol.volumePerMealMin == null &&
        protocol.volumePerMealMax == null) {
      volumeText = 'Theo khả năng dung nạp';
    } else if (protocol.volumePerMealMin != null &&
        protocol.volumePerMealMax != null) {
      volumeText = protocol.volumePerMealMin == protocol.volumePerMealMax
          ? '${protocol.volumePerMealMin} ml/lần'
          : '${protocol.volumePerMealMin} – ${protocol.volumePerMealMax} ml/lần';
    } else if (protocol.volumePerMealMin != null) {
      volumeText = 'Từ ${protocol.volumePerMealMin} ml/lần';
    } else {
      volumeText = 'Tối đa ${protocol.volumePerMealMax} ml/lần';
    }

    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F9F1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.soup_kitchen_rounded,
                  color: Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Khối lượng mỗi bữa / lần',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: AppColors.onSurface,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      volumeText,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: Color(0xFF10B981),
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (protocol.volumeInstruction != null &&
              protocol.volumeInstruction!.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(color: Color(0xFFEDEDF9)),
            const SizedBox(height: 12),
            Text(
              protocol.volumeInstruction!,
              style: TextStyle(
                color: AppColors.onSurface.withValues(alpha: 0.85),
                height: 1.6,
                fontSize: 15,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFoodsListCard({
    required String title,
    required List<String> items,
    required IconData icon,
    required Color iconColor,
  }) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }
    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: AppColors.onSurface,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 16),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: iconColor, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.onSurface,
                        height: 1.4,
                        fontFamily: 'Inter',
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

  Widget _buildForbiddenCard({
    required String title,
    required List<String> foods,
    required List<String> drinks,
  }) {
    final allItems = [...foods, ...drinks];
    if (allItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFDC2626),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: Color(0xFFDC2626),
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...allItems.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.remove_circle_outline_rounded,
                    color: Color(0xFFDC2626),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.onSurface,
                        height: 1.4,
                        fontFamily: 'Inter',
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

  Widget _buildUpgradeCriteriaCard({
    required String title,
    required List<String> criteria,
  }) {
    if (criteria.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.trending_up_rounded,
                  color: Color(0xFF0284C7),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: Color(0xFF0284C7),
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...criteria.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.task_alt_rounded,
                    color: Color(0xFF0284C7),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.onSurface,
                        height: 1.4,
                        fontFamily: 'Inter',
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

  Widget _buildGlassCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEDEDF9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(padding: const EdgeInsets.all(24.0), child: child),
        ),
      ),
    );
  }
}
