import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:poms/features/auth/presentation/providers/auth_provider.dart';
import 'package:poms/features/nurse/data/datasources/analytics_remote_datasource.dart';
import 'package:poms/features/nurse/data/repositories/analytics_repository_impl.dart';
import 'package:poms/features/nurse/domain/models/assessment_matrix.dart';
import 'package:poms/features/nurse/domain/models/compliance_overview.dart';
import 'package:poms/features/nurse/domain/models/patient_compliance.dart';
import 'package:poms/features/nurse/domain/repositories/analytics_repository.dart';

final analyticsRemoteDataSourceProvider = Provider<AnalyticsRemoteDataSource>((
  ref,
) {
  return AnalyticsRemoteDataSource(ref.watch(appDioProvider));
});

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  return AnalyticsRepositoryImpl(ref.watch(analyticsRemoteDataSourceProvider));
});

// ── GET /patients/analytics/overview ─────────────────────────────────────────

final complianceOverviewProvider =
    FutureProvider.autoDispose<ComplianceOverview>((ref) {
      return ref.watch(analyticsRepositoryProvider).getComplianceOverview();
    });

// ── GET /patients/:caseId/compliance ─────────────────────────────────────────

final patientComplianceProvider = FutureProvider.autoDispose
    .family<PatientCompliance, String>((ref, caseId) {
      return ref
          .watch(analyticsRepositoryProvider)
          .getPatientCompliance(caseId);
    });

// ── GET /patients/:caseId/assessment-matrix ──────────────────────────────────

final assessmentMatrixProvider = FutureProvider.autoDispose
    .family<AssessmentMatrix, String>((ref, caseId) {
      return ref.watch(analyticsRepositoryProvider).getAssessmentMatrix(caseId);
    });
