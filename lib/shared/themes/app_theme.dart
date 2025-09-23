import 'package:flutter/material.dart';

/// Application theme configuration following Material Design 3 principles
/// for the Capacity Estimation web application.
class AppTheme {
  // Brand colors for capacity planning
  static const Color _primaryColor = Color(0xFF1976D2); // Blue 700
  static const Color _secondaryColor = Color(0xFF388E3C); // Green 700
  static const Color _surfaceColor = Color(0xFFFAFAFA); // Grey 50
  static const Color _errorColor = Color(0xFFD32F2F); // Red 700

  // Capacity planning specific colors
  static const Color backendColor = Color(0xFF3F51B5); // Indigo
  static const Color frontendColor = Color(0xFF009688); // Teal
  static const Color mobileColor = Color(0xFF9C27B0); // Purple
  static const Color qaColor = Color(0xFFFF9800); // Orange
  static const Color devopsColor = Color(0xFF795548); // Brown
  static const Color designColor = Color(0xFFE91E63); // Pink

  // Allocation state colors
  static const Color availableColor = Color(0xFFE8F5E8); // Light green
  static const Color allocatedColor = Color(0xFF4CAF50); // Green
  static const Color overallocatedColor = Color(0xFFFF5722); // Deep orange
  static const Color conflictColor = Color(0xFFF44336); // Red

  /// Light theme configuration
  static ThemeData get lightTheme {
    const ColorScheme colorScheme = ColorScheme.light(
      primary: _primaryColor,
      secondary: _secondaryColor,
      surface: _surfaceColor,
      error: _errorColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.black87,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      
      // App bar theme for navigation
      appBarTheme: const AppBarTheme(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),

      // Card theme for initiative and team member cards
      cardTheme: CardTheme(
        elevation: 2,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),

      // Button themes for actions
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      // Text field theme for forms
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),

      // Chip theme for role tags
      chipTheme: ChipThemeData(
        backgroundColor: _surfaceColor,
        selectedColor: _primaryColor.withOpacity(0.12),
        labelStyle: const TextStyle(fontSize: 12),
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),

      // Data table theme for timeline
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(_surfaceColor),
        dataRowColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _primaryColor.withOpacity(0.08);
          }
          return null;
        }),
        headingTextStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        dataTextStyle: const TextStyle(
          fontSize: 13,
        ),
      ),

      // Progress indicator theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: _primaryColor,
        linearTrackColor: Colors.grey,
      ),

      // Tooltip theme for help text
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(4),
        ),
        textStyle: const TextStyle(
          color: Colors.white,
          fontSize: 12,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  /// Dark theme configuration (for future use)
  static ThemeData get darkTheme {
    const ColorScheme colorScheme = ColorScheme.dark(
      primary: Color(0xFF90CAF9), // Light blue
      secondary: Color(0xFF81C784), // Light green
      surface: Color(0xFF121212),
      error: Color(0xFFCF6679),
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      onSurface: Colors.white,
      onError: Colors.black,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.dark,
      // Additional dark theme configurations can be added here
    );
  }

  /// Get role-specific color for UI elements
  static Color getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'backend':
        return backendColor;
      case 'frontend':
        return frontendColor;
      case 'mobile':
        return mobileColor;
      case 'qa':
        return qaColor;
      case 'devops':
        return devopsColor;
      case 'design':
        return designColor;
      default:
        return _primaryColor;
    }
  }

  /// Get allocation state color for visual indicators
  static Color getAllocationStateColor(String state) {
    switch (state.toLowerCase()) {
      case 'available':
        return availableColor;
      case 'allocated':
        return allocatedColor;
      case 'overallocated':
        return overallocatedColor;
      case 'conflict':
        return conflictColor;
      default:
        return availableColor;
    }
  }

  /// Text styles for consistent typography
  static const TextStyle headingLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.25,
  );

  static const TextStyle headingSmall = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.15,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
  );

  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
  );
}