import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mongez/core/app_colors.dart';

/// Material 3 theme for Mongez.
///
/// Light + dark share the same shape language and align with the web
/// surfaces (landing page + admin dashboard):
///   • Typography : **Inter** (the dashboard's font family,
///                  `font-family: 'Inter', …` in the custom Django admin
///                  theme and the React dashboard).
///   • Radius     : 14 px — slightly softer than the dashboard's 12 px
///                  to suit thumb-sized touch targets, but visibly the
///                  same shape language.
///   • Colors     : pulled from [AppColors], which mirrors
///                  `--mongez-blue / --mongez-accent / --mongez-dark /
///                  --mongez-light / --mongez-danger` in
///                  `front/src/pages/Landing.css`.
class AppThemes {
  AppThemes._();

  // ── Shape / radii ─────────────────────────────────────────────────────
  static const double _r = 14.0;
  static const double _rPill = 999.0;
  static final BorderRadius _radius = BorderRadius.circular(_r);
  static final RoundedRectangleBorder _shape =
      RoundedRectangleBorder(borderRadius: _radius);

  // ── Typography ────────────────────────────────────────────────────────
  static TextTheme _textTheme(Color body, Color title) =>
      GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.inter(
          fontSize: 34, fontWeight: FontWeight.w800, color: title, height: 1.15,
          letterSpacing: -0.5,
        ),
        displayMedium: GoogleFonts.inter(
          fontSize: 28, fontWeight: FontWeight.w800, color: title, height: 1.2,
          letterSpacing: -0.4,
        ),
        displaySmall: GoogleFonts.inter(
          fontSize: 23, fontWeight: FontWeight.w700, color: title, height: 1.25,
          letterSpacing: -0.3,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 20, fontWeight: FontWeight.w700, color: title,
          letterSpacing: -0.2,
        ),
        headlineSmall: GoogleFonts.inter(
          fontSize: 18, fontWeight: FontWeight.w700, color: title,
          letterSpacing: -0.1,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 17, fontWeight: FontWeight.w700, color: title,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 15, fontWeight: FontWeight.w600, color: title,
        ),
        titleSmall: GoogleFonts.inter(
          fontSize: 13, fontWeight: FontWeight.w600, color: title,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 15, fontWeight: FontWeight.w400, color: body, height: 1.5,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.w400, color: body, height: 1.5,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12, fontWeight: FontWeight.w400, color: body,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.w700, color: title,
        ),
      );

  // ── Light ─────────────────────────────────────────────────────────────
  // Baby blue primary, green secondary (success/go signal), pale-blue
  // tertiary for soft chip/banner accents.
  static ThemeData lightTheme = _build(
    brightness: Brightness.light,
    scheme: const ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.onPrimaryContainer,
      secondary: AppColors.accent,
      onSecondary: AppColors.onPrimary,
      secondaryContainer: AppColors.accentSoft,
      onSecondaryContainer: Color(0xFF05381A),
      tertiary: AppColors.primarySoft,
      onTertiary: AppColors.textPrimary,
      error: AppColors.danger,
      onError: AppColors.onPrimary,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      surfaceContainerHighest: AppColors.surfaceVariant,
      outline: AppColors.outline,
      outlineVariant: AppColors.outlineStrong,
    ),
    scaffoldBg: AppColors.background,
    titleColor: AppColors.textPrimary,
    bodyColor: AppColors.textSecondary,
    fieldFill: AppColors.surface,
    fieldBorder: AppColors.outline,
    cardColor: AppColors.surface,
    dividerColor: AppColors.outline,
    iconColor: AppColors.textSecondary,
    statusBarStyle: SystemUiOverlayStyle.dark,
  );

  // ── Dark ──────────────────────────────────────────────────────────────
  static ThemeData darkTheme = _build(
    brightness: Brightness.dark,
    scheme: const ColorScheme.dark(
      primary: AppColors.primarySoft,
      onPrimary: Color(0xFF002033),
      primaryContainer: Color(0xFF134F75),
      onPrimaryContainer: AppColors.primaryContainer,
      secondary: AppColors.accent,
      onSecondary: AppColors.onPrimary,
      secondaryContainer: Color(0xFF14532D),
      onSecondaryContainer: AppColors.accentSoft,
      tertiary: AppColors.accentSoft,
      onTertiary: AppColors.textPrimary,
      error: AppColors.danger,
      onError: AppColors.onPrimary,
      surface: AppColors.surfaceDark,
      onSurface: AppColors.textPrimaryDark,
      surfaceContainerHighest: AppColors.surfaceVariantDark,
      outline: AppColors.outlineDark,
      outlineVariant: AppColors.outlineDark,
    ),
    scaffoldBg: AppColors.backgroundDark,
    titleColor: AppColors.textPrimaryDark,
    bodyColor: AppColors.textSecondaryDark,
    fieldFill: AppColors.surfaceVariantDark,
    fieldBorder: AppColors.outlineDark,
    cardColor: AppColors.surfaceDark,
    dividerColor: AppColors.outlineDark,
    iconColor: AppColors.textSecondaryDark,
    statusBarStyle: SystemUiOverlayStyle.light,
  );

  static ThemeData _build({
    required Brightness brightness,
    required ColorScheme scheme,
    required Color scaffoldBg,
    required Color titleColor,
    required Color bodyColor,
    required Color fieldFill,
    required Color fieldBorder,
    required Color cardColor,
    required Color dividerColor,
    required Color iconColor,
    required SystemUiOverlayStyle statusBarStyle,
  }) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffoldBg,
      primaryColor: scheme.primary,
      canvasColor: scaffoldBg,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      textTheme: _textTheme(bodyColor, titleColor),
      primaryTextTheme: _textTheme(bodyColor, titleColor),
      iconTheme: IconThemeData(color: iconColor, size: 22),
      dividerColor: dividerColor,
      dividerTheme: DividerThemeData(
        color: dividerColor, thickness: 1, space: 24,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBg,
        foregroundColor: titleColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          color: titleColor, fontSize: 18, fontWeight: FontWeight.w600,
        ),
        systemOverlayStyle: statusBarStyle.copyWith(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: brightness == Brightness.light
              ? Brightness.dark : Brightness.light,
        ),
      ),

      cardTheme: CardThemeData(
        color: cardColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: _shape.copyWith(
          side: BorderSide(color: dividerColor, width: 1),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: fieldFill,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: GoogleFonts.inter(
          color: scheme.onSurface.withValues(alpha: 0.45),
          fontWeight: FontWeight.w400,
        ),
        labelStyle: GoogleFonts.inter(
          color: scheme.onSurface.withValues(alpha: 0.7),
          fontWeight: FontWeight.w500,
        ),
        prefixIconColor: iconColor,
        suffixIconColor: iconColor,
        enabledBorder: OutlineInputBorder(
          borderRadius: _radius,
          borderSide: BorderSide(color: fieldBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: _radius,
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: _radius,
          borderSide: BorderSide(color: scheme.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: _radius,
          borderSide: BorderSide(color: scheme.error, width: 1.6),
        ),
        errorStyle: GoogleFonts.inter(
          color: scheme.error, fontSize: 12, fontWeight: FontWeight.w500,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          disabledBackgroundColor: scheme.primary.withValues(alpha: 0.35),
          disabledForegroundColor: scheme.onPrimary.withValues(alpha: 0.7),
          elevation: 0,
          shadowColor: scheme.primary.withValues(alpha: 0.25),
          minimumSize: const Size.fromHeight(52),
          shape: _shape,
          textStyle: GoogleFonts.inter(
            fontSize: 15, fontWeight: FontWeight.w600,
          ),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: _shape,
          textStyle: GoogleFonts.inter(
            fontSize: 15, fontWeight: FontWeight.w600,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.primary, width: 1.4),
          minimumSize: const Size.fromHeight(52),
          shape: _shape,
          textStyle: GoogleFonts.inter(
            fontSize: 15, fontWeight: FontWeight.w600,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: GoogleFonts.inter(
            fontSize: 14, fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_rPill),
          ),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerHighest,
        selectedColor: scheme.primary,
        disabledColor: scheme.surfaceContainerHighest,
        side: BorderSide(color: dividerColor),
        labelStyle: GoogleFonts.inter(
          color: titleColor, fontSize: 12, fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: GoogleFonts.inter(
          color: scheme.onPrimary, fontSize: 12, fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_rPill),
        ),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: cardColor,
        selectedItemColor: scheme.primary,
        unselectedItemColor: iconColor,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 12, fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 12, fontWeight: FontWeight.w500,
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cardColor,
        indicatorColor: scheme.primaryContainer,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 72,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.inter(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? scheme.primary : iconColor,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? scheme.primary : iconColor,
            size: 24,
          );
        }),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? scheme.onPrimary : scheme.outline),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? scheme.primary : scheme.surfaceContainerHighest),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.surface,
        contentTextStyle: GoogleFonts.inter(
          color: titleColor, fontSize: 14, fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: GoogleFonts.inter(
          color: titleColor, fontSize: 18, fontWeight: FontWeight.w600,
        ),
        contentTextStyle: GoogleFonts.inter(
          color: bodyColor, fontSize: 14, fontWeight: FontWeight.w400,
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHighest,
        circularTrackColor: scheme.surfaceContainerHighest,
      ),
    );
  }
}
