import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/result.dart';
import '../../models/satellite_frame.dart';

abstract class SatelliteRemoteDatasource {
  Future<Result<SatelliteTimeline>> getTimeline({
    required String areaId,
    int anos = 5,
    SatelliteLayer camada = SatelliteLayer.landCover,
  });
}

// ── Mock ─────────────────────────────────────────────────────────────

class SatelliteRemoteMock implements SatelliteRemoteDatasource {
  @override
  Future<Result<SatelliteTimeline>> getTimeline({
    required String areaId,
    int anos = 5,
    SatelliteLayer camada = SatelliteLayer.landCover,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));

    final anoAtual = DateTime.now().year;
    final anos_ = List.generate(anos, (i) => anoAtual - anos + 1 + i);

    // Progressão simulada: pastagem/solo exposto → floresta
    final progressao = [
      (vegetacao: 14.0, pastagem: 72.0, agricultura: 9.0, outros: 5.0),
      (vegetacao: 23.0, pastagem: 60.0, agricultura: 11.0, outros: 6.0),
      (vegetacao: 34.0, pastagem: 51.0, agricultura: 9.0, outros: 6.0),
      (vegetacao: 45.0, pastagem: 41.0, agricultura: 8.0, outros: 6.0),
      (vegetacao: 56.0, pastagem: 32.0, agricultura: 6.0, outros: 6.0),
    ];

    final frames = anos_.asMap().entries.map((e) {
      final idx = e.key.clamp(0, progressao.length - 1);
      final p = progressao[idx];
      return SatelliteFrame(
        id: 'mock-$areaId-${e.value}',
        areaId: areaId,
        ano: e.value,
        camada: camada,
        imagemUrl: '',
        thumbnailUrl: null,
        percentualVegetacao: p.vegetacao,
        classes: {
          'Floresta': p.vegetacao,
          'Pastagem': p.pastagem,
          'Agricultura': p.agricultura,
          'Outros': p.outros,
        },
        fonte: 'MAPBIOMAS',
      );
    }).toList();

    return Ok(SatelliteTimeline(frames: frames, geometria: 'polygon'));
  }
}

// ── Real ─────────────────────────────────────────────────────────────

class SatelliteRemoteReal implements SatelliteRemoteDatasource {
  final ApiClient _client;
  SatelliteRemoteReal(this._client);

  @override
  Future<Result<SatelliteTimeline>> getTimeline({
    required String areaId,
    int anos = 5,
    SatelliteLayer camada = SatelliteLayer.landCover,
  }) async {
    try {
      final resp = await _client.dio.get(
        '/areas/$areaId/satellite-timeline',
        queryParameters: {'anos': anos, 'camada': camada.code},
      );
      final timeline = SatelliteTimeline.fromJson(resp.data as Map<String, dynamic>);
      return Ok(timeline);
    } on DioException catch (e) {
      return Err(ApiException.fromDioException(e));
    } catch (e) {
      return Err(ApiException(message: e.toString()));
    }
  }
}
