import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:poms/features/nurse/domain/models/patient_compliance_list_page.dart';
import 'package:poms/features/nurse/presentation/providers/analytics_provider.dart';

/// Bộ lọc trạng thái tuân thủ tổng quát (overallStatus).
enum OverallStatusFilter { all, nonCompliant, compliant }

extension OverallStatusFilterX on OverallStatusFilter {
  String get apiValue => switch (this) {
    OverallStatusFilter.all => 'ALL',
    OverallStatusFilter.nonCompliant => 'NON_COMPLIANT',
    OverallStatusFilter.compliant => 'COMPLIANT',
  };

  String get label => switch (this) {
    OverallStatusFilter.all => 'Tất cả',
    OverallStatusFilter.nonCompliant => 'Không tuân thủ',
    OverallStatusFilter.compliant => 'Tuân thủ',
  };
}

/// Bộ lọc khung giờ đánh giá định kỳ bị bỏ lỡ — single-select.
enum AssessmentSlotFilter { any, missedMorning, missedAfternoon, missedBoth }

extension AssessmentSlotFilterX on AssessmentSlotFilter {
  String get label => switch (this) {
    AssessmentSlotFilter.any => 'Tất cả',
    AssessmentSlotFilter.missedMorning => 'Bỏ lỡ sáng',
    AssessmentSlotFilter.missedAfternoon => 'Bỏ lỡ chiều',
    AssessmentSlotFilter.missedBoth => 'Bỏ lỡ cả hai',
  };
}

/// Toàn bộ trạng thái bộ lọc của màn "Người bệnh không tuân thủ".
class NonCompliantFilters {
  const NonCompliantFilters({
    this.overallStatus = OverallStatusFilter.nonCompliant,
    this.dietaryNotViewed = false,
    this.healthEducationNotViewed = false,
    this.assessmentSlot = AssessmentSlotFilter.any,
  });

  final OverallStatusFilter overallStatus;
  final bool dietaryNotViewed;
  final bool healthEducationNotViewed;
  final AssessmentSlotFilter assessmentSlot;

  bool get isDefault =>
      overallStatus == OverallStatusFilter.nonCompliant &&
      !dietaryNotViewed &&
      !healthEducationNotViewed &&
      assessmentSlot == AssessmentSlotFilter.any;

  NonCompliantFilters copyWith({
    OverallStatusFilter? overallStatus,
    bool? dietaryNotViewed,
    bool? healthEducationNotViewed,
    AssessmentSlotFilter? assessmentSlot,
  }) {
    return NonCompliantFilters(
      overallStatus: overallStatus ?? this.overallStatus,
      dietaryNotViewed: dietaryNotViewed ?? this.dietaryNotViewed,
      healthEducationNotViewed:
          healthEducationNotViewed ?? this.healthEducationNotViewed,
      assessmentSlot: assessmentSlot ?? this.assessmentSlot,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NonCompliantFilters &&
          runtimeType == other.runtimeType &&
          overallStatus == other.overallStatus &&
          dietaryNotViewed == other.dietaryNotViewed &&
          healthEducationNotViewed == other.healthEducationNotViewed &&
          assessmentSlot == other.assessmentSlot;

  @override
  int get hashCode => Object.hash(
    overallStatus,
    dietaryNotViewed,
    healthEducationNotViewed,
    assessmentSlot,
  );
}

/// Ô tìm kiếm.
final nonCompliantSearchQueryProvider = StateProvider.autoDispose<String>(
  (ref) => '',
);

/// Bộ lọc chip.
final nonCompliantFiltersProvider =
    StateProvider.autoDispose<NonCompliantFilters>(
      (ref) => const NonCompliantFilters(),
    );

/// Trang hiện tại (1-based).
final nonCompliantPageProvider = StateProvider.autoDispose<int>((ref) => 1);

/// Kích thước trang.
const int kNonCompliantPageSize = 20;

/// Danh sách người bệnh theo bộ lọc + trang hiện tại.
/// GET /patients/analytics/compliance-list
final complianceListProvider =
    FutureProvider.autoDispose<PatientComplianceListPage>((ref) async {
      final search = ref.watch(nonCompliantSearchQueryProvider);
      final filters = ref.watch(nonCompliantFiltersProvider);
      final page = ref.watch(nonCompliantPageProvider);

      final slot = filters.assessmentSlot;

      return ref
          .watch(analyticsRepositoryProvider)
          .getComplianceList(
            search: search.isEmpty ? null : search,
            overallStatus: filters.overallStatus.apiValue,
            dietaryNotViewed: filters.dietaryNotViewed ? true : null,
            healthEducationNotViewed: filters.healthEducationNotViewed
                ? true
                : null,
            missedMorning: slot == AssessmentSlotFilter.missedMorning
                ? true
                : null,
            missedAfternoon: slot == AssessmentSlotFilter.missedAfternoon
                ? true
                : null,
            missedBoth: slot == AssessmentSlotFilter.missedBoth ? true : null,
            page: page,
            limit: kNonCompliantPageSize,
          );
    });
