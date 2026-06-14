import 'package:flutter/material.dart';

/// Mongez palette — baby blue (primary) + fresh green (accent).
///
/// The brand reads calm + trustworthy (sky blue) with an active "go" signal
/// (green) for confirmations, completion states, and CTAs. Surfaces are a
/// near-white blue-tinted neutral so the blue primary still pops without
/// fighting the content.
///
/// Legacy gray / blueGray / "primary1" / "softPrimary" aliases are kept so
/// older widgets compile without edits.
class AppColors {
  AppColors._();

  // ── Brand ──────────────────────────────────────────────────────────────
  // Baby blue — primary brand color.
  static const Color primary = Color(0xFF5BB6E8);          // baby blue
  static const Color primarySoft = Color(0xFF9FD5F2);      // pale baby blue
  static const Color primaryDark = Color(0xFF2F88BD);      // deeper sky
  static const Color primaryContainer = Color(0xFFDCEEF8); // wash background
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFF06324B);

  // Fresh green — accent / "go" / verified / completion.
  static const Color accent = Color(0xFF34C759);           // friendly green
  static const Color accentSoft = Color(0xFFB8EFC6);
  static const Color accentDark = Color(0xFF1F8A3F);

  // Sunny yellow for stars, urgency, featured tags.
  static const Color highlight = Color(0xFFFFC857);

  // Brand gradient — blue → green so banners and sticky CTAs feel
  // welcoming + active.
  static const List<Color> brandGradient = [
    Color(0xFF5BB6E8),
    Color(0xFF34C759),
  ];

  // ── Surfaces (cool, blue-tinted whites) ────────────────────────────────
  static const Color background = Color(0xFFF4FAFE);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFE8F3FB);
  static const Color surfaceMuted = Color(0xFFEFF7FC);
  static const Color surfaceTinted = Color(0xFFE2F2EA); // green tint

  static const Color backgroundDark = Color(0xFF0E1A22);
  static const Color surfaceDark = Color(0xFF152634);
  static const Color surfaceVariantDark = Color(0xFF1B3142);

  // ── Text / outline ─────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF0E2738);
  static const Color textSecondary = Color(0xFF3F5C70);
  static const Color textTertiary = Color(0xFF668097);
  static const Color textDisabled = Color(0xFFA6BCCC);
  static const Color outline = Color(0xFFD6E6F1);
  static const Color outlineStrong = Color(0xFFAEC8DA);

  static const Color textPrimaryDark = Color(0xFFEAF4FB);
  static const Color textSecondaryDark = Color(0xFFB9CFE0);
  static const Color textTertiaryDark = Color(0xFF8AA4B8);
  static const Color outlineDark = Color(0xFF24394C);

  // ── Status ─────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF1F8A3F);  // matches accentDark
  static const Color warning = Color(0xFFE9A23B);
  static const Color danger  = Color(0xFFE5484D);
  static const Color info    = Color(0xFF2F88BD);  // matches primaryDark

  // ── Legacy aliases ─────────────────────────────────────────────────────
  // Kept so screens still compile while the rename rolls through the app.
  static const Color white = Color(0xFFFFFFFF);
  static const Color categoryCard = primaryContainer;
  static const Color softPrimary = primarySoft;
  static const Color hardPrimary = primaryDark;
  static const Color primary1 = primary;

  static const Color gray9 = textPrimary;
  static const Color gray8 = Color(0xFF1A3346);
  static const Color gray7 = textSecondary;
  static const Color gray6 = Color(0xFF536F84);
  static const Color gray5 = textTertiary;
  static const Color gray4 = Color(0xFF93ADBE);
  static const Color gray3 = outlineStrong;
  static const Color gray2 = Color(0xFFC8DBE9);
  static const Color gray1 = outline;
  static const Color gray05 = surfaceMuted;

  static const Color blueGray9 = textPrimary;
  static const Color blueGray8 = Color(0xFF1A3346);
  static const Color blueGray7 = textSecondary;
  static const Color blueGray6 = Color(0xFF536F84);
  static const Color blueGray5 = textTertiary;
  static const Color blueGray4 = Color(0xFF93ADBE);
  static const Color blueGray3 = outlineStrong;
  static const Color blueGray2 = Color(0xFFC8DBE9);
  static const Color blueGray1 = surfaceVariant;
  static const Color blueGray05 = surfaceMuted;
}

/// Pre-baked gradients for buttons, banners, cards.
class AppGradients {
  AppGradients._();

  static const LinearGradient brand = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: AppColors.brandGradient,
  );

  static LinearGradient brandSoft = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.primary.withValues(alpha: 0.92),
      AppColors.accent.withValues(alpha: 0.92),
    ],
  );

  static LinearGradient surfaceFade(Color base) => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      base.withValues(alpha: 0.18),
      base.withValues(alpha: 0.04),
    ],
  );

  // Kept name for older widgets — now mapped to the green accent.
  static const LinearGradient mintAccent = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF34C759), Color(0xFF1F8A3F)],
  );

  // Kept name for older widgets — now a blue header (was warm terracotta).
  static const LinearGradient warmHeader = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF5BB6E8), Color(0xFF2F88BD)],
  );
}
