// lib/core/theme/app_colors.dart
import 'package:flutter/material.dart';

/// App color palette - Mint/Teal theme
/// Ordered from darkest to lightest
class AppColors {
  // Primary color palette (darkest to lightest)
  static const Color primary = Color(0xFF308B82);           // Verde petróleo (Darkest)
  static const Color primaryMedium = Color(0xFF69BFB6);     // Verde agua medio
  static const Color primaryLight = Color(0xFFE5FFFC);      // Verde menta muy claro
  static const Color primaryLighter = Color(0xFFE7FFFD);    // Verde menta claro
  static const Color primaryLightest = Color(0xFFE9FFFF);   // Verde menta muy pálido (Lightest)
  
  // Background colors
  static const Color background = Color(0xFFF9F9F9);        // Fondo blanco grisáceo
  static const Color cardBackground = Colors.white;
  
  // Gradient combinations
  static LinearGradient get primaryGradient => const LinearGradient(
    colors: [primary, primaryMedium],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static LinearGradient get accentGradient => const LinearGradient(
    colors: [primaryMedium, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static LinearGradient get lightGradient => const LinearGradient(
    colors: [primaryLight, primaryLightest],
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

