import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Modern dark theme configuration for the From Fed to Chain audio app
class AppTheme {
  // Color palette
  static const Color primaryColor = Color(0xFF6366F1); // Indigo
  static const Color primaryVariant = Color(0xFF4F46E5);
  static const Color secondaryColor = Color(0xFF10B981); // Emerald
  static const Color backgroundColor = Color(0xFF0F172A); // Slate 900
  static const Color surfaceColor = Color(0xFF1E293B); // Slate 800
  static const Color cardColor = Color(0xFF334155); // Slate 700
  static const Color onSurfaceColor = Color(0xFFF1F5F9); // Slate 100
  static const Color onPrimaryColor = Colors.white;
  static const Color errorColor = Color(0xFFEF4444); // Red 500
  static const Color warningColor = Color(0xFFF59E0B); // Amber 500
  static const Color successColor = Color(0xFF10B981); // Emerald 500

  // Gradient colors
  static const Gradient primaryGradient = LinearGradient(
    colors: [primaryColor, primaryVariant],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient cardGradient = LinearGradient(
    colors: [surfaceColor, cardColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Typography
  static const String fontFamily = 'Inter';

  static const TextStyle headlineLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: onSurfaceColor,
    letterSpacing: -0.5,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: onSurfaceColor,
    letterSpacing: -0.25,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: onSurfaceColor,
  );

  static const TextStyle titleLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: onSurfaceColor,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: onSurfaceColor,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: onSurfaceColor,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: onSurfaceColor,
  );

  static TextStyle get bodySmall => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: onSurfaceColor.withOpacity(0.7),
      );

  // Spacing
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;

  // Border radius
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 24.0;

  // Elevation
  static const double elevationS = 2.0;
  static const double elevationM = 4.0;
  static const double elevationL = 8.0;
  static const double elevationXL = 16.0;

  // Main theme
  static ThemeData get darkTheme {
    return ThemeData(
      // Core theme
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: fontFamily,

      // Color scheme
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        primaryContainer: primaryVariant,
        secondary: secondaryColor,
        surface: surfaceColor,
        background: backgroundColor,
        onPrimary: onPrimaryColor,
        onSecondary: Colors.white,
        onSurface: onSurfaceColor,
        onBackground: onSurfaceColor,
        error: errorColor,
      ),

      // Scaffold
      scaffoldBackgroundColor: backgroundColor,

      // App bar
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: headlineMedium,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: backgroundColor,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      ),

      // Cards
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: elevationS,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusM),
        ),
      ),

      // Elevated buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: onPrimaryColor,
          elevation: elevationS,
          padding: const EdgeInsets.symmetric(
            horizontal: spacingL,
            vertical: spacingM,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusM),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // Text buttons
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(
            horizontal: spacingM,
            vertical: spacingS,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusS),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // Icon buttons
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: onSurfaceColor,
          backgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusS),
          ),
        ),
      ),

      // Floating action button
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: onPrimaryColor,
        elevation: elevationM,
      ),

      // Bottom navigation bar
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: onSurfaceColor,
        type: BottomNavigationBarType.fixed,
        elevation: elevationM,
      ),

      // Sliders
      sliderTheme: SliderThemeData(
        activeTrackColor: primaryColor,
        inactiveTrackColor: cardColor,
        thumbColor: primaryColor,
        overlayColor: primaryColor.withOpacity(0.2),
        trackHeight: 4.0,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8.0),
      ),

      // Progress indicators
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryColor,
        linearTrackColor: cardColor,
        circularTrackColor: cardColor,
      ),

      // List tiles
      listTileTheme: const ListTileThemeData(
        tileColor: Colors.transparent,
        selectedTileColor: primaryColor,
        textColor: onSurfaceColor,
        iconColor: onSurfaceColor,
        contentPadding: EdgeInsets.symmetric(
          horizontal: spacingM,
          vertical: spacingXS,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(radiusS)),
        ),
      ),

      // Input decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingM,
          vertical: spacingM,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        hintStyle: bodyMedium.copyWith(
          color: onSurfaceColor.withOpacity(0.6),
        ),
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: onSurfaceColor.withOpacity(0.1),
        thickness: 1,
        space: 1,
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: cardColor,
        selectedColor: primaryColor,
        labelStyle: bodySmall,
        padding: const EdgeInsets.symmetric(
          horizontal: spacingS,
          vertical: spacingXS,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusL),
        ),
      ),
    );
  }

  // Custom widgets styles
  static BoxDecoration get glassMorphismDecoration {
    return BoxDecoration(
      color: surfaceColor.withOpacity(0.8),
      borderRadius: BorderRadius.circular(radiusM),
      border: Border.all(
        color: onSurfaceColor.withOpacity(0.1),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  static BoxDecoration get cardDecoration {
    return BoxDecoration(
      color: surfaceColor,
      borderRadius: BorderRadius.circular(radiusM),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  static BoxDecoration get gradientCardDecoration {
    return BoxDecoration(
      gradient: cardGradient,
      borderRadius: BorderRadius.circular(radiusM),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  // Animation durations
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationMedium = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);

  // Custom colors for audio states
  static const Color playingColor = successColor;
  static const Color pausedColor = warningColor;
  static const Color loadingColor = primaryColor;
  static const Color errorStateColor = errorColor;

  // Language/Category colors
  static const Map<String, Color> languageColors = {
    'zh-TW': Color(0xFFEF4444), // Red
    'en-US': Color(0xFF3B82F6), // Blue
    'ja-JP': Color(0xFF10B981), // Emerald
  };

  static const Map<String, Color> categoryColors = {
    'daily-news': Color(0xFFF59E0B), // Amber
    'ethereum': Color(0xFF8B5CF6), // Violet
    'macro': Color(0xFF06B6D4), // Cyan
    'startup': Color(0xFFEC4899), // Pink
    'ai': Color(0xFF10B981), // Emerald
    'defi': Color(0xFFEF4444), // Red
  };

  // Utility methods
  static Color getLanguageColor(String language) {
    return languageColors[language] ?? primaryColor;
  }

  static Color getCategoryColor(String category) {
    return categoryColors[category] ?? secondaryColor;
  }

  static String getCategoryDisplayName(String category) {
    switch (category) {
      case 'daily-news':
        return 'Daily News';
      case 'ethereum':
        return 'Ethereum';
      case 'macro':
        return 'Macro';
      case 'startup':
        return 'Startup';
      case 'ai':
        return 'AI';
      case 'defi':
        return 'DeFi';
      default:
        return category.toUpperCase();
    }
  }

  static String getLanguageDisplayName(String language) {
    switch (language) {
      case 'zh-TW':
        return '繁體中文';
      case 'en-US':
        return 'English';
      case 'ja-JP':
        return '日本語';
      default:
        return language.toUpperCase();
    }
  }

  // Safe area padding
  static EdgeInsets get safePadding {
    return const EdgeInsets.all(spacingM);
  }

  static EdgeInsets get safeHorizontalPadding {
    return const EdgeInsets.symmetric(horizontal: spacingM);
  }

  static EdgeInsets get safeVerticalPadding {
    return const EdgeInsets.symmetric(vertical: spacingM);
  }
}
