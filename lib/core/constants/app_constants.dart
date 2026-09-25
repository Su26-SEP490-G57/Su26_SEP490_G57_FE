/// Misc app-wide constants
abstract final class AppConstants {
  // Storage keys — SharedPreferences
  static const String keyUserRole = 'user_role';
  static const String keyUserId = 'user_id';
  static const String keyRememberMe = 'remember_me';
  static const String keyOnboardingDone = 'onboarding_done';
  static const String keyUserProfile = 'user_profile'; // JSON string

  // Storage keys — FlutterSecureStorage
  static const String keyRefreshToken = 'refresh_token';

  // API endpoints
  static const String endpointLogin = '/auth/login';
  static const String endpointRefresh = '/auth/refresh';
  static const String endpointLogout = '/auth/logout';
  static const endpointPatients = '/patients';
  static const String endpointAnalyticsOverview =
      '/patients/analytics/overview';
  static const String endpointComplianceList =
      '/patients/analytics/compliance-list';
  static String endpointPatientCompliance(String caseId) =>
      '/patients/$caseId/compliance';
  static String endpointAssessmentMatrix(String caseId) =>
      '/patients/$caseId/assessment-matrix';

  // API endpoints — chỉ số sinh tồn
  static const String endpointVitalSigns = '/vital-signs';
  static String endpointVitalSignsByPatient(String caseId) =>
      '/vital-signs/patient/$caseId';

  // API endpoints — chỉ định điều trị
  static const String endpointTreatmentOrders = '/treatment-orders';
  static String endpointTreatmentOrdersByPatient(String caseId) =>
      '/treatment-orders/patient/$caseId';
  static String endpointTreatmentSheetsByPatient(String caseId) =>
      '/treatment-orders/patient/$caseId/sheets';
  static String endpointTreatmentSheetPdf(String caseId, int sheetId) =>
      '/treatment-orders/patient/$caseId/sheets/$sheetId/pdf';
  static String endpointTreatmentSheetPrefill(String caseId) =>
      '/treatment-orders/patient/$caseId/sheet-prefill';

  // API endpoints — danh mục mã bệnh ICD-10 (?search=&limit=)
  static const String endpointDiseases = '/diseases';

  // API endpoints — thông báo hệ thống của bệnh nhân
  static const String endpointMyNotifications = '/notifications/mine';
  static String endpointMarkNotificationRead(int notificationId) =>
      '/notifications/$notificationId/read';

  // API endpoints — phiếu theo dõi chăm sóc
  static const String endpointCareObservationMyTasks =
      '/care-observation/tasks/mine';
  static String endpointCareSheetsByPatient(String caseId) =>
      '/care-observation/patient/$caseId/sheets';
  static String endpointCareSheetPdf(String caseId, int sheetId) =>
      '/care-observation/patient/$caseId/sheets/$sheetId/pdf';
  static String endpointCareSheetPrefill(String caseId) =>
      '/care-observation/patient/$caseId/sheet-prefill';

  // API
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const int maxRetries = 3;

  // Pagination
  static const int defaultPageSize = 20;

  // Animation durations
  static const Duration animFast = Duration(milliseconds: 150);
  static const Duration animNormal = Duration(milliseconds: 300);
  static const Duration animSlow = Duration(milliseconds: 500);

  // Border radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 24.0;

  // Spacing
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;
}
