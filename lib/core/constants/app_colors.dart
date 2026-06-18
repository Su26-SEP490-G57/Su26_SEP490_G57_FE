import 'package:flutter/material.dart';

/// Design tokens — shared with POMS web admin (Clinical Precision theme)
abstract final class AppColors {
  // Primary — medical blue
  static const Color primary = Color(0xFF00459A);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFD8E2FF);
  static const Color onPrimaryContainer = Color(0xFF001551);

  // Secondary — teal
  static const Color secondary = Color(0xFF006A61);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFF9EF2E4);
  static const Color onSecondaryContainer = Color(0xFF00201D);

  // Error / Critical
  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF410002);

  // Warning
  static const Color warning = Color(0xFFE65100);
  static const Color warningContainer = Color(0xFFFFE0B2);

  // Surface
  static const Color surface = Color(0xFFFBF8FF);
  static const Color onSurface = Color(0xFF1A1B22);
  static const Color surfaceVariant = Color(0xFFE2E2EC);
  static const Color onSurfaceVariant = Color(0xFF45464F);

  // Outline
  static const Color outline = Color(0xFFC2C6D5);
  static const Color outlineVariant = Color(0xFFC5C6D0);

  // Background
  static const Color background = Color(0xFFFBF8FF);
  static const Color onBackground = Color(0xFF1A1B22);

  // Neutral
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color transparent = Color(0x00000000);

  // Status colors
  static const Color statusNormal = Color(0xFF2E7D32);
  static const Color statusWarning = Color(0xFFF57F17);
  static const Color statusCritical = Color(0xFFBA1A1A);
  static const Color statusUnknown = Color(0xFF757575);
}
