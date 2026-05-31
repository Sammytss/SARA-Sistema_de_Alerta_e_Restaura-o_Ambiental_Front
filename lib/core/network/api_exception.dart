import 'package:dio/dio.dart';

enum ApiErrorType { offline, unauthorized, notFound, serverError, timeout, unknown }

/// Exceção tipada para erros de API REST.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final ApiErrorType type;

  const ApiException({
    required this.message,
    this.statusCode,
    this.type = ApiErrorType.unknown,
  });

  factory ApiException.fromDioException(DioException e) {
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.unknown) {
      return const ApiException(
        message: 'Sem conexão. Verifique sua internet.',
        type: ApiErrorType.offline,
      );
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return const ApiException(
        message: 'Servidor demorou muito para responder.',
        type: ApiErrorType.timeout,
      );
    }
    final code = e.response?.statusCode;
    return switch (code) {
      401 => const ApiException(
          message: 'Sessão expirada. Faça login novamente.',
          statusCode: 401,
          type: ApiErrorType.unauthorized,
        ),
      404 => ApiException(
          message: 'Recurso não encontrado.',
          statusCode: 404,
          type: ApiErrorType.notFound,
        ),
      _ => ApiException(
          message: e.response?.data?['detail'] as String? ?? 'Erro no servidor.',
          statusCode: code,
          type: ApiErrorType.serverError,
        ),
    };
  }

  factory ApiException.offline() => const ApiException(
        message: 'Sem conexão. Verifique sua internet.',
        type: ApiErrorType.offline,
      );

  @override
  String toString() => message;
}
