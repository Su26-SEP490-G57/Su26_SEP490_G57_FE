/// Route path constants — single source of truth
abstract final class AppRoutes {
  // Auth
  static const String splash = '/';
  static const String login = '/login';

  // Nurse routes
  static const String nurseDashboard = '/nurse/dashboard';
  static const String nursePatients = '/nurse/patients';
  static const String nursePriorityPatients = '/nurse/priority-patients';
  static const String nursePatientDetail = '/nurse/patients/:id';
  static const String nurseAlerts = '/nurse/alerts';
  static const String nurseReports = '/nurse/reports';
  static const String nurseMonitoring = '/nurse/monitoring';
  static const String nurseNotifications = '/nurse/notifications';
  static const String nurseProfile = '/nurse/profile';

  // Doctor routes
  static const String doctorDashboard = '/doctor/dashboard';
  static const String doctorPatients = '/doctor/patients';
  static const String doctorPatientDetail = '/doctor/patients/:id';
  static const String doctorProfile = '/doctor/profile';

  // Patient routes
  static const String patientDashboard = '/patient/dashboard';
  static const String patientNotifications = '/patient/notifications';
  static const String patientProfile = '/patient/profile';
  static const String patientSymptoms = '/patient/symptoms';
  static const String patientEducation = '/patient/education';
  static const String patientRecovery = '/patient/recovery';
  static const String patientAssessment = '/patient/assessment';
  static const String patientAssessmentResult = '/patient/assessment/result';
  static const String patientAssessmentHistory = '/patient/assessment-history';
  static const String patientDietGuidance = '/patient/diet-guidance';

  // Helpers for parameterized routes
  static String nursePatientDetailPath(String id) => '/nurse/patients/$id';
  static String doctorPatientDetailPath(String id) => '/doctor/patients/$id';
}
