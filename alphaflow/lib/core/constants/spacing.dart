/// Spacing constants for consistent layout throughout the app
/// Based on 8px grid system
class Spacing {
  // Base unit
  static const double xs = 4.0;   // 4px
  static const double sm = 8.0;   // 8px - Base unit
  static const double md = 16.0;  // 16px - Standard padding/margins
  static const double lg = 24.0;  // 24px - Section spacing
  static const double xl = 32.0;  // 32px - Page-level spacing
  static const double xxl = 48.0; // 48px - Major section breaks

  // Component-specific spacing
  static const double cardPadding = md;      // 16px
  static const double cardSpacing = sm;      // 8px
  static const double buttonSpacing = md;    // 16px
  static const double sectionSpacing = lg;   // 24px
  static const double pageSpacing = xl;      // 32px

  // Touch targets
  static const double touchTarget = xxl;     // 48px - Minimum touch target
  static const double iconButtonSize = 40.0; // 40px - Icon button size

  // Border radius
  static const double radiusSm = 4.0;   // 4px
  static const double radiusMd = 8.0;   // 8px
  static const double radiusLg = 12.0;  // 12px
  static const double radiusXl = 16.0;  // 16px
} 