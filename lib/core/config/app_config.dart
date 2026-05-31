/// Configuração do app lida de variáveis de compilação (--dart-define).
///
/// Uso em desenvolvimento:
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
///
/// Em produção (CI/CD):
///   flutter build apk --dart-define=API_BASE_URL=https://api.sara.to.gov.br --dart-define=ENV=prod
class AppConfig {
  AppConfig._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  static const String env = String.fromEnvironment(
    'ENV',
    defaultValue: 'dev',
  );

  /// Quando true, repositórios usam dados mockados em vez de chamadas REST.
  /// Padrão true até o backend real estar disponível.
  static const bool useMockData = bool.fromEnvironment(
    'USE_MOCK_DATA',
    defaultValue: true,
  );

  static bool get isDev => env == 'dev';
  static bool get isProd => env == 'prod';
}
