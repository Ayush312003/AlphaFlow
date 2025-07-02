import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';

/// Premium Dark Theme for AlphaFlow
/// Implements glassmorphism design with modern typography
class AlphaFlowTheme {
  // Color Palette
  static const Color background = Color(0xFF0B0B0F);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color cardOverlay = Color(0x66000000); // rgba(0,0,0,0.4)
  static const Color highlight = Color(0xFF1E90FF);
  static const Color shadow = Color(0x55000000); // #00000055

  // Guided Mode Specific Colors
  static const Color guidedBackground = Color(0xFF0A0A0A);
  static const Color guidedCardBackground = Color(0x0DFFFFFF); // rgba(255,255,255,0.05)
  static const Color guidedCardBorder = Color(0x14FFFFFF); // rgba(255,255,255,0.08)
  static const Color guidedTextPrimary = Color(0xFFFFFFFF);
  static const Color guidedTextSecondary = Color(0xFFCFCFCF);
  static const Color guidedAccentOrange = Color(0xFFFFA500);
  static const Color guidedProgressBarTrack = Color(0xFF2C2C2C);
  static const Color guidedProgressBarFill = Color(0xFFFFA500);
  static const Color guidedCheckboxFill = Color(0xFFFFA500);
  static const Color guidedCheckboxOutline = Color(0xFF4F4F4F);
  static const Color guidedDividerLine = Color(0xFF1E1E1E);
  static const Color guidedInactiveText = Color(0xFFAAAAAA);

  // Font Sizes
  static const double screenTitleSize = 28.0;
  static const double cardTitleSize = 22.0;
  static const double cardSubtitleSize = 14.0;
  static const double buttonTextSize = 16.0;

  // Spacing
  static const double screenPadding = 16.0;
  static const double betweenCards = 16.0;
  static const double insideCard = 16.0;
  static const double titleToSubtitle = 8.0;

  // Radius
  static const double cardRadius = 20.0;

  // Blur
  static const double cardBlurSigma = 3.0;
  static const double guidedCardBlurSigma = 10.0;

  /// Main dark theme configuration
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      
      // Font configuration
      fontFamily: GoogleFonts.sora().fontFamily,
      splashColor: Colors.white24,
      highlightColor: highlight,
      
      // AppBar theme
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          fontFamily: 'Sora',
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      
      // Card theme
      cardTheme: CardTheme(
        color: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
        ),
      ),
      
      // Text theme
      textTheme: TextTheme(
        headlineMedium: const TextStyle( // Screen title
          fontSize: screenTitleSize,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          fontFamily: 'Sora',
        ),
        titleLarge: const TextStyle( // Card title
          fontSize: cardTitleSize,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          fontFamily: 'Sora',
        ),
        titleMedium: const TextStyle( // Subtitle
          fontSize: cardSubtitleSize,
          fontWeight: FontWeight.w500,
          color: textSecondary,
          fontFamily: 'Sora',
        ),
        bodyMedium: const TextStyle( // Body text
          fontSize: 14,
          color: textSecondary,
          fontFamily: 'Sora',
        ),
        labelLarge: const TextStyle( // Button text
          fontSize: buttonTextSize,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          fontFamily: 'Sora',
        ),
      ),
      
      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: highlight,
          foregroundColor: textPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: const TextStyle(
            fontSize: buttonTextSize,
            fontWeight: FontWeight.bold,
            fontFamily: 'Sora',
          ),
        ),
      ),
      
      // Text button theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: textPrimary,
          textStyle: const TextStyle(
            fontSize: buttonTextSize,
            fontWeight: FontWeight.w600,
            fontFamily: 'Sora',
          ),
        ),
      ),
      
      // Icon theme
      iconTheme: const IconThemeData(
        color: textPrimary,
        size: 24,
      ),
      
      // Visual density
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }

  /// Glassmorphism card decoration
  static BoxDecoration get glassmorphismCardDecoration {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(cardRadius),
      boxShadow: [
        BoxShadow(
          color: shadow,
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  /// Guided Mode Glassmorphism card decoration
  static BoxDecoration get guidedGlassmorphismCardDecoration {
    return BoxDecoration(
      color: guidedCardBackground,
      borderRadius: BorderRadius.circular(cardRadius),
      border: Border.all(color: guidedCardBorder, width: 1),
      boxShadow: [
        BoxShadow(
          color: const Color(0x33000000), // #00000033
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  /// Guided Mode Glassmorphism card with shine effect
  static BoxDecoration get guidedGlassmorphismCardWithShine {
    return BoxDecoration(
      color: guidedCardBackground,
      borderRadius: BorderRadius.circular(cardRadius),
      border: Border.all(color: guidedCardBorder, width: 1),
      boxShadow: [
        BoxShadow(
          color: const Color(0x33000000), // #00000033
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0x1AFFFFFF), // Subtle white shine at top-left
          Color(0x00FFFFFF), // Transparent in middle
          Color(0x0DFFFFFF), // Slight white at bottom-right
        ],
        stops: [0.0, 0.5, 1.0],
      ),
    );
  }

  /// Stronger shine effect specifically for calendar
  static BoxDecoration get calendarStrongShine {
    return BoxDecoration(
      color: guidedCardBackground,
      borderRadius: BorderRadius.circular(cardRadius),
      border: Border.all(color: guidedCardBorder, width: 1),
      boxShadow: [
        BoxShadow(
          color: const Color(0x33000000), // #00000033
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0x80FFFFFF), // Much stronger white shine at top-left (0x80)
          Color(0x40FFFFFF), // Strong white at top-right
          Color(0x00FFFFFF), // Transparent in center
          Color(0x20FFFFFF), // Medium white at bottom-left
          Color(0x60FFFFFF), // Strong white at bottom-right (0x60)
        ],
        stops: [0.0, 0.3, 0.5, 0.7, 1.0],
      ),
    );
  }

  /// Gradient overlay for cards
  static LinearGradient get cardGradient {
    return const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0x1A000000), // rgba(0,0,0,0.1)
        Color(0xB3000000), // rgba(0,0,0,0.7)
      ],
    );
  }

  /// Card blur filter
  static ImageFilter get cardBlurFilter {
    return ImageFilter.blur(
      sigmaX: cardBlurSigma,
      sigmaY: cardBlurSigma,
    );
  }

  /// Guided Mode card blur filter
  static ImageFilter get guidedCardBlurFilter {
    return ImageFilter.blur(
      sigmaX: guidedCardBlurSigma,
      sigmaY: guidedCardBlurSigma,
    );
  }

  /// Guided Mode text style
  static const TextStyle guidedTextStyle = TextStyle(
    fontFamily: 'Sora',
    color: guidedTextPrimary,
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );
} 