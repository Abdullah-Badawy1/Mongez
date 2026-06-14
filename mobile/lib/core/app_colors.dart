import 'package:flutter/material.dart';

/// Mongez brand palette — single source of truth, shared with the web
/// dashboard (`front/src/pages/Landing.css`) and the custom Django
/// admin theme. The shape:
///
///   • Primary    : Mongez blue   #3498db  (trust, calm)
///   • Accent     : Fresh green   #2ecc71  ("go" / completion / verified)
///   • Dark       : Slate         #2c3e50  (titles, primary text)
///   • Light      : Cloud         #ecf0f1  (chip / banner washes)
///   • Danger     : Alizarin      #e74c3c  (errors, cancels)
///
/// Keep these values in lock-step with `--mongez-blue` / `--mongez-accent`
/// / `--mongez-dark` / `--mongez-light` / `--mongez-danger` in
/// `front/src/pages/Landing.css`. The legacy gray / blueGray /
/// "primary1" / "softPrimary" aliases are kept so older widgets compile
/// without edits.
class AppColors {
  AppColors._();

  // ── Brand ──────────────────────────────────────────────────────────────
  // Mongez blue — primary brand color. Matches --mongez-blue on the web.
  static const Color primary = Color(0xFF3498DB);          // Mongez blue
  static const Color primarySoft = Color(0xFF5DADE2);      // tinted blue
  static const Color primaryDark = Color(0xFF2980B9);      // hover / pressed
  static const Color primaryContainer = Color(0xFFECF0F1); // --mongez-light
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFF1B4F72);

  // Fresh green — accent / "go" / verified / completion.
  // Matches --mongez-accent on the web.
  static const Color accent = Color(0xFF2ECC71);
  static const Color accentSoft = Color(0xFFA3E4C2);
  static const Color accentDark = Color(0xFF27AE60);

  // Sunny yellow for stars, urgency, featured tags.
  static const Color highlight = Color(0xFFF39C12);

  // Brand gradient — blue → green so banners and sticky CTAs feel
  // welcoming + active.
  static const List<Color> brandGradient = [
    Color(0xFF3498DB),
    Color(0xFF2ECC71),
  ];

  // ── Surfaces (cool, blue-tinted whites) ────────────────────────────────
  static const Color background = Color(0xFFF5F9FC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFECF0F1); // --mongez-light
  static const Color surfaceMuted = Color(0xFFF1F5F9);
  static const Color surfaceTinted = Color(0xFFE8F8F0); // green tint

  static const Color backgroundDark = Color(0xFF1A2530);
  static const Color surfaceDark = Color(0xFF22303C);
  static const Color surfaceVariantDark = Color(0xFF2C3E50); // --mongez-dark

  // ── Text / outline ─────────────────────────────────────────────────────
  // textPrimary matches --mongez-dark exactly so headlines on mobile
  // read the same as on the landing page.
  static const Color textPrimary = Color(0xFF2C3E50);
  static const Color textSecondary = Color(0xFF566573);
  static const Color textTertiary = Color(0xFF7F8C8D);
  static const Color textDisabled = Color(0xFFBDC3C7);
  static const Color outline = Color(0xFFE2E8F0);
  static const Color outlineStrong = Color(0xFFCBD5E0);

  static const Color textPrimaryDark = Color(0xFFECF0F1);
  static const Color textSecondaryDark = Color(0xFFBDC3C7);
  static const Color textTertiaryDark = Color(0xFF95A5A6);
  static const Color outlineDark = Color(0xFF34495E);

  // ── Status ─────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF27AE60);  // accentDark sibling
  static const Color warning = Color(0xFFF39C12);  // matches highlight
  static const Color danger  = Color(0xFFE74C3C);  // --mongez-danger
  static const Color info    = Color(0xFF2980B9);  // primaryDark sibling

  // ── Legacy aliases still referenced by some widgets ───────────────────
  // Only the names with actual call sites are kept — every removed alias
  // had zero usages.
  static const Color white = Color(0xFFFFFFFF);
  static const Color gray9 = textPrimary;
  static const Color gray3 = outlineStrong;
  static const Color gray2 = Color(0xFFD5DBDB);
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
    colors: [Color(0xFF2ECC71), Color(0xFF27AE60)],
  );

  // Kept name for older widgets — now a blue header (was warm terracotta).
  static const LinearGradient warmHeader = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3498DB), Color(0xFF2980B9)],
  );
}
