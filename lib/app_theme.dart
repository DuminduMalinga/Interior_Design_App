import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Design tokens. Screens never use raw hex values, font sizes or magic
// spacing numbers: they read from this file.
// ---------------------------------------------------------------------------

/// Spacing scale: 4 / 8 / 12 / 16 / 24 / 32 / 48.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double huge = 48;
}

abstract final class AppRadius {
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 28;
  static const double full = 999;

  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlAll = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius fullAll = BorderRadius.all(Radius.circular(full));
}

/// Material elevation values, for widgets that take a `double elevation`.
abstract final class AppElevation {
  static const double card = 4;
  static const double elevated = 8;
  static const double modal = 16;
  static const double floating = 24;
}

/// Soft, wide shadows for custom-decorated surfaces.
abstract final class AppShadows {
  static const List<BoxShadow> soft = [
    BoxShadow(color: Color(0x29000000), blurRadius: 18, offset: Offset(0, 8)),
  ];

  static const List<BoxShadow> medium = [
    BoxShadow(color: Color(0x3D000000), blurRadius: 32, offset: Offset(0, 16)),
  ];

  /// A coloured halo, used under primary actions.
  static List<BoxShadow> glow(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.32),
      blurRadius: 28,
      offset: const Offset(0, 10),
    ),
  ];
}

/// Colour tokens, registered on [ThemeData] as a [ThemeExtension].
/// Read them with `context.colors`.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.background,
    required this.backgroundElevated,
    required this.surface,
    required this.surfaceElevated,
    required this.border,
    required this.primary,
    required this.onPrimary,
    required this.secondary,
    required this.accent,
    required this.success,
    required this.warning,
    required this.error,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.glassFill,
    required this.glassBorder,
    required this.scrim,
    required this.backgroundGradient,
    required this.brandGradient,
  });

  static const AppColors dark = AppColors(
    background: Color(0xFF060A14),
    backgroundElevated: Color(0xFF0B1220),
    surface: Color(0xFF111A2E),
    surfaceElevated: Color(0xFF17233D),
    border: Color(0xFF22304D),
    primary: Color(0xFF4A82F7),
    onPrimary: Color(0xFFFFFFFF),
    secondary: Color(0xFF8B6CFF),
    accent: Color(0xFF4FD1C5),
    success: Color(0xFF3DD68C),
    warning: Color(0xFFF5B95F),
    error: Color(0xFFFF6B7A),
    textPrimary: Color(0xFFF4F7FF),
    textSecondary: Color(0xFFC3CEE8),
    textMuted: Color(0xFF8592B0),
    glassFill: Color(0x14FFFFFF),
    glassBorder: Color(0x1FFFFFFF),
    scrim: Color(0xB8000000),
    backgroundGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF0A1226), Color(0xFF060A14), Color(0xFF0B0F24)],
    ),
    brandGradient: LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [Color(0xFF4A82F7), Color(0xFF8B6CFF)],
    ),
  );

  final Color background;
  final Color backgroundElevated;
  final Color surface;
  final Color surfaceElevated;
  final Color border;
  final Color primary;
  final Color onPrimary;
  final Color secondary;
  final Color accent;
  final Color success;
  final Color warning;
  final Color error;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color glassFill;
  final Color glassBorder;
  final Color scrim;
  final LinearGradient backgroundGradient;
  final LinearGradient brandGradient;

  @override
  AppColors copyWith({
    Color? background,
    Color? backgroundElevated,
    Color? surface,
    Color? surfaceElevated,
    Color? border,
    Color? primary,
    Color? onPrimary,
    Color? secondary,
    Color? accent,
    Color? success,
    Color? warning,
    Color? error,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? glassFill,
    Color? glassBorder,
    Color? scrim,
    LinearGradient? backgroundGradient,
    LinearGradient? brandGradient,
  }) {
    return AppColors(
      background: background ?? this.background,
      backgroundElevated: backgroundElevated ?? this.backgroundElevated,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      border: border ?? this.border,
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      secondary: secondary ?? this.secondary,
      accent: accent ?? this.accent,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      glassFill: glassFill ?? this.glassFill,
      glassBorder: glassBorder ?? this.glassBorder,
      scrim: scrim ?? this.scrim,
      backgroundGradient: backgroundGradient ?? this.backgroundGradient,
      brandGradient: brandGradient ?? this.brandGradient,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      background: mix(background, other.background),
      backgroundElevated: mix(backgroundElevated, other.backgroundElevated),
      surface: mix(surface, other.surface),
      surfaceElevated: mix(surfaceElevated, other.surfaceElevated),
      border: mix(border, other.border),
      primary: mix(primary, other.primary),
      onPrimary: mix(onPrimary, other.onPrimary),
      secondary: mix(secondary, other.secondary),
      accent: mix(accent, other.accent),
      success: mix(success, other.success),
      warning: mix(warning, other.warning),
      error: mix(error, other.error),
      textPrimary: mix(textPrimary, other.textPrimary),
      textSecondary: mix(textSecondary, other.textSecondary),
      textMuted: mix(textMuted, other.textMuted),
      glassFill: mix(glassFill, other.glassFill),
      glassBorder: mix(glassBorder, other.glassBorder),
      scrim: mix(scrim, other.scrim),
      backgroundGradient: LinearGradient.lerp(
        backgroundGradient,
        other.backgroundGradient,
        t,
      )!,
      brandGradient: LinearGradient.lerp(
        brandGradient,
        other.brandGradient,
        t,
      )!,
    );
  }
}

