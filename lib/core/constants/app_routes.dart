/// Route path constants — single source of truth
abstract final class AppRoutes {
  // Auth
  static const String splash = '/';
  static const String login = '/login';

  // Nurse routes
  static const String nurseDashboard = '/nurse/dashboard';
  static const String nursePatients = '/nurse/patients';
  static const String nursePatientDetail = '/nurse/patients/:id';
  static const String nurseAlerts = '/nurse/alerts';
  static const String nurseReports = '/nurse/reports';
  static const String nurseMonitoring = '/nurse/monitoring';
  static const String nurseNotifications = '/nurse/notifications';
  static const String nurseProfile = '/nurse/profile';

  // Patient routes
  static const String patientDashboard = '/patient/dashboard';
  static const String patientNotifications = '/patient/notifications';
  static const String patientProfile = '/patient/profile';
  static const String patientSymptoms = '/patient/symptoms';
  static const String patientEducation = '/patient/education';
  static const String patientRecovery = '/patient/recovery';
  static const String patientAssessment = '/patient/assessment';
  static const String patientAssessmentResult = '/patient/assessment/result';

  // Helpers for parameterized routes
  static String nursePatientDetailPath(String id) => '/nurse/patients/$id';
}
