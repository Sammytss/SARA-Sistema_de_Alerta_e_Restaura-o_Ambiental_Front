

/// Constantes gerais do SARA APP.
class AppConstants {
  AppConstants._();

  // ── App Info ────────────────────────────────────────────────
  static const String appName = 'SARA';
  static const String appFullName = 'Sistema de Acompanhamento da Restauração Ambiental';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'Monitoramento ambiental inteligente';

  // ── Animation Durations ─────────────────────────────────────
  static const Duration animFast = Duration(milliseconds: 200);
  static const Duration animNormal = Duration(milliseconds: 300);
  static const Duration animSlow = Duration(milliseconds: 500);
  static const Duration animVerySlow = Duration(milliseconds: 800);

  // ── API Base URLs ───────────────────────────────────────────
  static const String apiBaseUrl = 'https://api.sara.gov.br/v1';
  static const String publicApiBaseUrl = 'https://api.sara.gov.br/v1/public';

  // ── Storage Keys ────────────────────────────────────────────
  static const String keyToken = 'sara_auth_token';
  static const String keyUser = 'sara_user_data';
  static const String keyThemeMode = 'sara_theme_mode';
  static const String keyLastSync = 'sara_last_sync';
  static const String keyFirstLaunch = 'sara_first_launch';

  // ── Pagination ──────────────────────────────────────────────
  static const int defaultPageSize = 20;

  // ── Validation ──────────────────────────────────────────────
  static const int minPasswordLength = 6;
  static const int maxNameLength = 100;
  static const int maxObservationLength = 500;
}
