import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/result.dart';
import '../../mock/mock_data.dart';

/// DTO de resposta do endpoint de login.
class AuthResponse {
  final String accessToken;
  final String refreshToken;

  /// Mapa raw do usuário — mesmo formato de UsuarioLocal.toMap().
  final Map<String, dynamic> usuario;

  const AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.usuario,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
        usuario: json['usuario'] as Map<String, dynamic>,
      );
}

/// Contrato de datasource de autenticação remota.
abstract class AuthRemoteDatasource {
  Future<Result<AuthResponse>> login(String email, String password);
  Future<Result<String>> refreshAccessToken(String refreshToken);
}

// ── Mock ─────────────────────────────────────────────────────────

/// Datasource mock — usa MockData; sem rede.
class AuthRemoteMock implements AuthRemoteDatasource {
  @override
  Future<Result<AuthResponse>> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 900));

    final user = MockData.usuarios[email.trim().toLowerCase()];

    if (user == null) {
      return Err(const ApiException(
        message: 'E-mail não encontrado. Verifique e tente novamente.',
        statusCode: 404,
        type: ApiErrorType.notFound,
      ));
    }

    if (password != MockData.defaultPassword) {
      return Err(const ApiException(
        message: 'Senha incorreta. Tente novamente.',
        statusCode: 401,
        type: ApiErrorType.unauthorized,
      ));
    }

    if (!user.status.canLogin) {
      return Err(ApiException(
        message:
            'Sua conta está ${user.status.displayName.toLowerCase()}. Entre em contato com o administrador.',
        statusCode: 403,
        type: ApiErrorType.unauthorized,
      ));
    }

    return Ok(AuthResponse(
      accessToken: 'mock_access_${user.perfil.code.toLowerCase()}',
      refreshToken: 'mock_refresh_${user.perfil.code.toLowerCase()}',
      usuario: user.toMap(),
    ));
  }

  @override
  Future<Result<String>> refreshAccessToken(String refreshToken) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return const Ok('mock_access_refreshed');
  }
}

// ── Real ─────────────────────────────────────────────────────────

/// Datasource real — chama o backend REST.
/// Ativado quando AppConfig.useMockData == false.
class AuthRemoteReal implements AuthRemoteDatasource {
  final ApiClient _client;

  AuthRemoteReal(this._client);

  @override
  Future<Result<AuthResponse>> login(String email, String password) async {
    try {
      final response = await _client.dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {'email': email, 'senha': password},
      );
      return Ok(AuthResponse.fromJson(response.data!));
    } on DioException catch (e) {
      return Err(ApiException.fromDioException(e));
    }
  }

  @override
  Future<Result<String>> refreshAccessToken(String refreshToken) async {
    try {
      final response = await _client.dio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      return Ok(response.data!['accessToken'] as String);
    } on DioException catch (e) {
      return Err(ApiException.fromDioException(e));
    }
  }
}
