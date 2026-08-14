abstract class EngagementRepository {
  Future<void> logEngagement({
    required String caseId,
    bool? viewedGuidance,
    bool? viewedEducation,
  });
}
