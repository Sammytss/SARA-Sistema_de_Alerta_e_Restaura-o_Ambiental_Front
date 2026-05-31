import 'package:flutter/material.dart';

/// Paleta de cores oficial do SARA APP.
/// Inspirada na natureza e restauração ambiental — tons de verde,
/// terra e água com variações para uso em light e dark mode.
class AppColors {
  AppColors._();

  // ── Primary: Verde Floresta ─────────────────────────────────
  static const Color primaryDark = Color(0xFF0D3B1E);
  static const Color primary = Color(0xFF1B6B3A);
  static const Color primaryLight = Color(0xFF2E9B5A);
  static const Color primarySurface = Color(0xFFE8F5EC);
  static const Color primaryOnSurface = Color(0xFF0D3B1E);

  // ── Secondary: Âmbar / Terra ────────────────────────────────
  static const Color secondaryDark = Color(0xFF8B5E00);
  static const Color secondary = Color(0xFFD4920A);
  static const Color secondaryLight = Color(0xFFFFC947);
  static const Color secondarySurface = Color(0xFFFFF8E1);

  // ── Accent: Azul Água ───────────────────────────────────────
  static const Color accentDark = Color(0xFF0A4D68);
  static const Color accent = Color(0xFF0E86A0);
  static const Color accentLight = Color(0xFF4FC3D9);
  static const Color accentSurface = Color(0xFFE0F7FA);

  // ── Status Colors ───────────────────────────────────────────
  static const Color success = Color(0xFF2E7D32);
  static const Color successLight = Color(0xFFE8F5E9);
  static const Color warning = Color(0xFFED6C02);
  static const Color warningLight = Color(0xFFFFF3E0);
  static const Color error = Color(0xFFD32F2F);
  static const Color errorLight = Color(0xFFFFEBEE);
  static const Color info = Color(0xFF0288D1);
  static const Color infoLight = Color(0xFFE1F5FE);

  // ── Neutrals ────────────────────────────────────────────────
  static const Color white = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF5F7F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF0F2F0);
  static const Color border = Color(0xFFDDE2DD);
  static const Color divider = Color(0xFFE8ECE8);
  static const Color textPrimary = Color(0xFF1A2E1A);
  static const Color textSecondary = Color(0xFF5A6B5A);
  static const Color textTertiary = Color(0xFF8A978A);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color disabled = Color(0xFFB0BAB0);

  // ── Dark Mode ───────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF0F1A12);
  static const Color darkSurface = Color(0xFF1A2B1E);
  static const Color darkSurfaceVariant = Color(0xFF243428);
  static const Color darkBorder = Color(0xFF3A4D3E);
  static const Color darkDivider = Color(0xFF2E402E);
  static const Color darkTextPrimary = Color(0xFFE8F0E8);
  static const Color darkTextSecondary = Color(0xFFB0C4B0);
  static const Color darkTextTertiary = Color(0xFF7A907A);

  // ── Gradients ───────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryLight],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primaryDark, Color(0xFF1B6B3A), Color(0xFF2E9B5A)],
  );

  static const LinearGradient darkHeroGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0A2514), Color(0xFF0F3B1E), Color(0xFF1A5532)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, accentLight],
  );

  // ── Role-based Colors ───────────────────────────────────────
  static const Color rolePublic = Color(0xFF78909C);
  static const Color roleGestor = Color(0xFF7B1FA2);
  static const Color roleProdutor = Color(0xFF388E3C);
  static const Color roleAnalista = Color(0xFF1976D2);
  static const Color roleAuditor = Color(0xFF455A64);
  static const Color roleTecnico = Color(0xFFE65100);
  static const Color roleOperario = Color(0xFF6D4C41);

  // ── Area Status Colors ──────────────────────────────────────
  static const Color statusRecuperacao = Color(0xFF2E7D32);
  static const Color statusAtencao = Color(0xFFED6C02);
  static const Color statusCritica = Color(0xFFD32F2F);
  static const Color statusRegular = Color(0xFF0288D1);
}
