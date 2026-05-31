import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/result.dart';
import '../../mock/mock_alertas.dart';
import '../../models/alerta.dart';

/// Fonte remota de alertas de ameaça.
abstract class AlertsRemoteDatasource {
  /// Retorna alertas desde [since] (null = todos). [areaId] filtra por área.
  Future<Result<List<Alerta>>> getAlertas({
    DateTime? since,
    String? areaId,
  });
}

// ── Mock ─────────────────────────────────────────────────────────

class AlertsRemoteMock implements AlertsRemoteDatasource {
  @override
  Future<Result<List<Alerta>>> getAlertas({
    DateTime? since,
    String? areaId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    var lista = MockAlertas.todos;
    if (areaId != null) {
      lista = lista.where((a) => a.areaId == areaId).toList();
    }
    if (since != null) {
      lista = lista.where((a) => a.detectadoEm.isAfter(since)).toList();
    }
    return Ok(lista);
  }
}

// ── Real ─────────────────────────────────────────────────────────

/// Implementação real — chama `GET /alertas` do backend FastAPI.
/// Ativada quando AppConfig.useMockData == false.
class AlertsRemoteReal implements AlertsRemoteDatasource {
  final ApiClient _client;

  AlertsRemoteReal(this._client);

  @override
  Future<Result<List<Alerta>>> getAlertas({
    DateTime? since,
    String? areaId,
  }) async {
    try {
      final params = <String, dynamic>{};
      if (since != null) params['since'] = since.toIso8601String();
      if (areaId != null) params['areaId'] = areaId;

      final response = await _client.dio.get<List<dynamic>>(
        '/alertas',
        queryParameters: params,
      );
      final alertas = (response.data ?? [])
          .cast<Map<String, dynamic>>()
          .map(Alerta.fromJson)
          .toList();
      return Ok(alertas);
    } on DioException catch (e) {
      return Err(ApiException.fromDioException(e));
    }
  }
}
