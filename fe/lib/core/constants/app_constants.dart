/// Misc app-wide constants
abstract final class AppConstants {
  // Storage keys
  static const String keyUserRole = 'user_role';
  static const String keyUserId = 'user_id';
  static const String keyRememberMe = 'remember_me';
  static const String keyOnboardingDone = 'onboarding_done';

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
