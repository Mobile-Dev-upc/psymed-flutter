// lib/core/theme/app_colors.dart
import 'package:flutter/material.dart';

/// App color palette
/// Ordered from darkest to lightest
class AppColors {
  // Primary color palette (darkest to lightest)
  static const Color primary = Color(0xFF376081);      // Darkest
  static const Color primaryMediumDark = Color(0xFF216B83);
  static const Color primaryMedium = Color(0xFF1F8792);
  static const Color primaryMediumLight = Color(0xFF45B5A9);
  static const Color primaryLight = Color(0xFF8FF7C6); // Lightest
  
  // Background colors
  static const Color background = Color(0xFFF9F9F9);
  static const Color cardBackground = Colors.white;
  
  // Gradient combinations
  static LinearGradient get primaryGradient => const LinearGradient(
    colors: [primary, primaryMedium],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static LinearGradient get accentGradient => const LinearGradient(
    colors: [primaryMedium, primaryMediumLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static LinearGradient get lightGradient => const LinearGradient(
    colors: [primaryMediumLight, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Text colors
  static const Color textPrimary = Color(0xFF2D3748);
  static const Color textSecondary = Color(0xFF718096);
  static const Color textLight = Color(0xFFA0AEC0);
  
  // Status colors
  static const Color success = Color(0xFF48BB78);
  static const Color error = Color(0xFFF56565);
  static const Color warning = Color(0xFFED8936);
  static const Color info = primaryMedium;
  
  // Utility colors
  static Color get shadowColor => primary.withOpacity(0.15);
  static Color get dividerColor => const Color(0xFFE2E8F0);
}