extension AppThemeContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>() ?? AppColors.dark;
  TextTheme get text => Theme.of(this).textTheme;
}

class AppTheme {
  const AppTheme._();

  static ThemeData darkTheme() {
    const c = AppColors.dark;
    final text = _textTheme(c);

    RoundedRectangleBorder shape(BorderRadius r) =>
        RoundedRectangleBorder(borderRadius: r);

    OutlineInputBorder inputBorder(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: c.background,
      dividerColor: c.border,
      colorScheme: ColorScheme.dark(
        primary: c.primary,
        onPrimary: c.onPrimary,
        secondary: c.secondary,
        onSecondary: c.onPrimary,
        tertiary: c.accent,
        error: c.error,
        surface: c.surface,
        onSurface: c.textPrimary,
        outline: c.border,
      ),
      textTheme: text,
      extensions: const [AppColors.dark],
      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        foregroundColor: c.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: text.titleMedium,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: c.backgroundElevated,
        selectedItemColor: c.primary,
        unselectedItemColor: c.textMuted,
        selectedLabelStyle: text.labelSmall,
        unselectedLabelStyle: text.labelSmall,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: c.backgroundElevated,
        indicatorColor: c.primary.withValues(alpha: 0.16),
        selectedIconTheme: IconThemeData(color: c.primary),
        unselectedIconTheme: IconThemeData(color: c.textMuted),
        selectedLabelTextStyle: text.labelLarge?.copyWith(color: c.primary),
        unselectedLabelTextStyle: text.labelLarge?.copyWith(color: c.textMuted),
        minWidth: 80,
        minExtendedWidth: 220,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: c.primary,
        foregroundColor: c.onPrimary,
        elevation: AppElevation.elevated,
        shape: shape(AppRadius.lgAll),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: c.onPrimary,
          minimumSize: const Size(0, 52),
          textStyle: text.labelLarge,
          shape: shape(AppRadius.mdAll),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.textPrimary,
          minimumSize: const Size(0, 52),
          textStyle: text.labelLarge,
          side: BorderSide(color: c.border),
          shape: shape(AppRadius.mdAll),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.primary,
          textStyle: text.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface,
        hintStyle: text.bodyMedium?.copyWith(color: c.textMuted),
        errorStyle: text.bodySmall?.copyWith(color: c.error),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        border: inputBorder(c.border),
        enabledBorder: inputBorder(c.border),
        focusedBorder: inputBorder(c.primary, 1.5),
        errorBorder: inputBorder(c.error),
        focusedErrorBorder: inputBorder(c.error, 1.5),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.surfaceElevated,
        contentTextStyle: text.bodyMedium,
        shape: shape(AppRadius.mdAll),
      ),
    );
  }

  /// display / headline / title / body / label, each in large-medium-small
  /// where the app needs them.
  static TextTheme _textTheme(AppColors c) {
    return const TextTheme(
      displayLarge: TextStyle(
        fontSize: 44,
        height: 1.1,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.4,
      ),
      displayMedium: TextStyle(
        fontSize: 34,
        height: 1.15,
        fontWeight: FontWeight.w800,
        letterSpacing: -1,
      ),
      headlineLarge: TextStyle(
        fontSize: 28,
        height: 1.2,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.7,
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        height: 1.25,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      headlineSmall: TextStyle(
        fontSize: 20,
        height: 1.3,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        height: 1.35,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        height: 1.4,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        height: 1.4,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(fontSize: 16, height: 1.5),
      bodyMedium: TextStyle(fontSize: 14, height: 1.5),
      bodySmall: TextStyle(fontSize: 12, height: 1.45),
      labelLarge: TextStyle(
        fontSize: 14,
        height: 1.3,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.1,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        height: 1.3,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        height: 1.3,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
    ).apply(bodyColor: c.textPrimary, displayColor: c.textPrimary);
  }
}
